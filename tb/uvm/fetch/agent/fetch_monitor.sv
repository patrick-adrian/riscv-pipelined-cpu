class fetch_monitor extends uvm_monitor;

    virtual fetch_if vif;
    uvm_analysis_port #(fetch_sample) ap;

    `uvm_component_utils(fetch_monitor)

    function new(string name = "fetch_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fetch_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "No vif")
    endfunction

    task run_phase(uvm_phase phase);

        fetch_sample tr;

        forever begin
            @(vif.mon_cb);
            #0;

            tr = fetch_sample::type_id::create("tr");

            tr.pc              = vif.mon_cb.pc;
            tr.pc_plus4        = vif.mon_cb.pc_plus4;

            tr.pc_src          = vif.mon_cb.pc_src;
            tr.stall           = vif.mon_cb.stall;

            tr.pc_target_ex    = vif.mon_cb.pc_target_ex;
            tr.pc_plus4_ex     = vif.mon_cb.pc_plus4_ex;
            tr.pred_pc_target  = vif.mon_cb.pred_pc_target;

            tr.reset           = vif.mon_cb.reset;

            ap.write(tr);
        end

    endtask

endclass