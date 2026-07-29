
// Self-checking testbench for 8-bit ALU

`timescale 1ns/1ps

module tb_alu;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0] a, b;
    reg  [2:0]        op_sel;
    wire [WIDTH-1:0] result;
    wire              zero, carry, overflow;

    integer errors = 0;
    integer tests  = 0;

    alu #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .op_sel(op_sel),
        .result(result), .zero(zero), .carry(carry), .overflow(overflow)
    );

    task check(input [WIDTH-1:0] exp_result, input exp_zero, input [127:0] name);
        begin
            tests = tests + 1;
            #1;
            if (result !== exp_result || zero !== exp_zero) begin
                errors = errors + 1;
                $display("FAIL [%0s] a=%0d b=%0d op=%0d -> got result=%0d zero=%0b, expected result=%0d zero=%0b",
                          name, a, b, op_sel, result, zero, exp_result, exp_zero);
            end else begin
                $display("PASS [%0s] a=%0d b=%0d op=%0d -> result=%0d", name, a, b, op_sel, result);
            end
        end
    endtask

    initial begin
        // ADD
        a = 8'd10; b = 8'd20; op_sel = 3'b000; check(30, 0, "ADD");
        a = 8'd200; b = 8'd100; op_sel = 3'b000; check(8'd44, 0, "ADD_OVERFLOW_WRAP"); // 300 mod 256 = 44

        // SUB
        a = 8'd50; b = 8'd20; op_sel = 3'b001; check(30, 0, "SUB");
        a = 8'd5; b = 8'd10; op_sel = 3'b001; check(8'd251, 0, "SUB_BORROW"); // 5-10 = -5 -> 251

        // AND / OR / XOR / NOT
        a = 8'hF0; b = 8'h0F; op_sel = 3'b010; check(8'h00, 1, "AND");
        a = 8'hF0; b = 8'h0F; op_sel = 3'b011; check(8'hFF, 0, "OR");
        a = 8'hFF; b = 8'h0F; op_sel = 3'b100; check(8'hF0, 0, "XOR");
        a = 8'h0F; b = 8'h00; op_sel = 3'b101; check(8'hF0, 0, "NOT");

        // Shifts
        a = 8'h01; b = 8'd3;  op_sel = 3'b110; check(8'h08, 0, "SHL");
        a = 8'h80; b = 8'd3;  op_sel = 3'b111; check(8'h10, 0, "SHR");

        // Zero flag edge case
        a = 8'h00; b = 8'h00; op_sel = 3'b011; check(8'h00, 1, "OR_ZERO");

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
