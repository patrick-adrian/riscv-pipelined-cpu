class decode_obs;

    int txn_tag;
    int cycle;

    logic        reset;
    logic        stall;
    logic        flush;
    logic [2:0]  imm_src_de_i;

    // DUT outputs
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

    function void display(string prefix = "MON");
        $display("[CYCLE %0d] %0s: tag=%0d reset=%0b stall=%0b flush=%0b valid=%0b instr=%h imm_ext=%h pc=%h pc+4=%h",
                 cycle, prefix, txn_tag, reset, stall, flush, valid_de_o, instr_de_o,
                 imm_ext_de_o, pc_de_o, pc_plus4_de_o);
    endfunction

    function bit matches_txn(decode_txn txn);
        return (txn_tag == txn.id);
    endfunction

endclass

