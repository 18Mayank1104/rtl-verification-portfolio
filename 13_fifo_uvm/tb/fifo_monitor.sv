// ============================================================
// FIFO Monitor
// Samples every clock edge and publishes what actually happened
// that cycle (the driver's intent gated by full/empty already
// happened at the DUT boundary, so the monitor just reports
// ground truth off the pins).
// ============================================================
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(fifo_txn) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("FIFO_MON", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.rst_n === 1'b1);
        forever begin
            @(posedge vif.clk);
            #1; // let the DUT's registered outputs (full/empty/rd_data) settle;
                // driver hasn't moved past this same edge yet, so wr_en/rd_en
                // still reflect the values that were actually sampled by the DUT
            begin
                fifo_txn txn = fifo_txn::type_id::create("txn");
                txn.wr_en   = vif.wr_en;
                txn.rd_en   = vif.rd_en;
                txn.wr_data = vif.wr_data;
                txn.rd_data = vif.rd_data;
                txn.full    = vif.full;
                txn.empty   = vif.empty;
                ap.write(txn);
            end
        end
    endtask
endclass
