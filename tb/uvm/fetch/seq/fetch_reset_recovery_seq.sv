class fetch_reset_recovery_seq extends fetch_base_seq;

    `uvm_object_utils(fetch_reset_recovery_seq)

    function new(string name = "fetch_reset_recovery_seq");
        super.new(name);
    endfunction

    task body();
        fetch_seq_item t;

        t = fetch_seq_item::type_id::create("txn0");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0000;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_seq_item::type_id::create("txn1");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_seq_item::type_id::create("txn2");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0008;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_seq_item::type_id::create("txn3");
        start_item(t);
        t.pc_src         = 2'd1;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0000;
        t.pred_pc_target = 32'h0000_0020;
        finish_item(t);
    endtask

endclass
