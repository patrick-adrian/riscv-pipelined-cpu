`include "instr_macros.sv"
`include "control_macros.sv"

class fetch_decode_base_test;

    protected virtual fetch_decode_control_if vif;
    protected fetch_decode_env                env;

    function new(virtual fetch_decode_control_if vif, fetch_decode_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    task assert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b1;
        $display("[TIME %0t] RESET ASSERTED", $time);
    endtask

    task deassert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b0;
        $display("[TIME %0t] RESET DEASSERTED", $time);
    endtask

    task apply_reset(int cycles = 1);
        assert_reset();
        repeat (cycles) @(posedge vif.clk);
        deassert_reset();
    endtask

    task run_cycles(int cycles);
        repeat (cycles)
            @(posedge vif.clk);
    endtask

    task clear_program();
        vif.clear_program();
    endtask

    task load_program_word(int word_idx, logic [31:0] instr);
        vif.load_program_word(word_idx, instr);
    endtask

    task load_program_file(string path);
        vif.load_program_file(path);
    endtask

    task send_ctrl_txn(
        input string      name,
        // Control-owned inputs that steer fetch and determine whether decode
        // advances, stalls, or flushes on the following cycle.
        input logic [1:0] pc_src = `PC_SRC_SEQ_F,
        input logic       stall_fi = 1'b0,
        input logic       stall_de = 1'b0,
        input logic       flush_de = 1'b0,
        input logic [31:0] pc_target_ex = 32'h0,
        input logic [31:0] pc_plus4_ex = 32'h0,
        input logic [31:0] pred_pc_target_fi = 32'h0,
        input logic        pc_src_pred_fi = 1'b0
    );
        fetch_decode_txn t = new();
        t.cycle_name        = name;
        t.pc_src            = pc_src;
        t.stall_fi          = stall_fi;
        t.stall_de          = stall_de;
        t.flush_de          = flush_de;
        t.pc_target_ex      = pc_target_ex;
        t.pc_plus4_ex       = pc_plus4_ex;
        t.pred_pc_target_fi = pred_pc_target_fi;
        t.pc_src_pred_fi    = pc_src_pred_fi;
        env.put_txn(t);
    endtask

    function automatic logic [31:0] encode_r_type(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] encode_i_type(
        input integer      imm12,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [4:0]  rd,
        input logic [6:0]  opcode
    );
        logic [11:0] imm_bits;
        imm_bits = imm12[11:0];
        return {imm_bits, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] encode_b_type(
        input integer      imm13,
        input logic [4:0]  rs2,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [6:0]  opcode
    );
        logic [12:0] imm_bits;
        imm_bits = imm13[12:0];
        return {
            imm_bits[12],
            imm_bits[10:5],
            rs2,
            rs1,
            funct3,
            imm_bits[4:1],
            imm_bits[11],
            opcode
        };
    endfunction

    function automatic logic [31:0] encode_addi(
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input integer     imm
    );
        return encode_i_type(imm, rs1, `F3_ADD_SUB, rd, `I_TYPE_ALU_OP);
    endfunction

    function automatic logic [31:0] encode_add(
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2
    );
        return encode_r_type(`FUNCT7_ADD_SRL, rs2, rs1, `F3_ADD_SUB, rd, `R_TYPE_OP);
    endfunction

    function automatic logic [31:0] encode_beq(
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input integer     imm
    );
        return encode_b_type(imm, rs2, rs1, `F3_BEQ, `B_TYPE_OP);
    endfunction

    function automatic logic [31:0] encode_nop();
        return `NOP_INSTR;
    endfunction

    virtual task run();
        $fatal(1, "fetch_decode_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.report_results();
    endtask

endclass
