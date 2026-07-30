// ============================================================
// ALU Transaction
// One randomizable stimulus item: the two operands and the
// operation select. Constrained so op_sel only ever lands on
// one of the 8 legal ALU operations (all values are legal here
// since the ALU has exactly 8 ops for a 3-bit select, but the
// constraint documents intent and protects against future
// field-width changes).
// ============================================================
class alu_txn extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit [2:0] op_sel;

    // DUT outputs, captured by the monitor for scoreboard comparison
    bit [7:0] result;
    bit       zero;
    bit       carry;
    bit       overflow;

    `uvm_object_utils_begin(alu_txn)
        `uvm_field_int(a,        UVM_ALL_ON)
        `uvm_field_int(b,        UVM_ALL_ON)
        `uvm_field_int(op_sel,   UVM_ALL_ON)
        `uvm_field_int(result,   UVM_ALL_ON)
        `uvm_field_int(zero,     UVM_ALL_ON)
        `uvm_field_int(carry,    UVM_ALL_ON)
        `uvm_field_int(overflow, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_op_sel_valid { op_sel inside {[3'b000:3'b111]}; }

    function new(string name = "alu_txn");
        super.new(name);
    endfunction
endclass
