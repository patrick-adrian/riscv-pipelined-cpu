class fetch_decode_imem_smoke_test extends fetch_decode_base_test;

    function new(virtual fetch_decode_control_if vif, fetch_decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        logic [31:0] instr0;
        logic [31:0] instr1;
        logic [31:0] instr2;

        instr0 = encode_addi(5'd1, 5'd0, 12'd4);
        instr1 = encode_add(5'd2, 5'd1, 5'd1);
        instr2 = encode_nop();

        clear_program();
        load_program_word(0, instr0);
        load_program_word(1, instr1);
        load_program_word(2, instr2);

        if (vif.program_word_at_pc(32'h0) !== instr0)
            $fatal(1, "IMEM smoke: PC 0 did not map to word 0");
        if (vif.program_word_at_pc(32'h4) !== instr1)
            $fatal(1, "IMEM smoke: PC 4 did not map to word 1");
        if (vif.program_word_at_pc(32'h8) !== instr2)
            $fatal(1, "IMEM smoke: PC 8 did not map to word 2");

        apply_reset(1);
        run_cycles(4);
        env.wait_until_checked(4);

        if (vif.program_word_at_pc(vif.pc_f) !== vif.instr_f)
            $fatal(1, "IMEM smoke: fetched instruction %08h did not match PC %08h mapping", vif.instr_f, vif.pc_f);

        report_and_finish();
    endtask

endclass
