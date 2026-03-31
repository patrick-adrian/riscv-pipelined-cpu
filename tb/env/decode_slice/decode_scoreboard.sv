class ds_scoreboard;

    mailbox #(ds_txn) drv_mbx;
    mailbox #(ds_obs) mon_mbx;

    logic [31:0] exp_instr;
    logic        exp_valid;

    int num_checked  = 0;
    int mismatch_count = 0;

    function new(mailbox #(ds_txn) drv_mbx, mailbox #(ds_obs) mon_mbx);
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;
        exp_instr = '0;
        exp_valid = 1'b0;
    endfunction

    task run();
        ds_txn  txn;
        ds_obs  obs;

        logic [6:0]  exp_op;
        logic [2:0]  exp_imm_src;
        logic [31:0] exp_imm_ext;
        logic        imm_src_mm, imm_ext_mm, instr_mm, valid_mm;

        forever begin
            drv_mbx.get(txn);

            do begin
                mon_mbx.get(obs);
            end while (obs.txn_id != txn.id);

            // Update expected pipeline-register state.
            if (txn.reset || txn.flush) begin
                exp_instr = '0;
                exp_valid = 1'b0;
            end else if (!txn.stall) begin
                exp_instr = txn.instr;
                exp_valid = 1'b1;
            end

            if (!exp_valid) begin
                if (obs.valid !== 1'b0) begin
                    mismatch_count++;
                    $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: MISMATCH valid: exp=0 got=%0b",
                             $time, obs.cycle, txn.id, obs.valid);
                end else begin
                    $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: PASS (reset/flush)",
                             $time, obs.cycle, txn.id);
                end
            end else begin
                exp_op      = exp_instr[6:0];
                exp_imm_src = ds_ref_model::expected_imm_src(exp_op);
                exp_imm_ext = ds_ref_model::expected_imm_ext(exp_instr[31:7], exp_imm_src);

                imm_src_mm = (exp_imm_src !== obs.imm_src);
                imm_ext_mm = (exp_imm_ext !== obs.imm_ext_de);
                instr_mm   = (exp_instr   !== obs.instr_de);
                valid_mm   = (exp_valid   !== obs.valid);

                if (imm_src_mm || imm_ext_mm || instr_mm || valid_mm) begin
                    mismatch_count++;
                    $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: MISMATCH", $time, obs.cycle, txn.id);
                    $display("  instr:   exp=%h got=%h", exp_instr, obs.instr_de);
                    $display("  opcode:  exp=%07b got=%07b", exp_op, obs.op_de);
                    $display("  imm_src: exp=%03b got=%03b", exp_imm_src, obs.imm_src);
                    $display("  imm_ext: exp=%h got=%h", exp_imm_ext, obs.imm_ext_de);
                    $display("  valid:   exp=%0b got=%0b\n", exp_valid, obs.valid);
                end else begin
                    $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: PASS op=%07b imm_src=%03b imm=%h\n",
                             $time, obs.cycle, txn.id, obs.op_de, obs.imm_src, obs.imm_ext_de);
                end
            end

            num_checked++;
        end
    endtask

endclass
