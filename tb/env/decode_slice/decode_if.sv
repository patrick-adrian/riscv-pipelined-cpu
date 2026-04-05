interface ds_if(input logic clk);

    // TB → DUT inputs
    logic        tb_valid;
    logic        reset;
    logic        stall;
    logic        flush;
    logic [31:0] instr_fi;
    logic [31:0] pc_fi;
    logic [31:0] pc_plus4_fi;
    logic [31:0] pred_pc_target_fi;
    logic        pc_src_pred_fi;

    // Main decoder → DUT feedback (wired in tb_top, observable by monitor)
    logic [2:0]  imm_src;

    // DUT outputs
    logic [31:0] instr_de;
    logic [31:0] imm_ext_de;
    logic [31:0] pc_de;
    logic [31:0] pc_plus4_de;
    logic [31:0] pred_pc_target_de;
    logic [11:0] csr_addr_de;
    logic [4:0]  rd_de;
    logic [4:0]  rs1_de;
    logic [4:0]  rs2_de;
    logic [6:0]  op_de;
    logic [2:0]  funct3_de;
    logic [6:0]  funct7_de;
    logic        pc_src_pred_de;
    logic        valid_de;

    // TB metadata
    int          cycle;

endinterface
