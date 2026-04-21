class fetch_scoreboard extends uvm_component;

    uvm_analysis_imp #(fetch_obs_txn, fetch_scoreboard) analysis_export;

    fetch_obs_txn expected_q[$];
    fetch_obs_txn actual_q[$];

    logic [31:0] expected_pc;

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
        num_checked        = 0;
        num_driven_checked = 0;
        num_active_driven_checked = 0;
        mismatch_count     = 0;
        have_prev_obs      = 1'b0;
    endfunction

    function void write(fetch_obs_txn obs);
        fetch_obs_txn expected_txn;
        fetch_obs_txn actual_txn;

        if (!have_prev_obs) begin
            save_prev_obs(obs);
            return;
        end

        expected_txn = build_expected_txn(obs);
        actual_txn   = clone_txn("actual_txn", obs);

        write_expected(expected_txn);
        write_actual(actual_txn);

        num_checked++;
        if (prev_obs.tb_valid) begin
            num_driven_checked++;
            if (!prev_obs.reset) begin
                num_active_driven_checked++;
            end
        end

        expected_pc = expected_txn.pc;
        save_prev_obs(obs);
    endfunction

    function void write_expected(fetch_obs_txn txn);
        expected_q.push_back(txn);
    endfunction

    function void write_actual(fetch_obs_txn txn);
        actual_q.push_back(txn);
    endfunction

    function void check_phase(uvm_phase phase);
        int compare_count;
        int i;

        super.check_phase(phase);

        if (expected_q.size() != actual_q.size()) begin
            mismatch_count++;
            `uvm_error("FETCH/SB",
                       $sformatf("Transaction count mismatch exp=%0d act=%0d",
                                 expected_q.size(), actual_q.size()))
        end

        compare_count = (expected_q.size() < actual_q.size()) ? expected_q.size() : actual_q.size();
        for (i = 0; i < compare_count; i++) begin
            if (!expected_q[i].compare(actual_q[i])) begin
                mismatch_count++;
                `uvm_error("FETCH/SB",
                           $sformatf("Mismatch at index %0d prev_ctrl={%s} exp={%s} act={%s}",
                                     i, (i == 0) ? "initial sample skipped" : actual_q[i-1].convert2string(),
                                     expected_q[i].convert2string(), actual_q[i].convert2string()))
            end
        end

        if (num_driven_checked == 0) begin
            `uvm_error("FETCH/SB", "No driven transactions reached the scoreboard")
        end else if (num_active_driven_checked == 0) begin
            `uvm_error("FETCH/SB", "No driven transactions were checked while reset was deasserted")
        end
    endfunction

    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        int error_count;
        int fatal_count;
        bit pass;

        super.report_phase(phase);

        server      = uvm_report_server::get_server();
        error_count = server.get_severity_count(UVM_ERROR);
        fatal_count = server.get_severity_count(UVM_FATAL);
        pass        = (mismatch_count == 0) &&
                      (num_driven_checked > 0) &&
                      (num_active_driven_checked > 0) &&
                      (error_count == 0) &&
                      (fatal_count == 0);

        `uvm_info("FETCH/SB",
                  $sformatf("Summary: expected=%0d actual=%0d checks=%0d driven=%0d active_driven=%0d mismatches=%0d result=%s",
                            expected_q.size(), actual_q.size(), num_checked,
                            num_driven_checked, num_active_driven_checked,
                            mismatch_count, pass ? "PASS" : "FAIL"),
                  UVM_NONE)

        if (pass) begin
            $display("TEST PASSED");
        end else begin
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

    protected function fetch_obs_txn clone_txn(string name, fetch_obs_txn obs);
        fetch_obs_txn txn_copy;

        txn_copy = fetch_obs_txn::type_id::create(name);
        txn_copy.copy(obs);
        return txn_copy;
    endfunction

    protected function fetch_obs_txn build_expected_txn(fetch_obs_txn obs);
        fetch_obs_txn expected_txn;
        logic [31:0] next_expected_pc;
        logic [31:0] expected_pc_plus4;

        expected_txn = clone_txn("expected_txn", obs);
        next_expected_pc = expected_pc;

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

        expected_pc_plus4    = next_expected_pc + 32'd4;
        expected_txn.pc      = next_expected_pc;
        expected_txn.pc_plus4 = expected_pc_plus4;

        return expected_txn;
    endfunction

endclass
