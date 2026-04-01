interface control_if(input logic clk);

    // TB -> DUT inputs
    logic       reset;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // DUT outputs
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

    // TB metadata
    int         txn_id;
    int         cycle;

    clocking cb @(posedge clk);
        default input #1step;
        input reset;
        input opcode, funct3, funct7;
        input imm_src, result_src, branch_op;
        input alu_src, pc_base_src, reg_write, mem_write, csr_we;
        input alu_control, width_src, csr_control, csr_src;
    endclocking

endinterface
