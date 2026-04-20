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
            @(posedge vif.clk);
            cycle_count++;
            #1ps;

            obs = fetch_obs_txn::type_id::create($sformatf("obs_%0d", cycle_count));
            obs.cycle          = cycle_count;
            obs.reset          = vif.reset;
            obs.tb_valid       = vif.tb_valid;
            obs.pc_src         = vif.pc_src;
            obs.stall          = vif.stall;
            obs.pc_target_ex   = vif.pc_target_ex;
            obs.pc_plus4_ex    = vif.pc_plus4_ex;
            obs.pred_pc_target = vif.pred_pc_target;
            obs.pc             = vif.pc;
            obs.pc_plus4       = vif.pc_plus4;

            ap.write(obs);
            `uvm_info("FETCH/MON", $sformatf("sample %s", obs.convert2string()), UVM_HIGH)
        end
    endtask

endclass
