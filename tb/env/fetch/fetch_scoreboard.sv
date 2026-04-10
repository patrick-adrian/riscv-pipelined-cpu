class fetch_scoreboard;

    mailbox #(fetch_obs) mon_mbx;

    logic [31:0] expected_pc;
    logic [31:0] next_expected_pc;
    logic [31:0] expected_pc_plus4;

    int num_checked        = 0;
    int num_driven_checked = 0;
    int mismatch_count     = 0;

    function new(mailbox #(fetch_obs) mon_mbx);
        this.mon_mbx = mon_mbx;
        expected_pc = 0;
    endfunction

    task run();
        fetch_obs obs;
        bit pc_mismatch;
        bit pc_plus4_mismatch;
        string check_kind;

        forever begin
            mon_mbx.get(obs);
            next_expected_pc = expected_pc;
            check_kind = obs.tb_valid ? "DRIVEN" : "IDLE";

            if (obs.reset) begin
                next_expected_pc = 0;
            end else if (!obs.stall) begin
                case(obs.pc_src)
                    2'd0: next_expected_pc = expected_pc + 4;
                    2'd1: next_expected_pc = obs.pred_pc_target;
                    2'd2: next_expected_pc = obs.pc_plus4_ex;
                    2'd3: next_expected_pc = obs.pc_target_ex;
                endcase
            end

            expected_pc_plus4 = next_expected_pc + 32'd4;
            pc_mismatch = (next_expected_pc !== obs.pc);
            pc_plus4_mismatch = (expected_pc_plus4 !== obs.pc_plus4);

            if (pc_mismatch || pc_plus4_mismatch) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] SB: %0s mismatch! exp_pc=%h dut_pc=%h exp_pc_plus4=%h dut_pc_plus4=%h\n",
                         $time, obs.cycle, check_kind, next_expected_pc, obs.pc,
                         expected_pc_plus4, obs.pc_plus4);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB: %0s PASS: PC=%h PC+4=%h\n",
                         $time, obs.cycle, check_kind, obs.pc, obs.pc_plus4);
            end
            num_checked++;
            if (obs.tb_valid)
                num_driven_checked++;

            expected_pc = next_expected_pc;
        end
    endtask

endclass

