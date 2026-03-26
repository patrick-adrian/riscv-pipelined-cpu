class fetch_scoreboard;

    virtual fetch_if vif;
    mailbox #(fetch_txn) drv_mbx;
    mailbox #(fetch_obs) mon_mbx;

    logic [31:0] expected_pc;
    logic [31:0] next_expected_pc;
    logic [31:0] expected_pc_plus4;

    int num_checked = 0;
    int mismatch_count = 0;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_txn) drv_mbx,
                 mailbox #(fetch_obs) mon_mbx);
        this.vif     = vif;
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;
        expected_pc = 0;
    endfunction

    task run();
        fetch_txn txn;
        fetch_obs obs;
        bit pc_mismatch;
        bit pc_plus4_mismatch;

        forever begin
            // Get the next expected input transaction.
            drv_mbx.get(txn);

            // The passive monitor samples every fetch clock, including idle and
            // reset-only cycles. Only observations carrying the driver's TB tag
            // are scoreboard work for this transaction.
            do begin
                mon_mbx.get(obs);
            end while (obs.txn_tag != txn.id);

            // Compute the expected next PC and compare it against the sampled
            // post-clock DUT output for the matching cycle.
            next_expected_pc = expected_pc;

            // Reset is driven to be stable before the sampling posedge; when the
            // observation sees reset high, that cycle's DUT PC is expected at 0.
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
                $display("[TIME %0t][CYCLE %0d] SB  TXN[%0d]: Mismatch! exp_pc=%h dut_pc=%h exp_pc_plus4=%h dut_pc_plus4=%h\n",
                         $time, obs.cycle, txn.id, next_expected_pc, obs.pc,
                         expected_pc_plus4, obs.pc_plus4);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB  TXN[%0d]: PASS: PC=%h PC+4=%h\n",
                         $time, obs.cycle, txn.id, obs.pc, obs.pc_plus4);
            end
            num_checked++;

            // Update expected_pc for the following cycle.
            expected_pc = next_expected_pc;
        end
    endtask

endclass

