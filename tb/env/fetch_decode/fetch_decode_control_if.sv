`include "instr_macros.sv"

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

interface fetch_decode_control_if #(parameter int IMEM_DEPTH = 64) (input logic clk);

    // Testbench handshake and shared reset.
    logic reset;
    logic is_new_txn;

    // Control-driven fetch steering inputs.
    logic [1:0]  pc_src;
    logic        stall_fi;
    logic        stall_de;
    logic        flush_de;
    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target_fi;
    logic        pc_src_pred_fi;

    // Backing store for fetch instruction memory.
    logic [31:0] program_mem[0:IMEM_DEPTH-1];

    // Fetch-stage observations.
    logic [31:0] pc_f;
    logic [31:0] pc_next_f;
    logic [31:0] pc_plus4_f;
    logic [31:0] instr_f;

    // Decode-stage observations.
    logic [31:0] instr_d;
    logic [31:0] imm_d;
    logic [31:0] pc_d;
    logic [31:0] pc_plus4_d;
    logic [31:0] pred_pc_target_d;
    logic [11:0] csr_addr_d;
    logic [4:0]  rd_d;
    logic [4:0]  rs1_d;
    logic [4:0]  rs2_d;
    logic [6:0]  opcode_d;
    logic [2:0]  funct3_d;
    logic [6:0]  funct7_d;
    logic        pc_src_pred_d;
    logic        valid_d;

    // Control-unit outputs derived from decode fields.
    logic [2:0] imm_src_ctrl;
    logic [2:0] result_src_ctrl;
    logic [1:0] branch_op_ctrl;
    logic       alu_src_ctrl;
    logic       pc_base_src_ctrl;
    logic       reg_write_ctrl;
    logic       mem_write_ctrl;
    logic       csr_we_ctrl;
    logic [3:0] alu_control_ctrl;
    logic [2:0] width_src_ctrl;
    logic [1:0] csr_control_ctrl;
    logic       csr_src_ctrl;

    task automatic clear_program();
        for (int i = 0; i < IMEM_DEPTH; i++) begin
            program_mem[i] = `NOP_INSTR;
        end
    endtask

    task automatic load_program_word(input int word_idx, input logic [31:0] instr);
        if (word_idx < 0 || word_idx >= IMEM_DEPTH) begin
            $fatal(1, "Program word index %0d is outside IMEM depth %0d", word_idx, IMEM_DEPTH);
        end
        program_mem[word_idx] = instr;
    endtask

    task automatic load_program_file(input string path);
        $readmemh(path, program_mem);
    endtask

    function automatic logic [31:0] program_word_at_pc(input logic [31:0] pc);
        if (pc[31:2] >= IMEM_DEPTH)
            return `NOP_INSTR;
        return program_mem[pc[31:2]];
    endfunction

    function automatic control_signals_t sample_ctrl();
        control_signals_t ctrl;

        ctrl.imm_src     = imm_src_ctrl;
        ctrl.result_src  = result_src_ctrl;
        ctrl.branch_op   = branch_op_ctrl;
        ctrl.alu_src     = alu_src_ctrl;
        ctrl.pc_base_src = pc_base_src_ctrl;
        ctrl.reg_write   = reg_write_ctrl;
        ctrl.mem_write   = mem_write_ctrl;
        ctrl.csr_we      = csr_we_ctrl;
        ctrl.alu_control = alu_control_ctrl;
        ctrl.width_src   = width_src_ctrl;
        ctrl.csr_control = csr_control_ctrl;
        ctrl.csr_src     = csr_src_ctrl;

        return ctrl;
    endfunction

endinterface
