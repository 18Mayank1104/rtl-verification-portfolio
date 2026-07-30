// ============================================================
// APB Scoreboard
// Maintains an independent associative-array model of the
// register file (not the DUT's own regs[] array) and checks
// every completed transfer: writes update the model and are
// checked for correct SLVERR behavior; reads are checked
// against the model's current value and SLVERR for out-of-range
// addresses.
// ============================================================
class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_txn, apb_scoreboard) ap_imp;

    bit [31:0] ref_regs[bit [7:0]]; // associative array, keyed by word address
    int unsigned num_regs = 8;      // must match DUT's NUM_REGS

    int unsigned matches = 0;
    int unsigned mismatches = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function bit addr_valid(bit [7:0] addr);
        return (addr >> 2) < num_regs;
    endfunction

    function void write(apb_txn txn);
        bit exp_valid = addr_valid(txn.addr);

        if (txn.write) begin
            bit exp_slverr = !exp_valid;
            if (txn.slverr === exp_slverr) begin
                matches++;
                if (exp_valid) ref_regs[txn.addr] = txn.wdata;
            end else begin
                mismatches++;
                `uvm_error("APB_SB", $sformatf(
                    "WRITE SLVERR MISMATCH addr=0x%02h: got %0b, expected %0b",
                    txn.addr, txn.slverr, exp_slverr))
            end
        end else begin
            bit [31:0] exp_rdata = exp_valid ? (ref_regs.exists(txn.addr) ? ref_regs[txn.addr] : 32'h0) : 32'h0;
            bit        exp_slverr = !exp_valid;

            if (txn.rdata === exp_rdata && txn.slverr === exp_slverr) begin
                matches++;
            end else begin
                mismatches++;
                `uvm_error("APB_SB", $sformatf(
                    "READ MISMATCH addr=0x%02h: got rdata=0x%08h slverr=%0b, expected rdata=0x%08h slverr=%0b",
                    txn.addr, txn.rdata, txn.slverr, exp_rdata, exp_slverr))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("APB_SB", $sformatf("Scoreboard summary: %0d matched, %0d mismatched",
                   matches, mismatches), UVM_LOW)
        if (mismatches == 0)
            `uvm_info("APB_SB", "*** ALL TRANSACTIONS MATCHED ***", UVM_LOW)
        else
            `uvm_error("APB_SB", $sformatf("*** %0d MISMATCHES DETECTED ***", mismatches))
    endfunction
endclass
