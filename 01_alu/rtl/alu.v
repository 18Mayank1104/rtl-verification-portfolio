 
// 8-bit ALU
// Combinational ALU supporting arithmetic, logic and shift ops

module alu #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0]       op_sel,   // operation select
    output reg  [WIDTH-1:0] result,
    output wire              zero,     // result == 0
    output reg               carry,    // carry/borrow out
    output wire              overflow  // signed overflow (add/sub only)
);

    // Operation encoding
    localparam OP_ADD  = 3'b000;
    localparam OP_SUB  = 3'b001;
    localparam OP_AND  = 3'b010;
    localparam OP_OR   = 3'b011;
    localparam OP_XOR  = 3'b100;
    localparam OP_NOT  = 3'b101;
    localparam OP_SHL  = 3'b110;
    localparam OP_SHR  = 3'b111;

    reg signed_ovf;

    always @(*) begin
        carry      = 1'b0;
        signed_ovf = 1'b0;
        case (op_sel)
            OP_ADD: begin
                {carry, result} = a + b;
                signed_ovf = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            OP_SUB: begin
                {carry, result} = a - b;      // carry here doubles as borrow
                signed_ovf = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end
            OP_AND: result = a & b;
            OP_OR : result = a | b;
            OP_XOR: result = a ^ b;
            OP_NOT: result = ~a;
            OP_SHL: {carry, result} = {1'b0, a} << b[3:0];
            OP_SHR: begin
                result = a >> b[3:0];
                carry  = a[0];
            end
            default: result = {WIDTH{1'bx}};
        endcase
    end

    assign zero     = (result == {WIDTH{1'b0}});
    assign overflow = signed_ovf;

endmodule
