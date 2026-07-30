// ============================================================
// FIFO Sequences
// - fifo_fill_seq: writes until full, verifying the DUT's full
//   flag is respected (driver drops wr_en once full is seen).
// - fifo_drain_seq: reads until empty.
// - fifo_random_seq: mixed read/write/simultaneous traffic,
//   the main coverage-driving sequence.
// ============================================================
class fifo_fill_seq extends uvm_sequence #(fifo_txn);
    `uvm_object_utils(fifo_fill_seq)
    int unsigned max_writes = 20; // > FIFO depth, to also test full holdoff

    function new(string name = "fifo_fill_seq");
        super.new(name);
    endfunction

    task body();
        fifo_txn txn;
        repeat (max_writes) begin
            txn = fifo_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize() with { wr_en == 1; rd_en == 0; })
                `uvm_error("FIFO_SEQ", "Randomize failed")
            finish_item(txn);
        end
    endtask
endclass

class fifo_drain_seq extends uvm_sequence #(fifo_txn);
    `uvm_object_utils(fifo_drain_seq)
    int unsigned max_reads = 20;

    function new(string name = "fifo_drain_seq");
        super.new(name);
    endfunction

    task body();
        fifo_txn txn;
        repeat (max_reads) begin
            txn = fifo_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize() with { wr_en == 0; rd_en == 1; })
                `uvm_error("FIFO_SEQ", "Randomize failed")
            finish_item(txn);
        end
    endtask
endclass

class fifo_random_seq extends uvm_sequence #(fifo_txn);
    `uvm_object_utils(fifo_random_seq)
    int unsigned num_txns = 300;

    function new(string name = "fifo_random_seq");
        super.new(name);
    endfunction

    task body();
        fifo_txn txn;
        repeat (num_txns) begin
            txn = fifo_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize())
                `uvm_error("FIFO_SEQ", "Randomize failed")
            finish_item(txn);
        end
    endtask
endclass
