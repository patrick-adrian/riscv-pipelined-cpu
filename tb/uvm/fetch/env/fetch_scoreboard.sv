class fetch_scoreboard extends uvm_component;

    uvm_analysis_imp #(fetch_obs_txn, fetch_scoreboard) analysis_export;

    logic [31:0] expected_pc;
    logic [31:0] next_expected_pc;
    logic [31:0] expected_pc_plus4;

    int num_checked;
    int num_driven_checked;
    int num_active_driven_checked;
    int mismatch_count;

    protected bit           have_prev_obs;
    protected fetch_obs_txn prev_obs;

    `uvm_component_utils(fetch_scoreboard)

    function new(string name = "fetch_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export    = new("analysis_export", this);
        expected_pc        = 32'h0;
        next_expected_pc   = 32'h0;
        expected_pc_plus4  = 32'h4;
        num_checked        = 0;
        num_driven_checked = 0;
        num_active_driven_checked = 0;
        mismatch_count     = 0;
        have_prev_obs      = 1'b0;
    endfunction

    function void write(fetch_obs_txn obs);
        bit   pc_mismatch;
        bit   pc_plus4_mismatch;
        string check_kind;

        if (!have_prev_obs) begin
            save_prev_obs(obs);
            return;
        end

        next_expected_pc = expected_pc;
        check_kind = prev_obs.tb_valid ? "DRIVEN" : "IDLE";

        if (prev_obs.reset) begin
            next_expected_pc = 32'h0;
        end else if (!prev_obs.stall) begin
            case (prev_obs.pc_src)
                2'd0: next_expected_pc = expected_pc + 32'd4;
                2'd1: next_expected_pc = prev_obs.pred_pc_target;
                2'd2: next_expected_pc = prev_obs.pc_plus4_ex;
                2'd3: next_expected_pc = prev_obs.pc_target_ex;
                default: next_expected_pc = expected_pc;
            endcase
        end

        expected_pc_plus4 = next_expected_pc + 32'd4;
        pc_mismatch       = (next_expected_pc !== obs.pc);
        pc_plus4_mismatch = (expected_pc_plus4 !== obs.pc_plus4);

        if (pc_mismatch || pc_plus4_mismatch) begin
            mismatch_count++;
            `uvm_error("FETCH/SB",
                       $sformatf("%s mismatch at cycle %0d exp_pc=%08h dut_pc=%08h exp_pc_plus4=%08h dut_pc_plus4=%08h prev_ctrl={%s} curr_obs={%s}",
                                 check_kind, obs.cycle, next_expected_pc, obs.pc,
                                 expected_pc_plus4, obs.pc_plus4,
                                 prev_obs.convert2string(), obs.convert2string()))
        end else begin
            `uvm_info("FETCH/SB",
                      $sformatf("%s PASS cycle=%0d pc=%08h pc_plus4=%08h",
                                check_kind, obs.cycle, obs.pc, obs.pc_plus4),
                      UVM_MEDIUM)
        end

        num_checked++;
        if (prev_obs.tb_valid) begin
            num_driven_checked++;
            if (!prev_obs.reset) begin
                num_active_driven_checked++;
            end
        end

        expected_pc = next_expected_pc;
        save_prev_obs(obs);
    endfunction

    function void final_phase(uvm_phase phase);
        uvm_report_server server;
        int error_count;
        int fatal_count;
        bit pass;

        super.final_phase(phase);

        server      = uvm_report_server::get_server();
        error_count = server.get_severity_count(UVM_ERROR);
        fatal_count = server.get_severity_count(UVM_FATAL);
        pass        = (mismatch_count == 0) &&
                      (num_driven_checked > 0) &&
                      (num_active_driven_checked > 0) &&
                      (error_count == 0) &&
                      (fatal_count == 0);

        $display("Total checks: %0d", num_checked);
        $display("Driven checks: %0d", num_driven_checked);
        $display("Active driven checks: %0d", num_active_driven_checked);
        $display("Mismatches: %0d", mismatch_count);

        if (pass) begin
            $display("TEST PASSED");
        end else begin
            if (num_driven_checked == 0) begin
                `uvm_error("FETCH/SB", "No driven transactions reached the scoreboard")
            end else if (num_active_driven_checked == 0) begin
                `uvm_error("FETCH/SB", "No driven transactions were checked while reset was deasserted")
            end
            $display("TEST FAIL");
        end
    endfunction

    protected function void save_prev_obs(fetch_obs_txn obs);
        if (prev_obs == null) begin
            prev_obs = fetch_obs_txn::type_id::create("prev_obs");
        end
        prev_obs.copy(obs);
        have_prev_obs = 1'b1;
    endfunction

endclass
