// ============================================================
// Synchronous FIFO
// Single clock domain, parameterized data width and depth
// (depth must be a power of 2)
// ============================================================
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16,               // must be power of 2
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire                   full,

    input  wire                   rd_en,
    output reg  [DATA_WIDTH-1:0]  rd_data,
    output wire                   empty,

    output wire [ADDR_WIDTH:0]    fifo_count
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // one extra MSB so wrap-around distinguishes full vs empty
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;

    wire wr_valid = wr_en && !full;
    wire rd_valid = rd_en && !empty;

    // ---------------- write ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_valid) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // ---------------- read ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= 0;
            rd_data <= {DATA_WIDTH{1'b0}};
        end else if (rd_valid) begin
            rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr  <= rd_ptr + 1'b1;
        end
    end

    // ---------------- flags ----------------
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
                   (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);
    assign fifo_count = wr_ptr - rd_ptr;

endmodule
