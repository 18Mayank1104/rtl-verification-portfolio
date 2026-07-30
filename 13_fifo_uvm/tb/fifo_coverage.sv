// ============================================================
// FIFO Coverage Collector
// Covers full/empty boundary conditions and simultaneous
// read+write, since those corner cases are exactly where FIFO
// pointer-wrap bugs hide and plain random traffic can under-hit
// them without a targeted directed sequence (fifo_fill_seq /
// fifo_drain_seq are what actually drives these bins closed).
// ============================================================
class fifo_coverage extends uvm_subscriber #(fifo_txn);
    `uvm_component_utils(fifo_coverage)

    fifo_txn txn;

    covergroup cg;
        option.per_instance = 1;

        cp_wr_en: coverpoint txn.wr_en;
        cp_rd_en: coverpoint txn.rd_en;
        cp_full:  coverpoint txn.full;
        cp_empty: coverpoint txn.empty;

        cross_wr_full:  cross cp_wr_en, cp_full;   // write while full (should be blocked)
        cross_rd_empty: cross cp_rd_en, cp_empty;  // read while empty (should be blocked)
        simultaneous_rw: coverpoint (txn.wr_en && txn.rd_en) {
            bins simultaneous = {1};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(fifo_txn t);
        txn = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("FIFO_COV", $sformatf("Functional coverage: %0.2f%%", cg.get_coverage()), UVM_LOW)
    endfunction
endclass
