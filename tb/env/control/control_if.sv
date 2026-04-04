typedef struct packed {
    logic [2:0] imm_src;
    logic [2:0] result_src;
    logic [1:0] branch_op;
    logic       alu_src;
    logic       pc_base_src;
    logic       reg_write;
    logic       mem_write;
    logic       csr_we;
    logic [3:0] alu_control;
    logic [2:0] width_src;
    logic [1:0] csr_control;
    logic       csr_src;
} control_signals_t;

// Testbench contract for a clocked control-stage environment. The DUT itself
// is still combinational; clk/reset/valid only define the cycle semantics used
// by the driver, monitor, and scoreboard.
interface control_if(input logic clk);

    logic       reset;
    logic       valid;
    logic [31:0] instr;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [2:0] imm_src;
    logic [2:0] result_src;
    logic [1:0] branch_op;
    logic       alu_src;
    logic       pc_base_src;
    logic       reg_write;
    logic       mem_write;
    logic       csr_we;
    logic [3:0] alu_control;
    logic [2:0] width_src;
    logic [1:0] csr_control;
    logic       csr_src;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    function automatic control_signals_t sample_ctrl();
        control_signals_t ctrl;

        ctrl.imm_src     = imm_src;
        ctrl.result_src  = result_src;
        ctrl.branch_op   = branch_op;
        ctrl.alu_src     = alu_src;
        ctrl.pc_base_src = pc_base_src;
        ctrl.reg_write   = reg_write;
        ctrl.mem_write   = mem_write;
        ctrl.csr_we      = csr_we;
        ctrl.alu_control = alu_control;
        ctrl.width_src   = width_src;
        ctrl.csr_control = csr_control;
        ctrl.csr_src     = csr_src;

        return ctrl;
    endfunction

endinterface
