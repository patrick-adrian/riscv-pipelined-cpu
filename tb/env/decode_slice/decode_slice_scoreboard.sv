class decode_slice_scoreboard;

    mailbox #(decode_slice_obs) mon_mbx;

    logic [31:0] exp_instr;
    logic        exp_valid;
    logic [31:0] exp_pc;
    logic [31:0] exp_pc_plus4;
    logic [31:0] exp_pred_pc_target;
    logic        exp_pc_src_pred;

    int num_checked        = 0;
    int num_driven_checked = 0;
    int mismatch_count     = 0;

    function new(mailbox #(decode_slice_obs) mon_mbx);
        this.mon_mbx = mon_mbx;
        exp_instr = '0;
        exp_valid = 1'b0;
        exp_pc = '0;
        exp_pc_plus4 = '0;
        exp_pred_pc_target = '0;
        exp_pc_src_pred = 1'b0;
    endfunction

    task run();
        decode_slice_obs  obs;

        logic [6:0]  exp_op;
        logic [2:0]  exp_imm_src;
        logic [31:0] exp_imm_ext;
        logic [4:0]  exp_rd, exp_rs1, exp_rs2;
        logic [2:0]  exp_funct3;
        logic [11:0] exp_csr_addr;
        logic        imm_src_mm, imm_ext_mm, instr_mm, valid_mm;
        logic        op_mm, rd_mm, rs1_mm, rs2_mm, f3_mm, csr_mm, f7b5_mm;
        logic        pc_mm, pc_p4_mm, pred_mm, pred_src_mm;
        logic        any_mm;
        string       check_kind;

        forever begin
            mon_mbx.get(obs);

            // Update expected pipeline-register state from the previously sampled
            // TB inputs. The monitor stays passive and simply reports what was on
            // the interface for the cycle that produced the current DUT outputs.
            if (obs.reset || obs.flush) begin
                exp_instr = '0;
                exp_valid = 1'b0;
                exp_pc = '0;
                exp_pc_plus4 = '0;
                exp_pred_pc_target = '0;
                exp_pc_src_pred = 1'b0;
            end else if (!obs.stall) begin
                exp_instr = obs.instr_fi;
                exp_valid = 1'b1;
                exp_pc = obs.pc_fi;
                exp_pc_plus4 = obs.pc_plus4_fi;
                exp_pred_pc_target = obs.pred_pc_target_fi;
                exp_pc_src_pred = obs.pc_src_pred_fi;
            end

            exp_op       = exp_instr[6:0];
            exp_imm_src  = decode_slice_ref_model::expected_imm_src(exp_op);
            exp_imm_ext  = decode_slice_ref_model::expected_imm_ext(exp_instr[31:7], exp_imm_src);
            exp_rd       = exp_instr[11:7];
            exp_rs1      = exp_instr[19:15];
            exp_rs2      = exp_instr[24:20];
            exp_funct3   = exp_instr[14:12];
            exp_csr_addr = exp_instr[31:20];
            check_kind = obs.tb_valid ? "DRIVEN" : "IDLE";

            imm_src_mm  = (exp_imm_src !== obs.imm_src);
            imm_ext_mm  = (exp_imm_ext !== obs.imm_ext_de);
            instr_mm    = (exp_instr !== obs.instr_de);
            valid_mm    = (exp_valid !== obs.valid);
            op_mm       = (exp_op !== obs.op_de);
            rd_mm       = (exp_rd !== obs.rd_de);
            rs1_mm      = (exp_rs1 !== obs.rs1_de);
            rs2_mm      = (exp_rs2 !== obs.rs2_de);
            f3_mm       = (exp_funct3 !== obs.funct3_de);
            csr_mm      = (exp_csr_addr !== obs.csr_addr_de);
            f7b5_mm     = (exp_instr[30] !== obs.funct7_de[5]);
            pc_mm       = (exp_pc !== obs.pc_de);
            pc_p4_mm    = (exp_pc_plus4 !== obs.pc_plus4_de);
            pred_mm     = (exp_pred_pc_target !== obs.pred_pc_target_de);
            pred_src_mm = (exp_pc_src_pred !== obs.pc_src_pred_de);
            any_mm      = imm_src_mm | imm_ext_mm | instr_mm | valid_mm | op_mm
                        | rd_mm | rs1_mm | rs2_mm | f3_mm | csr_mm | f7b5_mm
                        | pc_mm | pc_p4_mm | pred_mm | pred_src_mm;

            if (any_mm) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] SB: %0s MISMATCH", $time, obs.cycle, check_kind);
                $display("  instr:   exp=%h got=%h", exp_instr, obs.instr_de);
                $display("  pc:      exp=%h got=%h", exp_pc, obs.pc_de);
                $display("  pc+4:    exp=%h got=%h", exp_pc_plus4, obs.pc_plus4_de);
                $display("  pred_tgt exp=%h got=%h", exp_pred_pc_target, obs.pred_pc_target_de);
                $display("  pred_src exp=%0b got=%0b", exp_pc_src_pred, obs.pc_src_pred_de);
                $display("  csr_addr exp=%03h got=%03h", exp_csr_addr, obs.csr_addr_de);
                $display("  opcode:  exp=%07b got=%07b", exp_op, obs.op_de);
                $display("  rd/rs1/rs2: exp=%02h/%02h/%02h got=%02h/%02h/%02h",
                         exp_rd, exp_rs1, exp_rs2, obs.rd_de, obs.rs1_de, obs.rs2_de);
                $display("  funct3:  exp=%03b got=%03b", exp_funct3, obs.funct3_de);
                $display("  funct7[5] exp=%0b got=%0b", exp_instr[30], obs.funct7_de[5]);
                $display("  imm_src: exp=%03b got=%03b", exp_imm_src, obs.imm_src);
                $display("  imm_ext: exp=%h got=%h", exp_imm_ext, obs.imm_ext_de);
                $display("  valid:   exp=%0b got=%0b\n", exp_valid, obs.valid);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB: %0s PASS op=%07b imm_src=%03b imm=%h valid=%0b\n",
                         $time, obs.cycle, check_kind, obs.op_de, obs.imm_src, obs.imm_ext_de, obs.valid);
            end

            num_checked++;
            if (obs.tb_valid)
                num_driven_checked++;
        end
    endtask

endclass
