class control_obs;

    int               cycle;
    bit               valid;
    bit               reset;
    logic [31:0]      instr;
    control_signals_t ctrl;

endclass


// Fully passive: emits one observation per cycle, before the driver updates the
// next cycle's inputs. That enforces a deterministic one-cycle delay between
// drive and check without modifying the combinational DUT.
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

            obs.cycle = cycle_count;
            cycle_count++;
            obs.valid = vif.valid;
            obs.reset = vif.reset;
            obs.instr = vif.instr;
            obs.ctrl  = vif.sample_ctrl();

            mon_mbx.put(obs);
            num_sampled++;
        end
    endtask

endclass
