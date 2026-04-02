// Combinational DUT: no clock or reset on interface. txn_id is TB-only tagging.
// valid: driver pulses high when opcode/funct/txn_id are driven; passive monitor samples while valid.
interface control_if;

    logic       valid;
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

    int         txn_id;

endinterface
