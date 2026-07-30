// ============================================================
// ALU Monitor
// Passively samples the interface after every input change and
// publishes a completed transaction (inputs + DUT outputs) to
// the scoreboard via an analysis port. Never drives signals.
// ============================================================
class alu_monitor extends uvm_monitor;
    `uvm_component_utils(alu_monitor)

    virtual alu_if vif;
    uvm_analysis_port #(alu_txn) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
            `uvm_fatal("ALU_MON", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        alu_txn txn;
        forever begin
            @(vif.a or vif.b or vif.op_sel);
            #2; // sample after the driver's settle delay
            txn          = alu_txn::type_id::create("txn");
            txn.a        = vif.a;
            txn.b        = vif.b;
            txn.op_sel   = vif.op_sel;
            txn.result   = vif.result;
            txn.zero     = vif.zero;
            txn.carry    = vif.carry;
            txn.overflow = vif.overflow;
            ap.write(txn);
        end
    endtask
endclass
