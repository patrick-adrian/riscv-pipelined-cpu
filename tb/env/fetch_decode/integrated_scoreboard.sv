`include "instr_macros.sv"
`include "control_macros.sv"

class integrated_scoreboard;

    localparam int INVALID_FLOW_ID = -1;

    mailbox #(integrated_obs) mon_mbx;

    logic [31:0] held_fetch_pc;

    bit          pending_valid;
    logic [31:0] pending_instr;
    logic [31:0] pending_pc;
    int          pending_flow_id;

    bit          held_valid;
    logic [31:0] held_instr;
    logic [31:0] held_pc;
    int          held_flow_id;

    int active_fetch_flow_id;
    int next_flow_id;

    int num_checked        = 0;
    int num_fetch_checks   = 0;
    int num_decode_checks  = 0;
    int num_control_checks = 0;
    int mismatch_count     = 0;

    function new(mailbox #(integrated_obs) mon_mbx);
        this.mon_mbx = mon_mbx;
        held_fetch_pc        = 32'h0;
        pending_valid        = 1'b0;
        pending_instr        = 32'h0;
        pending_pc           = 32'h0;
        pending_flow_id      = INVALID_FLOW_ID;
        held_valid           = 1'b0;
        held_instr           = 32'h0;
        held_pc              = 32'h0;
        held_flow_id         = INVALID_FLOW_ID;
        active_fetch_flow_id = INVALID_FLOW_ID;
        next_flow_id         = 1;
    endfunction

    function automatic logic [31:0] compute_pc_next(integrated_obs obs);
        case (obs.pc_src)
            `PC_SRC_SEQ_F:    return obs.pc + 32'd4;
            `PC_SRC_PRED_F:   return obs.pred_pc_target_fi;
            `PC_SRC_SEQ_E:    return obs.pc_plus4_ex;
            `PC_SRC_TARGET_E: return obs.pc_target_ex;
            default:          return 32'h0;
        endcase
    endfunction

    function automatic bit ctrl_matches(
        input control_signals_t got,
        input control_signals_t exp
    );
        return (got.imm_src     === exp.imm_src)     &&
               (got.result_src  === exp.result_src)  &&
               (got.branch_op   === exp.branch_op)   &&
               (got.alu_src     === exp.alu_src)     &&
               (got.pc_base_src === exp.pc_base_src) &&
               (got.reg_write   === exp.reg_write)   &&
               (got.mem_write   === exp.mem_write)   &&
               (got.csr_we      === exp.csr_we)      &&
               (got.alu_control === exp.alu_control) &&
               (got.width_src   === exp.width_src)   &&
               (got.csr_control === exp.csr_control) &&
               (got.csr_src     === exp.csr_src);
    endfunction

    function automatic bit ctrl_is_known(input control_signals_t ctrl);
        return !$isunknown({
            ctrl.imm_src,
            ctrl.result_src,
            ctrl.branch_op,
            ctrl.alu_src,
            ctrl.pc_base_src,
            ctrl.reg_write,
            ctrl.mem_write,
            ctrl.csr_we,
            ctrl.alu_control,
            ctrl.width_src,
            ctrl.csr_control,
            ctrl.csr_src
        });
    endfunction

    function automatic string cycle_kind(integrated_obs obs);
        if (obs.reset)
            return "RESET";
        if (obs.flush_de)
            return "FLUSH";
        if (obs.stall_fi || obs.stall_de)
            return "STALL";
        if (obs.is_bubble)
            return "BUBBLE";
        return "NORMAL";
    endfunction

    function automatic logic [31:0] expected_pc_this_cycle(integrated_obs obs);
        if (obs.reset)
            return 32'h0;
        if (obs.stall_fi)
            return held_fetch_pc;

        case (obs.pc_src)
            `PC_SRC_SEQ_F:    return held_fetch_pc + 32'd4;
            `PC_SRC_PRED_F:   return obs.pred_pc_target_fi;
            `PC_SRC_SEQ_E:    return obs.pc_plus4_ex;
            `PC_SRC_TARGET_E: return obs.pc_target_ex;
            default:          return 32'h0;
        endcase
    endfunction

    task run();
        integrated_obs                 obs;
        logic [31:0]                  exp_pc_this_cycle;
        logic [31:0]                  exp_pc_next;
        int                           current_fetch_flow_id;
        bit                           cur_decode_valid;
        logic [31:0]                  cur_decode_instr;
        logic [31:0]                  cur_decode_pc;
        int                           cur_decode_flow_id;
        logic [2:0]                   exp_imm_src;
        logic [31:0]                  exp_imm;
        logic [4:0]                   exp_rd;
        logic [4:0]                   exp_rs1;
        logic [4:0]                   exp_rs2;
        logic [6:0]                   exp_opcode;
        logic [2:0]                   exp_funct3;
        logic [6:0]                   exp_funct7;
        control_ref_model::control_exp_t exp_ctrl_decoded;
        control_signals_t             exp_ctrl;
        bit                           fetch_failed;
        bit                           decode_failed;
        bit                           control_failed;
        string                        kind;

        forever begin
            mon_mbx.get(obs);
            kind = cycle_kind(obs);

            if (active_fetch_flow_id == INVALID_FLOW_ID)
                active_fetch_flow_id = next_flow_id++;
            current_fetch_flow_id = active_fetch_flow_id;

            exp_pc_this_cycle = expected_pc_this_cycle(obs);
            exp_pc_next = compute_pc_next(obs);

            cur_decode_valid   = 1'b0;
            cur_decode_instr   = 32'h0;
            cur_decode_pc      = 32'h0;
            cur_decode_flow_id = INVALID_FLOW_ID;

            if (obs.reset || obs.flush_de) begin
                cur_decode_valid = 1'b0;
            end else if (obs.stall_de) begin
                cur_decode_valid   = held_valid;
                cur_decode_instr   = held_instr;
                cur_decode_pc      = held_pc;
                cur_decode_flow_id = held_flow_id;
            end else if (pending_valid) begin
                cur_decode_valid   = 1'b1;
                cur_decode_instr   = pending_instr;
                cur_decode_pc      = pending_pc;
                cur_decode_flow_id = pending_flow_id;
            end

            exp_opcode = cur_decode_instr[6:0];
            exp_funct3 = cur_decode_instr[14:12];
            exp_funct7 = {6'b0, cur_decode_instr[30]};
            exp_rd     = cur_decode_instr[11:7];
            exp_rs1    = cur_decode_instr[19:15];
            exp_rs2    = cur_decode_instr[24:20];
            exp_imm_src = decode_slice_ref_model::expected_imm_src(exp_opcode);
            exp_imm     = decode_slice_ref_model::expected_imm_ext(cur_decode_instr[31:7], exp_imm_src);

            if (cur_decode_valid)
                exp_ctrl_decoded = control_ref_model::decode_expected_instr(cur_decode_instr);
            else
                exp_ctrl_decoded = control_ref_model::decode_expected_instr(32'h0);
            exp_ctrl = control_ref_model::to_control_signals(exp_ctrl_decoded);

            fetch_failed = (exp_pc_this_cycle !== obs.pc) || (exp_pc_next !== obs.pc_next);
            decode_failed = (cur_decode_valid !== obs.valid_d) ||
                            (cur_decode_instr !== obs.instr_d) ||
                            (exp_imm !== obs.imm) ||
                            (exp_rd !== obs.rd) ||
                            (exp_rs1 !== obs.rs1) ||
                            (exp_rs2 !== obs.rs2) ||
                            (exp_opcode !== obs.opcode) ||
                            (exp_funct3 !== obs.funct3) ||
                            (exp_funct7 !== obs.funct7) ||
                            ((cur_decode_valid ? cur_decode_flow_id : INVALID_FLOW_ID) !== obs.flow_id);
            control_failed = !ctrl_is_known(obs.ctrl) || !ctrl_matches(obs.ctrl, exp_ctrl);

            if (fetch_failed || decode_failed || control_failed) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] FDC_SB: %0s FAIL", $time, obs.cycle, kind);
                if (fetch_failed) begin
                    $display("  FETCH: exp_pc=%08h got_pc=%08h exp_next=%08h got_next=%08h",
                             exp_pc_this_cycle, obs.pc, exp_pc_next, obs.pc_next);
                end
                if (decode_failed) begin
                    $display("  DECODE: exp_valid=%0b got_valid=%0b exp_instr=%08h got_instr=%08h",
                             cur_decode_valid, obs.valid_d, cur_decode_instr, obs.instr_d);
                    $display("          exp_imm=%08h got_imm=%08h exp_rd/rs1/rs2=%0d/%0d/%0d got=%0d/%0d/%0d",
                             exp_imm, obs.imm, exp_rd, exp_rs1, exp_rs2, obs.rd, obs.rs1, obs.rs2);
                    $display("          exp_op/f3/f7=%07b/%03b/%07b got=%07b/%03b/%07b exp_flow=%0d got_flow=%0d",
                             exp_opcode, exp_funct3, exp_funct7, obs.opcode, obs.funct3, obs.funct7,
                             (cur_decode_valid ? cur_decode_flow_id : INVALID_FLOW_ID), obs.flow_id);
                end
                if (control_failed) begin
                    $display("  CONTROL: exp imm_src=%03b got=%03b exp result_src=%03b got=%03b",
                             exp_ctrl.imm_src, obs.ctrl.imm_src, exp_ctrl.result_src, obs.ctrl.result_src);
                    $display("           exp branch_op=%02b got=%02b exp alu_control=%04b got=%04b",
                             exp_ctrl.branch_op, obs.ctrl.branch_op, exp_ctrl.alu_control, obs.ctrl.alu_control);
                    $display("           exp reg_write=%0b got=%0b exp mem_write=%0b got=%0b exp csr_we=%0b got=%0b",
                             exp_ctrl.reg_write, obs.ctrl.reg_write, exp_ctrl.mem_write, obs.ctrl.mem_write,
                             exp_ctrl.csr_we, obs.ctrl.csr_we);
                end
            end else begin
                $display("[TIME %0t][CYCLE %0d] FDC_SB: %0s PASS pc=%08h instr_f=%08h instr_d=%08h flow=%0d",
                         $time, obs.cycle, kind, obs.pc, obs.instr_f, obs.instr_d, obs.flow_id);
            end

            num_checked++;
            num_fetch_checks++;
            num_decode_checks++;
            num_control_checks++;

            held_valid   = cur_decode_valid;
            held_instr   = cur_decode_instr;
            held_pc      = cur_decode_pc;
            held_flow_id = cur_decode_flow_id;

            pending_valid   = 1'b1;
            pending_instr   = obs.instr_f;
            pending_pc      = obs.pc;
            pending_flow_id = current_fetch_flow_id;
            held_fetch_pc   = obs.pc;

            if (obs.reset) begin
                held_valid       = 1'b0;
                held_instr       = 32'h0;
                held_pc          = 32'h0;
                held_flow_id     = INVALID_FLOW_ID;
                active_fetch_flow_id = current_fetch_flow_id;
            end else begin
                if (!obs.stall_fi)
                    active_fetch_flow_id = next_flow_id++;
                else
                    active_fetch_flow_id = current_fetch_flow_id;
            end
        end
    endtask

endclass
