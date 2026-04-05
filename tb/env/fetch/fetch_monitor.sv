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
        bit         have_prev = 1'b0;
        int         cycle_count = 0;
        logic       prev_reset;
        logic       prev_tb_valid;
        logic [1:0] prev_pc_src;
        logic       prev_stall;
        logic [31:0] prev_pc_target_ex;
        logic [31:0] prev_pc_plus4_ex;
        logic [31:0] prev_pred_pc_target;

        forever begin
            @(posedge vif.clk);
            #1ps;

            if (have_prev) begin
                fetch_obs obs = new();

                obs.cycle          = cycle_count;
                obs.reset          = prev_reset;
                obs.tb_valid       = prev_tb_valid;
                obs.pc_src         = prev_pc_src;
                obs.stall          = prev_stall;
                obs.pc_target_ex   = prev_pc_target_ex;
                obs.pc_plus4_ex    = prev_pc_plus4_ex;
                obs.pred_pc_target = prev_pred_pc_target;
                obs.pc             = vif.pc;
                obs.pc_plus4       = vif.pc_plus4;

                mbx.put(obs);
                num_sampled++;
                cycle_count++;
            end

            prev_reset          = vif.reset;
            prev_tb_valid       = vif.tb_valid;
            prev_pc_src         = vif.pc_src;
            prev_stall          = vif.stall;
            prev_pc_target_ex   = vif.pc_target_ex;
            prev_pc_plus4_ex    = vif.pc_plus4_ex;
            prev_pred_pc_target = vif.pred_pc_target;
            have_prev           = 1'b1;
        end
    endtask

endclass

