// ============================================================
// APB Sequences
// - apb_directed_seq: write-then-read-back every valid register,
//   plus explicit in-range and out-of-range checks.
// - apb_random_seq: constrained-random reads/writes across the
//   full address space (biased toward valid addresses).
// ============================================================
class apb_directed_seq extends uvm_sequence #(apb_txn);
    `uvm_object_utils(apb_directed_seq)

    function new(string name = "apb_directed_seq");
        super.new(name);
    endfunction

    task body();
        for (int i = 0; i < 8; i++) begin
            write(i * 4, 32'hCAFE_0000 + i);
            read(i * 4);
        end
        write(4 * 4, 32'hDEAD_BEEF); // overwrite
        read(4 * 4);
        read(8 * 4);                 // one past the last valid register -> SLVERR
        write(8 * 4, 32'hBAD0_BAD0); // out-of-range write -> SLVERR, no corruption
        read(0);                     // reg[0] should be untouched
    endtask

    task write(bit [7:0] a, bit [31:0] d);
        apb_txn txn = apb_txn::type_id::create("txn");
        start_item(txn);
        if (!txn.randomize() with { addr == a; write == 1; wdata == d; })
            `uvm_error("APB_SEQ", "Randomize failed")
        finish_item(txn);
    endtask

    task read(bit [7:0] a);
        apb_txn txn = apb_txn::type_id::create("txn");
        start_item(txn);
        if (!txn.randomize() with { addr == a; write == 0; })
            `uvm_error("APB_SEQ", "Randomize failed")
        finish_item(txn);
    endtask
endclass

class apb_random_seq extends uvm_sequence #(apb_txn);
    `uvm_object_utils(apb_random_seq)
    int unsigned num_txns = 150;

    function new(string name = "apb_random_seq");
        super.new(name);
    endfunction

    task body();
        apb_txn txn;
        repeat (num_txns) begin
            txn = apb_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize())
                `uvm_error("APB_SEQ", "Randomize failed")
            finish_item(txn);
        end
    endtask
endclass
