class integrated_obs;

    // Cycle bookkeeping and control handshakes shared across the slice.
    int               cycle;
    bit               reset;
    bit               stall_fi;
    bit               stall_de;
    bit               flush_de;
    bit               is_new_txn;
    bit               is_bubble;
    int               flow_id;

    // Control redirect inputs that determine fetch sequencing.
    logic [1:0]       pc_src;
    logic [31:0]      pc_target_ex;
    logic [31:0]      pc_plus4_ex;
    logic [31:0]      pred_pc_target_fi;
    logic             pc_src_pred_fi;

    // Fetch-stage observations.
    logic [31:0]      pc;
    logic [31:0]      pc_next;
    logic [31:0]      instr_f;

    // Decode-stage observations.
    logic [31:0]      instr_d;
    logic [31:0]      imm;
    logic [4:0]       rs1;
    logic [4:0]       rs2;
    logic [4:0]       rd;
    logic             valid_d;

    // Control outputs decoded from the instruction in decode.
    logic [6:0]       opcode;
    logic [2:0]       funct3;
    logic [6:0]       funct7;
    control_signals_t ctrl;

    function void display(string prefix = "MON");
        $display("[CYCLE %0d][FLOW %0d] %0s: reset=%0b stall_fi=%0b stall_de=%0b flush_de=%0b bubble=%0b new_txn=%0b PC=%08h NEXT=%08h INSTR_F=%08h INSTR_D=%08h",
                 cycle, flow_id, prefix, reset, stall_fi, stall_de, flush_de, is_bubble,
                 is_new_txn, pc, pc_next, instr_f, instr_d);
    endfunction

endclass
