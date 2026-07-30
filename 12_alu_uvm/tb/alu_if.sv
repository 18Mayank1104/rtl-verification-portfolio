// ============================================================
// ALU Interface
// Bundles DUT signals for clean connection to the UVM driver
// and monitor via a virtual interface handle in the config db.
// ============================================================
interface alu_if #(parameter WIDTH = 8);
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [2:0]       op_sel;
    logic [WIDTH-1:0] result;
    logic             zero;
    logic             carry;
    logic             overflow;
endinterface
