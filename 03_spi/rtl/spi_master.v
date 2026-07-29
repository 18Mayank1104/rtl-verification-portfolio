// ============================================================
// SPI Master
// Mode 0 (CPOL=0, CPHA=0): sample on rising edge, shift on falling
// Full-duplex, 8-bit transfers, single slave select
// ============================================================
module spi_master #(
    parameter CLK_DIV = 4   // sclk = clk / (2*CLK_DIV)
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       start,       // pulse to begin a transfer
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,        // 1-cycle pulse when transfer completes

    // SPI bus
    output reg        sclk,
    output reg        mosi,
    input  wire        miso,
    output reg        ss_n         // active low
);

    localparam IDLE = 2'd0, XFER = 2'd1;

    reg [1:0]  state;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_out;
    reg [7:0]  shift_in;
    reg [$clog2(CLK_DIV*2):0] clk_cnt;
    reg        sclk_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            ss_n     <= 1'b1;
            busy     <= 1'b0;
            done     <= 1'b0;
            bit_cnt  <= 0;
            clk_cnt  <= 0;
            rx_data  <= 8'h00;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    sclk <= 1'b0;
                    if (start) begin
                        shift_out <= tx_data;
                        mosi      <= tx_data[7]; // MSB first, set up before first edge
                        ss_n      <= 1'b0;
                        bit_cnt   <= 0;
                        clk_cnt   <= 0;
                        busy      <= 1'b1;
                        state     <= XFER;
                    end
                end

                XFER: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= 0;
                        sclk    <= ~sclk;

                        if (sclk == 1'b0) begin
                            // rising edge coming: sample MISO
                            shift_in <= {shift_in[6:0], miso};
                        end else begin
                            // falling edge coming: shift out next bit, advance counter
                            if (bit_cnt == 3'd7) begin
                                busy    <= 1'b0;
                                done    <= 1'b1;
                                rx_data <= shift_in; // all 8 bits already sampled on rising edges
                                ss_n    <= 1'b1;
                                state   <= IDLE;
                            end else begin
                                bit_cnt   <= bit_cnt + 1;
                                shift_out <= {shift_out[6:0], 1'b0};
                                mosi      <= shift_out[6];
                            end
                        end
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
