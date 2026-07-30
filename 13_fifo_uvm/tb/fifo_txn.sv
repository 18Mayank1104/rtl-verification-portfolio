// ============================================================
// FIFO Transaction
// A single cycle's worth of stimulus: whether to assert
// wr_en and/or rd_en this cycle, and the write data if writing.
// Both can be set simultaneously (simultaneous read+write is a
// legal, common FIFO operation and deliberately part of the
// random stimulus space).
// ============================================================
class fifo_txn extends uvm_sequence_item;
    rand bit       wr_en;
    rand bit       rd_en;
    rand bit [7:0] wr_data;

    // captured by the monitor after the cycle completes
    bit [7:0] rd_data;
    bit       full;
    bit       empty;

    `uvm_object_utils_begin(fifo_txn)
        `uvm_field_int(wr_en,    UVM_ALL_ON)
        `uvm_field_int(rd_en,    UVM_ALL_ON)
        `uvm_field_int(wr_data,  UVM_ALL_ON)
        `uvm_field_int(rd_data,  UVM_ALL_ON)
        `uvm_field_int(full,     UVM_ALL_ON)
        `uvm_field_int(empty,    UVM_ALL_ON)
    `uvm_object_utils_end

    // bias heavily toward writes early / reads later isn't modeled
    // here (that's the sequence's job) - this just weights plain
    // random traffic toward "do something" over "do nothing"
    constraint c_activity { (wr_en + rd_en) dist { 0 := 1, 1 := 6, 2 := 3 }; }

    function new(string name = "fifo_txn");
        super.new(name);
    endfunction
endclass
