class fetch_stall_seq extends fetch_base_seq;

    `uvm_object_utils(fetch_stall_seq)

    function new(string name = "fetch_stall_seq");
        super.new(name);
    endfunction

    task body();
        fetch_txn t;

        t = fetch_txn::type_id::create("txn0");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn1");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b1;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn2");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0008;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn3");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b1;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn4");
        start_item(t);
        t.pc_src         = 2'd1;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0000;
        t.pred_pc_target = 32'h0000_0020;
        finish_item(t);

        t = fetch_txn::type_id::create("txn5");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b1;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn6");
        start_item(t);
        t.pc_src         = 2'd2;
        t.stall          = 1'b0;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0024;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn7");
        start_item(t);
        t.pc_src         = 2'd0;
        t.stall          = 1'b1;
        t.pc_target_ex   = 32'h0000_0000;
        t.pc_plus4_ex    = 32'h0000_0004;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);

        t = fetch_txn::type_id::create("txn8");
        start_item(t);
        t.pc_src         = 2'd3;
        t.stall          = 1'b1;
        t.pc_target_ex   = 32'h0000_0040;
        t.pc_plus4_ex    = 32'h0000_0000;
        t.pred_pc_target = 32'h0000_0000;
        finish_item(t);
    endtask

endclass
