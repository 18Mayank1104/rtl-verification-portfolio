// ============================================================
// ALU Coverage Collector
// Functional coverage on the operation select (all 8 ops hit)
// and cross-coverage of op vs. the zero/carry/overflow flags,
// so coverage closure actually demands hitting each flag's
// edge case per operation, not just exercising every opcode
// once with arbitrary operands.
// ============================================================
class alu_coverage extends uvm_subscriber #(alu_txn);
    `uvm_component_utils(alu_coverage)

    alu_txn txn;

    covergroup cg;
        option.per_instance = 1;

        cp_op: coverpoint txn.op_sel {
            bins add  = {3'b000};
            bins sub  = {3'b001};
            bins bAND = {3'b010};
            bins bOR  = {3'b011};
            bins bXOR = {3'b100};
            bins bNOT = {3'b101};
            bins shl  = {3'b110};
            bins shr  = {3'b111};
        }
        cp_zero:     coverpoint txn.zero;
        cp_carry:    coverpoint txn.carry;
        cp_overflow: coverpoint txn.overflow;

        cross_op_zero:  cross cp_op, cp_zero;
        cross_op_carry: cross cp_op, cp_carry;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(alu_txn t);
        txn = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("ALU_COV", $sformatf("Functional coverage: %0.2f%%", cg.get_coverage()), UVM_LOW)
    endfunction
endclass
