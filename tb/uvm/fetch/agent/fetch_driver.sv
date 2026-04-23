class fetch_driver extends uvm_driver #(fetch_seq_item);

    virtual fetch_if  vif;

    `uvm_component_utils(fetch_driver)

    function new(string name = "fetch_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fetch_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("FETCH/DRV/VIF", "virtual interface must be set for fetch_driver")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fetch_seq_item req;

        super.run_phase(phase);

        forever begin
            seq_item_port.get_next_item(req);
            @(vif.drv_cb);
            drive_txn(req);
            `uvm_info("FETCH/DRV", $sformatf("drive %s", req.convert2string()), UVM_MEDIUM)
            seq_item_port.item_done();
        end
    endtask

    protected task drive_txn(fetch_seq_item req);
        vif.drv_cb.tb_valid        <= 1'b1;
        vif.drv_cb.pc_src          <= req.pc_src;
        vif.drv_cb.stall           <= req.stall;
        vif.drv_cb.pc_target_ex    <= req.pc_target_ex;
        vif.drv_cb.pc_plus4_ex     <= req.pc_plus4_ex;
        vif.drv_cb.pred_pc_target  <= req.pred_pc_target;
    endtask

endclass
