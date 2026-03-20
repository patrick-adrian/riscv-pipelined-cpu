class fetch_scoreboard;

    virtual fetch_if vif;
    mailbox #(fetch_txn)    drv_mbx;
    mailbox #(logic [31:0]) mon_mbx;

    logic [31:0] expected_pc;
    logic [31:0] next_expected_pc;

    int num_checked = 0;
    int mismatch_count = 0;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_txn) drv_mbx,
                 mailbox #(logic [31:0]) mon_mbx);
        this.vif     = vif;
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;
        expected_pc = 0;
    endfunction

    task run();
        fetch_txn txn;
        logic [31:0] dut_pc;

        forever begin
            // Get the next transaction and the corresponding DUT PC sample
            // taken on the same posedge that the driver applied this txn's
            // control inputs.
            drv_mbx.get(txn);
            mon_mbx.get(dut_pc);

            // Compute the expected next PC and compare it against the DUT's
            // posedge-updated output.
            next_expected_pc = expected_pc;

            // Reset forces the DUT PC back to 0; keep the reference model in sync.
            if (vif.reset) begin
                next_expected_pc = 0;
            end else if (!txn.stall) begin
                case(txn.pc_src)
                    2'd0: next_expected_pc = expected_pc + 4;
                    2'd1: next_expected_pc = txn.pred_pc_target;
                    2'd2: next_expected_pc = txn.pc_plus4_ex;
                    2'd3: next_expected_pc = txn.pc_target_ex;
                endcase
            end

            if (next_expected_pc !== dut_pc) begin
                mismatch_count++;
                $display("[CYCLE %0d] SB TXN[%0d]: Mismatch! Model=%h DUT=%h \n",
                         vif.cycle, txn.id, next_expected_pc, dut_pc);
            end else begin
                $display("[CYCLE %0d] SB TXN[%0d]: PASS: PC=%h \n",
                         vif.cycle, txn.id, dut_pc);
            end
            num_checked++;

            // Update expected_pc for the following cycle.
            expected_pc = next_expected_pc;
        end
    endtask

endclass

