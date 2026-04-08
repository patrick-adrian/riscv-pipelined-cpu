class decode_slice_reset_recovery_test extends decode_slice_base_test;

    function new(virtual decode_slice_if vif, decode_slice_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset(2);

        // Establish a non-zero decode state before asserting reset again.
        send_txn(1'b0, 1'b0, 32'h02A00093, 32'h0000_0000); // ADDI x1, x0, 42
        env.wait_until_checked(1);

        assert_reset();

        // Reset must dominate even while the driver continues to send traffic.
        send_txn(1'b0, 1'b0, 32'h0080A103, 32'h0000_0004); // ignored by reset
        send_txn(1'b1, 1'b0, 32'h0020A823, 32'h0000_0008); // ignored by reset

        deassert_reset();

        // After reset deasserts, the stage should accept new traffic normally.
        send_txn(1'b0, 1'b0, 32'h00208463, 32'h0000_000C); // BEQ x1, x2, 8
        send_txn(1'b0, 1'b0, 32'hDEADB1B7, 32'h0000_0010); // LUI x3, 0xDEADB

        report_and_finish();
    endtask

endclass
