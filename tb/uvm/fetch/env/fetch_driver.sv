class fetch_driver extends uvm_driver #(fetch_txn);

    virtual fetch_if  vif;
    fetch_sequencer   sequencer_h;

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
        super.run_phase(phase);

        if (sequencer_h == null) begin
            `uvm_fatal("FETCH/DRV/SEQ", "fetch_driver requires a connected fetch_sequencer handle")
        end

        fork
            drive_reset();
            drive_transactions();
        join
    endtask

    protected task drive_reset();
        forever begin
            @(negedge vif.clk);
            vif.reset <= sequencer_h.get_reset_asserted();
        end
    endtask

    protected task drive_transactions();
        fetch_txn req;

        forever begin
            @(vif.drv_cb);

            req = null;
            seq_item_port.try_next_item(req);

            if (req == null) begin
                drive_idle();
                continue;
            end

            drive_txn(req);
            `uvm_info("FETCH/DRV",
                      $sformatf("drive %s reset=%0b", req.convert2string(),
                                sequencer_h.get_reset_asserted()),
                      UVM_MEDIUM)
            seq_item_port.item_done();
        end
    endtask

    protected task drive_idle();
        vif.drv_cb.tb_valid        <= 1'b0;
        vif.drv_cb.pc_src          <= 2'd0;
        vif.drv_cb.stall           <= 1'b1;
        vif.drv_cb.pc_target_ex    <= 32'h0;
        vif.drv_cb.pc_plus4_ex     <= 32'h0;
        vif.drv_cb.pred_pc_target  <= 32'h0;
    endtask

    protected task drive_txn(fetch_txn req);
        vif.drv_cb.tb_valid        <= 1'b1;
        vif.drv_cb.pc_src          <= req.pc_src;
        vif.drv_cb.stall           <= req.stall;
        vif.drv_cb.pc_target_ex    <= req.pc_target_ex;
        vif.drv_cb.pc_plus4_ex     <= req.pc_plus4_ex;
        vif.drv_cb.pred_pc_target  <= req.pred_pc_target;
    endtask

endclass
