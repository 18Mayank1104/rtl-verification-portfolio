// ============================================================
// ALU Sequences
// - alu_random_seq: pure constrained-random stimulus, the bulk
//   of coverage.
// - alu_directed_seq: hand-picked edge cases (wraparound, zero
//   flag boundary, max shift amount) that random stimulus can
//   miss or take a long time to hit by chance.
// ============================================================
class alu_random_seq extends uvm_sequence #(alu_txn);
    `uvm_object_utils(alu_random_seq)

    int unsigned num_txns = 200;

    function new(string name = "alu_random_seq");
        super.new(name);
    endfunction

    task body();
        alu_txn txn;
        repeat (num_txns) begin
            txn = alu_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize())
                `uvm_error("ALU_SEQ", "Randomization failed")
            finish_item(txn);
        end
    endtask
endclass

class alu_directed_seq extends uvm_sequence #(alu_txn);
    `uvm_object_utils(alu_directed_seq)

    function new(string name = "alu_directed_seq");
        super.new(name);
    endfunction

    task body();
        send(8'd200, 8'd100, 3'b000); // ADD wraparound (300 mod 256)
        send(8'd0,   8'd0,   3'b000); // ADD zero + zero -> zero flag
        send(8'd5,   8'd10,  3'b001); // SUB borrow (negative result)
        send(8'hFF,  8'hFF,  3'b010); // AND all-ones
        send(8'h00,  8'h00,  3'b011); // OR all-zero -> zero flag
        send(8'h01,  8'd15,  3'b110); // SHL by max nibble value
        send(8'h80,  8'd7,   3'b111); // SHR of MSB-set value
        send(8'h7F,  8'h01,  3'b000); // ADD signed-overflow boundary
    endtask

    task send(bit [7:0] a_val, bit [7:0] b_val, bit [2:0] op);
        alu_txn txn = alu_txn::type_id::create("txn");
        start_item(txn);
        if (!txn.randomize() with { a == a_val; b == b_val; op_sel == op; })
            `uvm_error("ALU_SEQ", "Directed randomize failed")
        finish_item(txn);
    endtask
endclass
