class fetch_scoreboard;

    mailbox #(fetch_txn) drv_mbx;
    mailbox #(logic [31:0]) mon_mbx;

    logic [31:0] model_pc;

    function new(mailbox #(fetch_txn) drv_mbx,
                 mailbox #(logic [31:0]) mon_mbx);
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;
        model_pc = 0;
    endfunction

    task run();
        fetch_txn txn;
        logic [31:0] dut_pc;

        forever begin
            drv_mbx.get(txn);
            mon_mbx.get(dut_pc);

            // Model behavior
            if (!txn.stall) begin
                case(txn.pc_src)
                    2'd0: model_pc = model_pc + 4;
                    2'd1: model_pc = txn.pred_pc_target;
                    2'd2: model_pc = txn.pc_plus4_ex;
                    2'd3: model_pc = txn.pc_target_ex;
                endcase
            end

            if (model_pc !== dut_pc) begin
                $error("Mismatch! Model=%h DUT=%h",
                        model_pc, dut_pc);
            end
            else begin
                $display("PASS: PC=%h", dut_pc);
            end
        end
    endtask

endclass