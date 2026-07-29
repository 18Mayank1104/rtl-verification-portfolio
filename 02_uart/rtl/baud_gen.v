// ============================================================
// Baud rate generator
// Produces a single-cycle tick pulse at 16x the baud rate
// (standard oversampling used by the RX for mid-bit sampling)
// ============================================================
module baud_gen #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_16x
);

    localparam integer DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    integer count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 0;
            tick_16x <= 1'b0;
        end else if (count == DIVISOR - 1) begin
            count    <= 0;
            tick_16x <= 1'b1;
        end else begin
            count    <= count + 1;
            tick_16x <= 1'b0;
        end
    end

endmodule
