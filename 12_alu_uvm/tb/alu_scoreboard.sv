// ============================================================
// ALU Scoreboard
// Implements an independent golden reference model of the ALU
// in plain SystemVerilog (not by re-instantiating the RTL) and
// compares every monitored transaction against it. This is the
// actual verification: it must be an independently-derived
// model, not a copy of the DUT's logic, or a bug shared by both
// would go undetected.
// ============================================================
class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)

    uvm_analysis_imp #(alu_txn, alu_scoreboard) ap_imp;

    int unsigned match_count = 0;
    int unsigned mismatch_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    // golden reference model
    function void predict(input bit [7:0] a, input bit [7:0] b, input bit [2:0] op,
                           output bit [7:0] exp_result, output bit exp_zero,
                           output bit exp_carry, output bit exp_overflow);
        logic [8:0] wide;
        exp_carry    = 1'b0;
        exp_overflow = 1'b0;
        case (op)
            3'b000: begin // ADD
                wide = a + b;
                exp_result = wide[7:0];
                exp_carry  = wide[8];
                exp_overflow = (a[7]==b[7]) && (exp_result[7]!=a[7]);
            end
            3'b001: begin // SUB
                wide = a - b;
                exp_result = wide[7:0];
                exp_carry  = wide[8];
                exp_overflow = (a[7]!=b[7]) && (exp_result[7]!=a[7]);
            end
            3'b010: exp_result = a & b;
            3'b011: exp_result = a | b;
            3'b100: exp_result = a ^ b;
            3'b101: exp_result = ~a;
            3'b110: begin
                {exp_carry, exp_result} = {1'b0, a} << b[3:0];
            end
            3'b111: begin
                exp_result = a >> b[3:0];
                exp_carry  = a[0];
            end
            default: exp_result = 8'hxx;
        endcase
        exp_zero = (exp_result == 8'h00);
    endfunction

    function void write(alu_txn txn);
        bit [7:0] exp_result;
        bit       exp_zero, exp_carry, exp_overflow;

        predict(txn.a, txn.b, txn.op_sel, exp_result, exp_zero, exp_carry, exp_overflow);

        if (txn.result === exp_result && txn.zero === exp_zero &&
            txn.carry === exp_carry && txn.overflow === exp_overflow) begin
            match_count++;
            `uvm_info("ALU_SB", $sformatf("MATCH  a=%0d b=%0d op=%0b -> result=%0d",
                       txn.a, txn.b, txn.op_sel, txn.result), UVM_HIGH)
        end else begin
            mismatch_count++;
            `uvm_error("ALU_SB", $sformatf(
                "MISMATCH a=%0d b=%0d op=%0b : DUT result=%0d zero=%0b carry=%0b ovf=%0b | EXP result=%0d zero=%0b carry=%0b ovf=%0b",
                txn.a, txn.b, txn.op_sel, txn.result, txn.zero, txn.carry, txn.overflow,
                exp_result, exp_zero, exp_carry, exp_overflow))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("ALU_SB", $sformatf("Scoreboard summary: %0d matched, %0d mismatched",
                   match_count, mismatch_count), UVM_LOW)
        if (mismatch_count == 0)
            `uvm_info("ALU_SB", "*** ALL TRANSACTIONS MATCHED ***", UVM_LOW)
        else
            `uvm_error("ALU_SB", $sformatf("*** %0d MISMATCHES DETECTED ***", mismatch_count))
    endfunction
endclass
