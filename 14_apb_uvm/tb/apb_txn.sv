// ============================================================
// APB Transaction
// One complete APB transfer: an address, a read/write
// direction, and (for writes) data. Address is constrained to
// bias heavily toward the DUT's valid register range while
// still occasionally hitting out-of-range addresses, so the
// PSLVERR path gets exercised by random stimulus too, not just
// a directed sequence.
// ============================================================
class apb_txn extends uvm_sequence_item;
    rand bit [7:0]  addr;
    rand bit        write;
    rand bit [31:0] wdata;

    // captured by the monitor after the transfer completes
    bit [31:0] rdata;
    bit        slverr;

    `uvm_object_utils_begin(apb_txn)
        `uvm_field_int(addr,   UVM_ALL_ON)
        `uvm_field_int(write,  UVM_ALL_ON)
        `uvm_field_int(wdata,  UVM_ALL_ON)
        `uvm_field_int(rdata,  UVM_ALL_ON)
        `uvm_field_int(slverr, UVM_ALL_ON)
    `uvm_object_utils_end

    // NUM_REGS=8 in the DUT -> valid word addresses are 0,4,...,28 (0x00-0x1C)
    constraint c_addr_dist {
        addr dist { [8'h00:8'h1C] :/ 90, [8'h20:8'hFF] :/ 10 };
        addr[1:0] == 2'b00; // word-aligned, matches how a real bus master behaves
    }

    function new(string name = "apb_txn");
        super.new(name);
    endfunction
endclass
