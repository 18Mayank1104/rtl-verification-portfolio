// ============================================================
// Self-checking testbench for RISC-V RV32I Register File
// ============================================================
`timescale 1ns/1ps

module tb_riscv_regfile;

    localparam DATA_WIDTH = 32;

    reg         clk = 0;
    reg         rst_n;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [DATA_WIDTH-1:0] rd_data;
    reg         reg_write;
    wire [DATA_WIDTH-1:0] rs1_data, rs2_data;

    integer errors = 0;
    integer tests  = 0;

    always #5 clk = ~clk;

    riscv_regfile #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .rs1_addr(rs1_addr), .rs1_data(rs1_data),
        .rs2_addr(rs2_addr), .rs2_data(rs2_data),
        .rd_addr(rd_addr), .rd_data(rd_data), .reg_write(reg_write)
    );

    task write_reg(input [4:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            rd_addr   = addr;
            rd_data   = data;
            reg_write = 1'b1;
            @(negedge clk);
            reg_write = 1'b0;
        end
    endtask

    task check_read(input [4:0] addr1, input [4:0] addr2, input [DATA_WIDTH-1:0] exp1, input [DATA_WIDTH-1:0] exp2, input [127:0] name);
        begin
            tests = tests + 1;
            rs1_addr = addr1;
            rs2_addr = addr2;
            #1;
            if (rs1_data === exp1 && rs2_data === exp2) begin
                $display("PASS [%0s] x%0d=0x%08h x%0d=0x%08h", name, addr1, rs1_data, addr2, rs2_data);
            end else begin
                $display("FAIL [%0s] x%0d=0x%08h(exp 0x%08h) x%0d=0x%08h(exp 0x%08h)",
                          name, addr1, rs1_data, exp1, addr2, rs2_data, exp2);
                errors = errors + 1;
            end
        end
    endtask

    integer i;
    initial begin
        rst_n = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0; reg_write = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);

        // Test 1: x0 always reads zero, even after attempting to write it
        write_reg(5'd0, 32'hFFFF_FFFF);
        check_read(5'd0, 5'd0, 32'h0, 32'h0, "x0_hardwired_zero");

        // Test 2: basic write then read back, distinct registers on rs1/rs2
        write_reg(5'd1, 32'hDEAD_BEEF);
        write_reg(5'd2, 32'hCAFE_F00D);
        check_read(5'd1, 5'd2, 32'hDEAD_BEEF, 32'hCAFE_F00D, "basic_write_read");

        // Test 3: same register on both read ports
        check_read(5'd1, 5'd1, 32'hDEAD_BEEF, 32'hDEAD_BEEF, "same_reg_both_ports");

        // Test 4: write-through forwarding - read rd while a write to the
        // same register is happening in this very cycle should see NEW data
        @(negedge clk);
        rd_addr = 5'd5; rd_data = 32'h1234_5678; reg_write = 1'b1;
        rs1_addr = 5'd5; rs2_addr = 5'd3; // x3 untouched, should read 0
        #1;
        tests = tests + 1;
        if (rs1_data === 32'h1234_5678 && rs2_data === 32'h0) begin
            $display("PASS [write_through_forwarding] rs1(=rd)=0x%08h rs2(x3)=0x%08h", rs1_data, rs2_data);
        end else begin
            $display("FAIL [write_through_forwarding] rs1=0x%08h(exp 0x12345678) rs2=0x%08h(exp 0)", rs1_data, rs2_data);
            errors = errors + 1;
        end
        @(negedge clk);
        reg_write = 1'b0;
        check_read(5'd5, 5'd5, 32'h1234_5678, 32'h1234_5678, "write_through_committed");

        // Test 5: writing to x0 never actually stores anything, even mid-stream
        write_reg(5'd0, 32'hABCD_1234);
        check_read(5'd0, 5'd1, 32'h0, 32'hDEAD_BEEF, "x0_write_ignored_others_intact");

        // Test 6: sweep all 32 registers with unique values, verify no aliasing
        for (i = 1; i < 32; i = i + 1)
            write_reg(i[4:0], {27'b0, i[4:0]} ^ 32'hA5A5_0000);
        for (i = 1; i < 32; i = i + 1) begin
            tests = tests + 1;
            rs1_addr = i[4:0];
            rs2_addr = 5'd0;
            #1;
            if (rs1_data === ({27'b0, i[4:0]} ^ 32'hA5A5_0000)) begin
                $display("PASS [sweep] x%0d = 0x%08h", i, rs1_data);
            end else begin
                $display("FAIL [sweep] x%0d = 0x%08h, expected 0x%08h", i, rs1_data, {27'b0, i[4:0]} ^ 32'hA5A5_0000);
                errors = errors + 1;
            end
        end

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
