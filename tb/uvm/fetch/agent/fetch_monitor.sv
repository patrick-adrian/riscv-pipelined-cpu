class fetch_monitor extends uvm_monitor;

    virtual fetch_if                       vif;
    uvm_analysis_port #(fetch_obs_txn)    ap;
    int unsigned                          cycle_count;

    `uvm_component_utils(fetch_monitor)

    function new(string name = "fetch_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
        cycle_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fetch_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("FETCH/MON/VIF", "virtual interface must be set for fetch_monitor")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fetch_obs_txn obs;

        super.run_phase(phase);

        forever begin
            @(vif.mon_cb);
            cycle_count++;

            // Emit one raw observation every sampled clock edge.
            obs = fetch_obs_txn::type_id::create($sformatf("obs_%0d", cycle_count));
            obs.cycle          = cycle_count;
            obs.reset          = vif.mon_cb.reset;
            obs.pc_src         = vif.mon_cb.pc_src;
            obs.stall          = vif.mon_cb.stall;
            obs.pc_target_ex   = vif.mon_cb.pc_target_ex;
            obs.pc_plus4_ex    = vif.mon_cb.pc_plus4_ex;
            obs.pred_pc_target = vif.mon_cb.pred_pc_target;
            obs.pc             = vif.mon_cb.pc;
            obs.pc_plus4       = vif.mon_cb.pc_plus4;

            ap.write(obs);
            `uvm_info("FETCH/MON", $sformatf("raw sample %s", obs.convert2string()), UVM_HIGH)
        end
    endtask

endclass
