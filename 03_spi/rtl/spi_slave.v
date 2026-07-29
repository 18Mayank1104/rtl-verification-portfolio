// ============================================================
// SPI Slave
// Mode 0 (CPOL=0, CPHA=0): samples MOSI on sclk rising edge,
// shifts MISO out on sclk falling edge
// ============================================================
module spi_slave (
    input  wire       clk,       // system clock, oversamples sclk
    input  wire       rst_n,

    input  wire [7:0] tx_data,   // data to send to master on next transfer
    output reg  [7:0] rx_data,
    output reg        rx_valid,  // 1-cycle pulse when a full byte received

    // SPI bus
    input  wire        sclk,
    input  wire        mosi,
    output reg          miso,
    input  wire        ss_n
);

    reg [2:0] sclk_sync;
    reg [2:0] ss_sync;
    wire sclk_rise = (sclk_sync[2:1] == 2'b01);
    wire sclk_fall = (sclk_sync[2:1] == 2'b10);
    wire ss_active = ~ss_sync[1];

    reg [2:0] bit_cnt;
    reg [7:0] shift_in;
    reg [7:0] shift_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            ss_sync   <= 3'b111;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            ss_sync   <= {ss_sync[1:0], ss_n};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid  <= 1'b0;
            bit_cnt   <= 0;
            miso      <= 1'b0;
            rx_data   <= 8'h00;
        end else begin
            rx_valid <= 1'b0;

            if (!ss_active) begin
                bit_cnt   <= 0;
                shift_out <= tx_data;
                miso      <= tx_data[7];
            end else begin
                if (sclk_rise) begin
                    shift_in <= {shift_in[6:0], mosi};
                    if (bit_cnt == 3'd7) begin
                        rx_data  <= {shift_in[6:0], mosi};
                        rx_valid <= 1'b1;
                    end
                end
                if (sclk_fall) begin
                    if (bit_cnt == 3'd7) begin
                        bit_cnt   <= 0;
                        shift_out <= tx_data; // preload next byte
                        miso      <= tx_data[7];
                    end else begin
                        bit_cnt   <= bit_cnt + 1;
                        shift_out <= {shift_out[6:0], 1'b0};
                        miso      <= shift_out[6];
                    end
                end
            end
        end
    end

endmodule
