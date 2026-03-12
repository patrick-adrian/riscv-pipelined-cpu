class fetch_scoreboard;

    virtual fetch_if vif;
    mailbox #(fetch_txn) drv_mbx;
    mailbox #(logic [31:0]) mon_mbx;

    logic [31:0] expected_pc;
    logic [31:0] next_expected_pc;

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
            drv_mbx.get(txn);
            mon_mbx.get(dut_pc);

            // Compute next PC
            next_expected_pc = expected_pc;

            if (!txn.stall) begin
                case(txn.pc_src)
                    2'd0: next_expected_pc = expected_pc + 4;
                    2'd1: next_expected_pc = txn.pred_pc_target;
                    2'd2: next_expected_pc = txn.pc_plus4_ex;
                    2'd3: next_expected_pc = txn.pc_target_ex;
                endcase
            end

            // Compare current DUT output with previous expected
            if (expected_pc !== dut_pc)
                $display("[CYCLE %0d] SB  TXN[%0d]: Mismatch! Model=%h DUT=%h \n",
                         vif.cycle, txn.id, expected_pc, dut_pc);
            else
                $display("[CYCLE %0d] SB  TXN[%0d]: PASS: PC=%h \n",
                         vif.cycle, txn.id, dut_pc);

            expected_pc = next_expected_pc;
        end
    endtask

endclass
