// ============================================================
// APB Slave
// AMBA3 APB protocol slave wrapping a small addressable
// register file. Zero-wait-state design: PREADY, PSLVERR and
// PRDATA are purely combinational functions of PSEL && PENABLE
// (the ACCESS phase). No internal state machine is needed
// because the APB protocol guarantees PADDR/PWDATA/PWRITE stay
// stable across both the SETUP and ACCESS phases of a transfer.
// ============================================================
module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 8            // valid word addresses: 0 .. NUM_REGS-1
)(
    input  wire                    pclk,
    input  wire                    presetn,

    // APB bus
    input  wire [ADDR_WIDTH-1:0]   paddr,
    input  wire                    psel,
    input  wire                    penable,
    input  wire                    pwrite,
    input  wire [DATA_WIDTH-1:0]   pwdata,
    output wire [DATA_WIDTH-1:0]   prdata,
    output wire                    pready,
    output wire                    pslverr
);

    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    wire [ADDR_WIDTH-1:0] word_addr  = paddr >> 2; // word-aligned access
    wire                  addr_valid = (word_addr < NUM_REGS);
    wire                  access     = psel && penable; // ACCESS phase

    integer i;

    assign pready  = access;                       // no wait states
    assign pslverr = access && !addr_valid;
    assign prdata  = (access && !pwrite && addr_valid) ? regs[word_addr]
                                                          : {DATA_WIDTH{1'b0}};

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (access && pwrite && addr_valid) begin
            regs[word_addr] <= pwdata;
        end
    end

endmodule
