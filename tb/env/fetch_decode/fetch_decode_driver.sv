`include "control_macros.sv"

class fetch_decode_driver;

    virtual fetch_decode_control_if vif;
    mailbox #(fetch_decode_txn)     mbx;
    int                             num_sent = 0;

    function new(virtual fetch_decode_control_if vif,
                 mailbox #(fetch_decode_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task automatic drive_defaults();
        vif.is_new_txn        = 1'b0;
        vif.pc_src            = `PC_SRC_SEQ_F;
        vif.stall_fi          = 1'b0;
        vif.stall_de          = 1'b0;
        vif.flush_de          = 1'b0;
        vif.pc_target_ex      = 32'h0;
        vif.pc_plus4_ex       = 32'h0;
        vif.pred_pc_target_fi = 32'h0;
        vif.pc_src_pred_fi    = 1'b0;
    endtask

    task run();
        fetch_decode_txn txn;
        bit              have_txn;
        int              cycle_count = 0;
        time             log_time;

        forever begin
            @(negedge vif.clk);
            cycle_count++;

            have_txn = mbx.try_get(txn);
            if (!have_txn) begin
                drive_defaults();
                continue;
            end

            vif.is_new_txn        = 1'b1;
            vif.pc_src            = txn.pc_src;
            vif.stall_fi          = txn.stall_fi;
            vif.stall_de          = txn.stall_de;
            vif.flush_de          = txn.flush_de;
            vif.pc_target_ex      = txn.pc_target_ex;
            vif.pc_plus4_ex       = txn.pc_plus4_ex;
            vif.pred_pc_target_fi = txn.pred_pc_target_fi;
            vif.pc_src_pred_fi    = txn.pc_src_pred_fi;

            log_time = $time;
            #2ps;
            txn.display(cycle_count, log_time);
            num_sent++;
        end
    endtask

endclass
