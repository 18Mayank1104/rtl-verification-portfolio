// ============================================================
// Asynchronous FIFO
// Dual clock domain (independent write/read clocks).
// Uses Gray-coded pointers with 2-flop synchronizers to safely
// cross the write pointer into the read clock domain and vice
// versa (the standard Clifford Cummings CDC-safe FIFO design).
// Depth must be a power of 2.
// ============================================================
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16,                // must be power of 2
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    // write domain
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // read domain
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // binary pointers (one extra MSB for full/empty wrap detection)
    reg [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    // gray-coded pointers, actually transferred across clock domains
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;

    // synchronized versions of the *other* domain's gray pointer
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync0, rd_ptr_gray_sync1; // into wr_clk domain
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync0, wr_ptr_gray_sync1; // into rd_clk domain

    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // ---------------- write domain ----------------
    wire wr_valid = wr_en && !full;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_valid) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end

    // synchronize read pointer (gray) into write clock domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync0 <= 0;
            rd_ptr_gray_sync1 <= 0;
        end else begin
            rd_ptr_gray_sync0 <= rd_ptr_gray;
            rd_ptr_gray_sync1 <= rd_ptr_gray_sync0;
        end
    end

    // full when next write pointer (gray) equals read pointer with
    // the top two MSBs inverted (the standard gray-code full check)
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync1[ADDR_WIDTH:ADDR_WIDTH-1],
                                     rd_ptr_gray_sync1[ADDR_WIDTH-2:0]});

    // ---------------- read domain ----------------
    wire rd_valid = rd_en && !empty;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= {DATA_WIDTH{1'b0}};
        end else if (rd_valid) begin
            rd_data     <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end

    // synchronize write pointer (gray) into read clock domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync0 <= 0;
            wr_ptr_gray_sync1 <= 0;
        end else begin
            wr_ptr_gray_sync0 <= wr_ptr_gray;
            wr_ptr_gray_sync1 <= wr_ptr_gray_sync0;
        end
    end

    // empty when read pointer (gray) equals synchronized write pointer
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync1);

endmodule
