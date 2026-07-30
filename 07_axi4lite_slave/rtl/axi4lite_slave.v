// ============================================================
// AXI4-Lite Slave
// Word-addressable register file behind a standard AXI4-Lite
// interface. Write and read paths are fully independent, each
// with their own valid/ready handshake per the AXI4-Lite spec:
//   Write: AW (address) + W (data) -> B (response)
//   Read:  AR (address) -> R (data + response)
// AWREADY/WREADY only assert once per transaction (gated by
// aw_en) so a new address isn't accepted mid-transaction.
// ============================================================
module axi4lite_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 8              // valid word addresses: 0 .. NUM_REGS-1
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // ---- Write address channel ----
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    // ---- Write data channel ----
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    // ---- Write response channel ----
    output reg  [1:0]                s_axi_bresp,   // 00=OKAY, 10=SLVERR
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    // ---- Read address channel ----
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    // ---- Read data channel ----
    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    localparam OKAY   = 2'b00;
    localparam SLVERR = 2'b10;

    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];
    integer i;

    // latched write address, and a gate so AW/W are only accepted
    // once per transaction (standard AXI4-Lite slave pattern)
    reg [ADDR_WIDTH-1:0] axi_awaddr;
    reg                  aw_en;

    wire [ADDR_WIDTH-1:0] wr_word_addr = axi_awaddr >> 2;
    wire [ADDR_WIDTH-1:0] rd_word_addr = s_axi_araddr >> 2;
    wire wr_addr_valid = (wr_word_addr < NUM_REGS);
    wire rd_addr_valid = (rd_word_addr < NUM_REGS);

    // ================= Write address channel =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            axi_awaddr    <= {ADDR_WIDTH{1'b0}};
            aw_en         <= 1'b1;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                axi_awaddr    <= s_axi_awaddr;
                aw_en         <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en         <= 1'b1;      // ready to accept a new address
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // ================= Write data channel =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (!s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en)
                s_axi_wready <= 1'b1;
            else
                s_axi_wready <= 1'b0;
        end
    end

    // ================= Register write =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && wr_addr_valid) begin
            if (s_axi_wstrb[0]) regs[wr_word_addr][7:0]   <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) regs[wr_word_addr][15:8]  <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) regs[wr_word_addr][23:16] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) regs[wr_word_addr][31:24] <= s_axi_wdata[31:24];
        end
    end

    // ================= Write response channel =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= OKAY;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= wr_addr_valid ? OKAY : SLVERR;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ================= Read address channel =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid)
                s_axi_arready <= 1'b1;
            else
                s_axi_arready <= 1'b0;
        end
    end

    // ================= Read data channel =================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= OKAY;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= rd_addr_valid ? OKAY : SLVERR;
                s_axi_rdata  <= rd_addr_valid ? regs[rd_word_addr] : {DATA_WIDTH{1'b0}};
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
