// ============================================================
// UART Transmitter
// 8N1 frame: 1 start bit, 8 data bits (LSB first), 1 stop bit
// ============================================================
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_16x,   // 16x baud tick from baud_gen
    input  wire       tx_start,   // pulse to begin transmission
    input  wire [7:0] tx_data,
    output reg        tx,         // serial line (idle = 1)
    output reg        tx_busy
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;   // counts 16x ticks per bit
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            tx       <= 1'b1;
            tx_busy  <= 1'b0;
            tick_cnt <= 0;
            bit_idx  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= START;
                        tick_cnt  <= 0;
                    end
                end

                START: if (tick_16x) begin
                    tx <= 1'b0; // start bit
                    if (tick_cnt == 4'd15) begin
                        tick_cnt <= 0;
                        bit_idx  <= 0;
                        state    <= DATA;
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                DATA: if (tick_16x) begin
                    tx <= shift_reg[bit_idx];
                    if (tick_cnt == 4'd15) begin
                        tick_cnt <= 0;
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                STOP: if (tick_16x) begin
                    tx <= 1'b1; // stop bit
                    if (tick_cnt == 4'd15) begin
                        tick_cnt <= 0;
                        tx_busy  <= 1'b0;
                        state    <= IDLE;
                    end else
                        tick_cnt <= tick_cnt + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
