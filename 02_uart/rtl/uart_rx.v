// ============================================================
// UART Receiver
// 8N1 frame, samples at the middle of each bit using 16x tick
// ============================================================
module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_16x,
    input  wire       rx,          // serial line in
    output reg  [7:0] rx_data,
    output reg        rx_valid,    // 1-cycle pulse when a byte is ready
    output reg        rx_error     // framing error (bad stop bit)
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    // synchronize the async rx line
    reg rx_sync0, rx_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync1 <= rx_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            tick_cnt <= 0;
            bit_idx  <= 0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0; // default, pulses high only on completion

            case (state)
                IDLE: begin
                    if (rx_sync1 == 1'b0) begin // start bit detected
                        state    <= START;
                        tick_cnt <= 0;
                    end
                end

                START: if (tick_16x) begin
                    if (tick_cnt == 4'd7) begin // middle of start bit
                        if (rx_sync1 == 1'b0) begin // confirm still low
                            tick_cnt <= 0;
                            bit_idx  <= 0;
                            state    <= DATA;
                        end else
                            state <= IDLE; // false start (glitch)
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                DATA: if (tick_16x) begin
                    if (tick_cnt == 4'd15) begin
                        tick_cnt <= 0;
                        shift_reg[bit_idx] <= rx_sync1; // sample mid-bit
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                STOP: if (tick_16x) begin
                    if (tick_cnt == 4'd15) begin
                        tick_cnt <= 0;
                        state    <= IDLE;
                        if (rx_sync1 == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1;
                            rx_error <= 1'b0;
                        end else begin
                            rx_error <= 1'b1; // framing error
                        end
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
