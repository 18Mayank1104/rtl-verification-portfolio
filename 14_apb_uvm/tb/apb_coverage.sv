// ============================================================
// APB Coverage Collector
// Covers read vs write crossed with in-range vs out-of-range
// address, so coverage closure demands seeing all four
// combinations -- including a write to an invalid address and
// a read from an invalid address, the two cases most likely to
// be under-tested by chance.
// ============================================================
class apb_coverage extends uvm_subscriber #(apb_txn);
    `uvm_component_utils(apb_coverage)

    apb_txn txn;
    bit     addr_in_range;

    covergroup cg;
        option.per_instance = 1;

        cp_write: coverpoint txn.write;
        cp_range: coverpoint addr_in_range;
        cp_slverr: coverpoint txn.slverr;

        cross_write_range: cross cp_write, cp_range;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(apb_txn t);
        txn = t;
        addr_in_range = ((t.addr >> 2) < 8);
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("APB_COV", $sformatf("Functional coverage: %0.2f%%", cg.get_coverage()), UVM_LOW)
    endfunction
endclass
