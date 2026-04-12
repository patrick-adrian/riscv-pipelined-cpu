class fetch_decode_flush_redirect_test extends fetch_decode_base_test;

    function new(virtual fetch_decode_control_if vif, fetch_decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        clear_program();
        load_program_word(0, encode_addi(5'd1, 5'd0, 12'd4));
        load_program_word(1, encode_add(5'd2, 5'd1, 5'd1));
        load_program_word(2, encode_beq(5'd1, 5'd2, 13'd8));
        load_program_word(3, encode_addi(5'd4, 5'd0, 12'd9));
        load_program_word(4, encode_nop());

        apply_reset(1);
        run_cycles(3);

        send_ctrl_txn("FLUSH_REDIRECT", `PC_SRC_TARGET_E, 1'b0, 1'b0, 1'b1, 32'd16, 32'd12, 32'h0, 1'b0);

        run_cycles(8);
        env.wait_until_checked(8);
        report_and_finish();
    endtask

endclass
