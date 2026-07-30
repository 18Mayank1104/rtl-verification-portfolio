// ============================================================
// ALU Driver
// Pulls transactions from the sequencer and drives them onto
// the DUT's combinational inputs. Since the ALU is purely
// combinational (no clock), the driver just settles the inputs
// and waits a delta cycle before signaling item done — there is
// no clock edge to synchronize to.
// ============================================================
class alu_driver extends uvm_driver #(alu_txn);
    `uvm_component_utils(alu_driver)

    virtual alu_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
            `uvm_fatal("ALU_DRV", "Virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            alu_txn txn;
            seq_item_port.get_next_item(txn);
            vif.a      = txn.a;
            vif.b      = txn.b;
            vif.op_sel = txn.op_sel;
            #1; // allow combinational logic to settle
            seq_item_port.item_done();
        end
    endtask
endclass
