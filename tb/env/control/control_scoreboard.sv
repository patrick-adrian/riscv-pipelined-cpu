class control_scoreboard;

    mailbox #(control_obs) mon_mbx;

    int num_checked           = 0;
    int num_driven_checked    = 0;
    int num_functional_checks = 0;
    int num_invariant_checks  = 0;
    int mismatch_count        = 0;

    function new(mailbox #(control_obs) mon_mbx);
        this.mon_mbx = mon_mbx;
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

    task automatic report_ctrl_mismatch(
        input string            label,
        input int               cycle,
        input logic [31:0]      instr,
        input control_signals_t got,
        input control_signals_t exp
    );
        $display("[TIME %0t][CYCLE %0d] SB: %0s mismatch instr=%08h",
                 $time, cycle, label, instr);
        $display("  imm_src:     exp=%03b got=%03b", exp.imm_src, got.imm_src);
        $display("  result_src:  exp=%03b got=%03b", exp.result_src, got.result_src);
        $display("  branch_op:   exp=%02b got=%02b", exp.branch_op, got.branch_op);
        $display("  alu_src:     exp=%0b got=%0b", exp.alu_src, got.alu_src);
        $display("  pc_base_src: exp=%0b got=%0b", exp.pc_base_src, got.pc_base_src);
        $display("  reg_write:   exp=%0b got=%0b", exp.reg_write, got.reg_write);
        $display("  mem_write:   exp=%0b got=%0b", exp.mem_write, got.mem_write);
        $display("  csr_we:      exp=%0b got=%0b", exp.csr_we, got.csr_we);
        $display("  alu_control: exp=%04b got=%04b", exp.alu_control, got.alu_control);
        $display("  width_src:   exp=%03b got=%03b", exp.width_src, got.width_src);
        $display("  csr_control: exp=%02b got=%02b", exp.csr_control, got.csr_control);
        $display("  csr_src:     exp=%0b got=%0b\n", exp.csr_src, got.csr_src);
    endtask

    task run();
        control_obs obs;
        control_ref_model::control_exp_t exp;
        control_signals_t exp_ctrl;
        bit check_failed;
        string check_kind;
        string check_label;

        forever begin
            mon_mbx.get(obs);
            check_failed = 1'b0;
            check_kind   = obs.tb_valid ? "DRIVEN" : "IDLE";
            check_label  = "UNKNOWN";

            if (!ctrl_is_known(obs.ctrl)) begin
                mismatch_count++;
                check_failed = 1'b1;
                check_label = "X/Z";
                #1ps;
                $display("[TIME %0t][CYCLE %0d] SB: %0s control outputs contain X/Z during sampled cycle",
                         $time, obs.cycle, check_kind);
            end else if (obs.reset) begin
                check_label = "RESET";
                num_invariant_checks++;
            end else begin
                check_label = control_ref_model::instruction_type(
                    obs.instr_de[6:0], obs.instr_de[14:12], obs.instr_de[31:25]
                );
                if (obs.tb_valid)
                    num_functional_checks++;
                exp      = control_ref_model::decode_expected_instr(obs.instr_de);
                exp_ctrl = control_ref_model::to_control_signals(exp);

                if (!ctrl_matches(obs.ctrl, exp_ctrl)) begin
                    mismatch_count++;
                    check_failed = 1'b1;
                    report_ctrl_mismatch(
                        check_label,
                        obs.cycle,
                        obs.instr_de,
                        obs.ctrl,
                        exp_ctrl
                    );
                end
            end

            #1ps;
            if (check_failed) begin
                $display("[TIME %0t][CYCLE %0d] SB: %0s FAIL (%0s) instr=%08h\n",
                         $time, obs.cycle, check_kind, check_label, obs.instr_de);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB: %0s PASS (%0s) instr=%08h\n",
                         $time, obs.cycle, check_kind, check_label, obs.instr_de);
            end

            num_checked++;
            if (obs.tb_valid)
                num_driven_checked++;
        end
    endtask

endclass
