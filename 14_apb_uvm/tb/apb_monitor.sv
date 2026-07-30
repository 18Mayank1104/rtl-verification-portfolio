// ============================================================
// APB Monitor
// Passively watches the bus and publishes one transaction per
// completed transfer, detected at the clock edge where
// PSEL && PENABLE && PREADY are all high (the actual transfer
// completion point per the APB spec) -- independent of however
// the driver happens to be timed, so this monitor would work
// correctly against a different master too.
// ============================================================
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_txn) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_MON", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.presetn === 1'b1);
        forever begin
            @(posedge vif.pclk);
            if (vif.psel && vif.penable && vif.pready) begin
                apb_txn txn = apb_txn::type_id::create("txn");
                txn.addr   = vif.paddr;
                txn.write  = vif.pwrite;
                txn.wdata  = vif.pwdata;
                txn.rdata  = vif.prdata;
                txn.slverr = vif.pslverr;
                ap.write(txn);
            end
        end
    endtask
endclass
