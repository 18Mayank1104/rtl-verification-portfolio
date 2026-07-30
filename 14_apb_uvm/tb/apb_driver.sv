// ============================================================
// APB Driver
// Drives a proper 2-phase APB transfer (SETUP then ACCESS),
// with all stimulus changes on the negative clock edge -- the
// same convention adopted portfolio-wide after the race
// condition found in project 06's original directed testbench
// (see that project's README "Debug note" for the story).
// ============================================================
class apb_driver extends uvm_driver #(apb_txn);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_DRV", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        vif.psel = 0; vif.penable = 0; vif.pwrite = 0;
        vif.paddr = 0; vif.pwdata = 0;
        wait (vif.presetn === 1'b1);

        forever begin
            apb_txn txn;
            seq_item_port.get_next_item(txn);

            // ---- SETUP phase ----
            @(negedge vif.pclk);
            vif.paddr   = txn.addr;
            vif.pwrite  = txn.write;
            vif.pwdata  = txn.wdata;
            vif.psel    = 1'b1;
            vif.penable = 1'b0;

            // ---- ACCESS phase ----
            @(negedge vif.pclk);
            vif.penable = 1'b1;

            @(negedge vif.pclk); // one full cycle with penable=1 for pready to be seen

            txn.rdata  = vif.prdata;
            txn.slverr = vif.pslverr;

            vif.psel    = 1'b0;
            vif.penable = 1'b0;

            seq_item_port.item_done();
        end
    endtask
endclass
