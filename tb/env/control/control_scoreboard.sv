class control_scoreboard;

    mailbox #(control_txn) drv_mbx;
    mailbox #(control_obs) mon_mbx;

    int num_checked = 0;
    int mismatch_count = 0;
    bit prev_reset = 1'b0;

    function new(mailbox #(control_txn) drv_mbx, mailbox #(control_obs) mon_mbx);
        this.drv_mbx = drv_mbx;
        this.mon_mbx = mon_mbx;
    endfunction

    task run();
        control_txn txn;
        control_obs obs;
        control_ref_model::control_exp_t exp;
        string decoded_type;
        bit mm;
        logic [22:0] flat_outputs;

        forever begin
            drv_mbx.get(txn);

            do begin
                mon_mbx.get(obs);
            end while (obs.txn_id != txn.id);

            if (txn.reset || obs.reset) begin
                num_checked++;
                prev_reset = 1'b1;
                continue;
            end

            flat_outputs = {
                obs.imm_src, obs.result_src, obs.branch_op, obs.alu_src,
                obs.pc_base_src, obs.reg_write, obs.mem_write, obs.csr_we,
                obs.alu_control, obs.width_src, obs.csr_control, obs.csr_src
            };

            if (prev_reset && $isunknown(flat_outputs)) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: MISMATCH post-reset outputs contain X/Z",
                         $time, obs.cycle, txn.id);
            end
            prev_reset = 1'b0;

            exp = control_ref_model::decode_expected(txn.opcode, txn.funct3, txn.funct7);
            decoded_type = control_ref_model::instruction_type(txn.opcode, txn.funct3, txn.funct7);

            mm = 1'b0;
            mm |= (obs.imm_src     !== exp.imm_src);
            mm |= (obs.result_src  !== exp.result_src);
            mm |= (obs.branch_op   !== exp.branch_op);
            mm |= (obs.alu_src     !== exp.alu_src);
            mm |= (obs.pc_base_src !== exp.pc_base_src);
            mm |= (obs.reg_write   !== exp.reg_write);
            mm |= (obs.mem_write   !== exp.mem_write);
            mm |= (obs.csr_we      !== exp.csr_we);
            mm |= (obs.alu_control !== exp.alu_control);
            mm |= (obs.width_src   !== exp.width_src);
            mm |= (obs.csr_control !== exp.csr_control);
            mm |= (obs.csr_src     !== exp.csr_src);

            if (mm) begin
                mismatch_count++;
                $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: MISMATCH (%0s)",
                         $time, obs.cycle, txn.id, decoded_type);
                $display("  fields: op=%07b f3=%03b f7=%07b", txn.opcode, txn.funct3, txn.funct7);
                $display("  imm_src:     exp=%03b got=%03b", exp.imm_src, obs.imm_src);
                $display("  result_src:  exp=%03b got=%03b", exp.result_src, obs.result_src);
                $display("  branch_op:   exp=%02b got=%02b", exp.branch_op, obs.branch_op);
                $display("  alu_src:     exp=%0b got=%0b",  exp.alu_src, obs.alu_src);
                $display("  pc_base_src: exp=%0b got=%0b",  exp.pc_base_src, obs.pc_base_src);
                $display("  reg_write:   exp=%0b got=%0b",  exp.reg_write, obs.reg_write);
                $display("  mem_write:   exp=%0b got=%0b",  exp.mem_write, obs.mem_write);
                $display("  csr_we:      exp=%0b got=%0b",  exp.csr_we, obs.csr_we);
                $display("  alu_control: exp=%04b got=%04b", exp.alu_control, obs.alu_control);
                $display("  width_src:   exp=%03b got=%03b", exp.width_src, obs.width_src);
                $display("  csr_control: exp=%02b got=%02b", exp.csr_control, obs.csr_control);
                $display("  csr_src:     exp=%0b got=%0b\n", exp.csr_src, obs.csr_src);
            end else begin
                $display("[TIME %0t][CYCLE %0d] SB TXN[%0d]: PASS (%0s)\n",
                         $time, obs.cycle, txn.id, decoded_type);
            end

            num_checked++;
        end
    endtask

endclass
