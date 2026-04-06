class decode_slice_txn;

    logic [31:0] instr;
    logic [31:0] pc;
    logic        stall;
    logic        flush;

    function void display(int cycle, time log_time);
        $display("[TIME %0t][CYCLE %0d] DRV: stall=%0b flush=%0b instr=%h pc=%h",
                 log_time, cycle, stall, flush, instr, pc);
    endfunction

endclass


class decode_slice_driver;

    virtual decode_slice_if vif;
    mailbox #(decode_slice_txn) mbx;
    int num_sent = 0;

    function new(virtual decode_slice_if vif, mailbox #(decode_slice_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        decode_slice_txn txn;
        bit    have_txn;
        int    cycle_count = 0;
        time   log_time;

        forever begin
            @(posedge vif.clk);
            cycle_count++;

            have_txn = mbx.try_get(txn);
            if (!have_txn) begin
                vif.tb_valid           <= 1'b0;
                vif.stall              <= 1'b1;
                vif.flush              <= 1'b0;
                vif.instr_fi           <= 32'h0;
                vif.pc_fi              <= 32'h0;
                vif.pc_plus4_fi        <= 32'h4;
                vif.pred_pc_target_fi  <= 32'h0;
                vif.pc_src_pred_fi     <= 1'b0;
                continue;
            end

            vif.tb_valid           <= 1'b1;
            vif.stall              <= txn.stall;
            vif.flush              <= txn.flush;
            vif.instr_fi           <= txn.instr;
            vif.pc_fi              <= txn.pc;
            vif.pc_plus4_fi        <= txn.pc + 32'd4;
            vif.pred_pc_target_fi  <= 32'h0;
            vif.pc_src_pred_fi     <= 1'b0;

            log_time = $time;
            #2ps;
            txn.display(cycle_count, log_time);
            num_sent++;
        end
    endtask

endclass
