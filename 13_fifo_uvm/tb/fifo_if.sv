// ============================================================
// Sync FIFO Interface
// ============================================================
interface fifo_if #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 4) (input logic clk);
    logic                  rst_n;
    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  full;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  empty;
    logic [ADDR_WIDTH:0]   fifo_count;
endinterface
