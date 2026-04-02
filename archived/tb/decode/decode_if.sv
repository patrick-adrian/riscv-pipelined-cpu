interface decode_if(input logic clk);

    // ------------------------
    // Testbench -> DUT inputs
    // ------------------------
    logic        reset;
    logic        pc_src_pred_fi;
    logic        stall;
    logic        flush;

    logic [31:0] instr_fi_i;
    logic [31:0] pc_fi_i;
    logic [31:0] pc_plus4_fi_i;
    logic [31:0] pred_pc_target_fi;
    logic [2:0]  imm_src_de_i;

    // ------------------------
    // DUT -> Testbench outputs
    // ------------------------
    logic [31:0] instr_de_o;
    logic [31:0] imm_ext_de_o;
    logic [31:0] pc_de_o;
    logic [31:0] pc_plus4_de_o;
    logic [31:0] pred_pc_target_de_o;
    logic [11:0] csr_addr_de_o;
    logic [4:0]  rd_de_o;
    logic [4:0]  rs1_de_o;
    logic [4:0]  rs2_de_o;
    logic [6:0]  op_de_o;
    logic [2:0]  funct3_de_o;
    logic [6:0]  funct7_de_o;
    logic        pc_src_pred_de_o;
    logic        valid_de_o;

    // ------------------------
    // TB metadata
    // ------------------------
    int          txn_tag;
    int          cycle;

    // Clocking block used to synchronize the passive monitor to each decode clock.
    clocking cb @(posedge clk);
        default input #1step;
        input  reset;
        input  pc_src_pred_fi, stall, flush;
        input  imm_src_de_i;
        input  instr_fi_i, pc_fi_i, pc_plus4_fi_i, pred_pc_target_fi;
        // Outputs are sampled via raw interface after the clocking event.
    endclocking

endinterface

