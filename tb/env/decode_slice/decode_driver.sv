class ds_txn;

    int          id;
    logic [31:0] instr;
    logic [31:0] pc;
    logic        reset;
    logic        stall;
    logic        flush;

    function void display(int cycle);
        $display("[TIME %0t][CYCLE %0d] DRV TXN[%0d]: reset=%0b stall=%0b flush=%0b instr=%h pc=%h",
                 $time, cycle, id, reset, stall, flush, instr, pc);
    endfunction

endclass


class ds_driver;

    virtual ds_if vif;
    mailbox #(ds_txn) mbx;
    int num_sent = 0;

    function new(virtual ds_if vif, mailbox #(ds_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        ds_txn txn;

        forever begin
            mbx.get(txn);

            @(negedge vif.clk);

            vif.reset            <= txn.reset;
            vif.stall            <= txn.stall;
            vif.flush            <= txn.flush;
            vif.instr_fi         <= txn.instr;
            vif.pc_fi            <= txn.pc;
            vif.pc_plus4_fi      <= txn.pc + 32'd4;
            vif.pred_pc_target_fi <= 32'h0;
            vif.pc_src_pred_fi   <= 1'b0;
            vif.txn_id           <= txn.id;

            txn.display(vif.cycle);
            num_sent++;
        end
    endtask

endclass
