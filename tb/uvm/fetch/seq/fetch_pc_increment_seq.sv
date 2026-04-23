class fetch_pc_increment_seq extends fetch_base_seq;

    int num_txns;

    `uvm_object_utils(fetch_pc_increment_seq)

    function new(string name = "fetch_pc_increment_seq");
        super.new(name);
        num_txns = 16;
    endfunction

    task body();
        fetch_seq_item t;

        for (int i = 0; i < num_txns; i++) begin
            t = fetch_seq_item::type_id::create($sformatf("txn%0d", i));
            start_item(t);
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'd4 * (i + 1);
            t.pred_pc_target = 32'h0000_0000;
            finish_item(t);
        end
    endtask

endclass
