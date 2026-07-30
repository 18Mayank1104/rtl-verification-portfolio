// ============================================================
// FIFO Driver
// Drives wr_en/rd_en/wr_data on the negative edge (settled well
// before the DUT's posedge-triggered logic samples them, the
// same negedge-drive/posedge-sample convention used throughout
// this portfolio's directed testbenches to avoid a driver/DUT
// race on the same clock edge). Gates wr_en against the DUT's
// own full flag and rd_en against empty, mirroring how a
// sensible upstream integration would behave and keeping the
// scoreboard's reference model exact (it only needs to track
// transactions the DUT actually accepted).
// ============================================================
class fifo_driver extends uvm_driver #(fifo_txn);
    `uvm_component_utils(fifo_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("FIFO_DRV", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        vif.wr_en   = 0;
        vif.rd_en   = 0;
        vif.wr_data = 0;
        wait (vif.rst_n === 1'b1);

        forever begin
            fifo_txn txn;
            seq_item_port.get_next_item(txn);

            @(negedge vif.clk);
            vif.wr_en   = txn.wr_en && !vif.full;
            vif.rd_en   = txn.rd_en && !vif.empty;
            vif.wr_data = txn.wr_data;

            @(posedge vif.clk); // DUT samples/updates here

            seq_item_port.item_done();
        end
    endtask
endclass
