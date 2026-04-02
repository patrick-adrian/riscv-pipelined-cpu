class decode_driver;

    virtual decode_if vif;
    mailbox #(decode_txn) mbx;
    int num_sent = 0;

    function new(virtual decode_if vif,
                mailbox #(decode_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        decode_txn txn;

        forever begin
            mbx.get(txn);

            // Drive on the negedge so inputs are stable for the DUT posedge.
            @(negedge vif.clk);

            vif.reset              <= txn.reset;
            vif.pc_src_pred_fi     <= txn.pc_src_pred_fi;
            vif.stall              <= txn.stall;
            vif.flush              <= txn.flush;

            vif.instr_fi_i         <= txn.instr_fi_i;
            vif.pc_fi_i            <= txn.pc_fi_i;
            vif.pc_plus4_fi_i     <= txn.pc_plus4_fi_i;
            vif.pred_pc_target_fi <= txn.pred_pc_target_fi;
            vif.imm_src_de_i      <= txn.imm_src_de_i;

            vif.txn_tag            <= txn.id;

            txn.display(vif.cycle);
            num_sent++;
        end
    endtask

endclass

