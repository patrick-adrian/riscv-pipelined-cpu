class fetch_monitor;

    virtual fetch_if vif;
    mailbox #(fetch_obs) mbx;
    int                  num_sampled = 0;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_obs) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            fetch_obs obs = new();

            // Use the clocking block event as the cycle boundary, then sample
            // the raw interface after the DUT's posedge updates settle.
            @(vif.cb);
            #1ps;

            obs.cycle          = vif.cycle;
            obs.reset          = vif.reset;
            obs.pc_src         = vif.pc_src;
            obs.stall          = vif.stall;
            obs.pc_target_ex   = vif.pc_target_ex;
            obs.pc_plus4_ex    = vif.pc_plus4_ex;
            obs.pred_pc_target = vif.pred_pc_target;
            obs.pc             = vif.pc;
            obs.pc_plus4       = vif.pc_plus4;

            mbx.put(obs);
            num_sampled++;
        end
    endtask

endclass

