// ============================================================
// FIFO Scoreboard
// Maintains an independent reference queue (a plain SystemVerilog
// queue, not a re-instantiation of the DUT) mirroring exactly
// what a FIFO should contain, and checks every accepted read
// against it. Also checks full/empty flag consistency against
// the reference queue's size vs. the known DUT depth.
// ============================================================
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_txn, fifo_scoreboard) ap_imp;

    bit [7:0] ref_q[$];
    int unsigned depth = 16; // must match DUT's DEPTH parameter

    int unsigned data_matches   = 0;
    int unsigned data_mismatches = 0;
    int unsigned flag_matches   = 0;
    int unsigned flag_mismatches = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(fifo_txn txn);
        bit exp_empty, exp_full;

        // apply the write first (matches DUT ordering: a simultaneous
        // wr+rd in one cycle reads the OLD front of the queue, then
        // pushes the new value to the back)
        if (txn.wr_en && ref_q.size() < depth)
            ref_q.push_back(txn.wr_data);

        if (txn.rd_en && ref_q.size() > 0) begin
            bit [7:0] exp_data = ref_q.pop_front();
            if (exp_data === txn.rd_data) begin
                data_matches++;
            end else begin
                data_mismatches++;
                `uvm_error("FIFO_SB", $sformatf(
                    "DATA MISMATCH: DUT rd_data=0x%0h, expected 0x%0h", txn.rd_data, exp_data))
            end
        end

        exp_empty = (ref_q.size() == 0);
        exp_full  = (ref_q.size() == depth);

        if (txn.empty === exp_empty && txn.full === exp_full) begin
            flag_matches++;
        end else begin
            flag_mismatches++;
            `uvm_error("FIFO_SB", $sformatf(
                "FLAG MISMATCH: DUT empty=%0b full=%0b, expected empty=%0b full=%0b (ref queue size=%0d)",
                txn.empty, txn.full, exp_empty, exp_full, ref_q.size()))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("FIFO_SB", $sformatf(
            "Scoreboard summary: data %0d matched / %0d mismatched, flags %0d matched / %0d mismatched",
            data_matches, data_mismatches, flag_matches, flag_mismatches), UVM_LOW)
        if (data_mismatches == 0 && flag_mismatches == 0)
            `uvm_info("FIFO_SB", "*** ALL CHECKS PASSED ***", UVM_LOW)
        else
            `uvm_error("FIFO_SB", "*** MISMATCHES DETECTED ***")
    endfunction
endclass
