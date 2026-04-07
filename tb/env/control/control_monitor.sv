class control_obs;

    int               cycle;
    bit               tb_valid;
    bit               reset;
    logic [31:0]      instr_de;
    control_signals_t ctrl;

endclass


// Fully passive: samples one observation per posedge after the clocked TB
// wrapper has updated its inputs for that cycle.
class control_monitor;

    virtual control_if vif;
    mailbox #(control_obs) mon_mbx;

    int num_sampled = 0;

    function new(virtual control_if vif, mailbox #(control_obs) mon_mbx);
        this.vif     = vif;
        this.mon_mbx = mon_mbx;
    endfunction

    task run();
        int cycle_count = 0;

        forever begin
            control_obs obs = new();

            @(posedge vif.clk);
            cycle_count++;
            #1ps;

            obs.cycle    = cycle_count;
            obs.tb_valid = vif.tb_valid;
            obs.reset    = vif.reset;
            obs.instr_de = vif.instr_de;
            obs.ctrl     = vif.sample_ctrl();

            mon_mbx.put(obs);
            if (obs.tb_valid)
                num_sampled++;
        end
    endtask

endclass
