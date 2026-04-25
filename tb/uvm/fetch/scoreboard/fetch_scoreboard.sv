class fetch_scoreboard extends uvm_component;

    uvm_analysis_imp #(fetch_obs_txn, fetch_scoreboard) analysis_export;

    logic [31:0] model_pc;
    logic        reset_d;
    logic        stall_d;
    logic [1:0]  pc_src_d;
    logic [31:0] ex_pc_target_d;
    logic [31:0] ex_pc_plus4_d;
    logic [31:0] pred_pc_target_d;
    bit          model_valid;

    int num_checked;
    int num_active_checked;
    int mismatch_count;

    `uvm_component_utils(fetch_scoreboard)

    function new(string name = "fetch_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export    = new("analysis_export", this);
        model_pc           = 32'h0;
        reset_d            = 1'b0;
        stall_d            = 1'b0;
        pc_src_d           = 2'b00;
        ex_pc_target_d     = 32'h0;
        ex_pc_plus4_d      = 32'h0;
        pred_pc_target_d   = 32'h0;
        model_valid        = 1'b0;
        num_checked        = 0;
        num_active_checked = 0;
        mismatch_count     = 0;
    endfunction

    function void write(fetch_obs_txn obs);
        fetch_obs_txn expected_txn;

        expected_txn = build_expected_txn(obs);

        if (model_valid) begin
            num_checked++;
            if (!obs.reset) begin
                num_active_checked++;
            end

            if (!compare_pc_fields(expected_txn, obs)) begin
                mismatch_count++;
            end
        end else begin
            `uvm_info("FETCH/SB",
                      $sformatf("Warm-up sample cycle=%0d raw_obs={%s}", obs.cycle,
                                obs.convert2string()),
                      UVM_HIGH)
        end

        advance_model_state(obs);
        model_valid = 1'b1;
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        if (num_checked == 0) begin
            mismatch_count++;
            `uvm_error("FETCH/SB", "No fetch observations were checked")
        end

        if (num_active_checked == 0) begin
            mismatch_count++;
            `uvm_error("FETCH/SB", "No post-reset fetch cycles were checked")
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
                      (num_active_checked > 0) &&
                      (error_count == 0) &&
                      (fatal_count == 0);

        `uvm_info("FETCH/SB",
                  $sformatf("Summary: checks=%0d active=%0d mismatches=%0d final_model_pc=%08h delayed_state={reset=%0b stall=%0b pc_src=%0d ex_pc_target=%08h ex_pc_plus4=%08h pred_pc_target=%08h} result=%s",
                            num_checked, num_active_checked, mismatch_count, model_pc,
                            reset_d, stall_d, pc_src_d, ex_pc_target_d,
                            ex_pc_plus4_d, pred_pc_target_d, pass ? "PASS" : "FAIL"),
                  UVM_NONE)

        if (pass) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAIL");
        end
    endfunction

    protected function fetch_obs_txn build_expected_txn(fetch_obs_txn obs);
        fetch_obs_txn expected_txn;

        expected_txn = fetch_obs_txn::type_id::create("expected_txn");
        expected_txn.cycle          = obs.cycle;
        expected_txn.reset          = obs.reset;
        expected_txn.pc_src         = pc_src_d;
        expected_txn.stall          = stall_d;
        expected_txn.pc_target_ex   = ex_pc_target_d;
        expected_txn.pc_plus4_ex    = ex_pc_plus4_d;
        expected_txn.pred_pc_target = pred_pc_target_d;
        expected_txn.pc             = model_pc;
        expected_txn.pc_plus4       = model_pc + 32'd4;

        return expected_txn;
    endfunction

    protected function logic [31:0] compute_next_model_pc(fetch_obs_txn obs);
        logic [31:0] next_pc;

        next_pc = model_pc;

        if (obs.reset) begin
            next_pc = 32'h0;
        end else if (!obs.stall) begin
            case (obs.pc_src)
                2'd0: next_pc = model_pc + 32'd4;
                2'd1: next_pc = obs.pred_pc_target;
                2'd2: next_pc = obs.pc_plus4_ex;
                2'd3: next_pc = obs.pc_target_ex;
                default: next_pc = model_pc;
            endcase
        end

        return next_pc;
    endfunction

    protected function bit compare_pc_fields(fetch_obs_txn expected_txn,
                                             fetch_obs_txn actual_txn);
        bit match;

        match = (expected_txn.pc === actual_txn.pc) &&
                (expected_txn.pc_plus4 === actual_txn.pc_plus4);

        if (!match) begin
            `uvm_error("FETCH/SB",
                       $sformatf("Cycle %0d mismatch delayed_state={model_pc=%08h reset=%0b stall=%0b pc_src=%0d ex_pc_target=%08h ex_pc_plus4=%08h pred_pc_target=%08h} exp={pc=%08h pc_plus4=%08h} act={pc=%08h pc_plus4=%08h} raw_obs={%s}",
                                 actual_txn.cycle, model_pc, reset_d, stall_d, pc_src_d,
                                 ex_pc_target_d, ex_pc_plus4_d, pred_pc_target_d,
                                 expected_txn.pc, expected_txn.pc_plus4,
                                 actual_txn.pc, actual_txn.pc_plus4,
                                 actual_txn.convert2string()))
        end else begin
            `uvm_info("FETCH/SB",
                      $sformatf("Cycle %0d matched delayed_state={model_pc=%08h reset=%0b stall=%0b pc_src=%0d} exp_pc=%08h exp_pc_plus4=%08h",
                                actual_txn.cycle, model_pc, reset_d, stall_d,
                                pc_src_d, expected_txn.pc, expected_txn.pc_plus4),
                      UVM_HIGH)
        end

        return match;
    endfunction

    protected function void advance_model_state(fetch_obs_txn obs);
        model_pc         = compute_next_model_pc(obs);
        reset_d          = obs.reset;
        stall_d          = obs.stall;
        pc_src_d         = obs.pc_src;
        ex_pc_target_d   = obs.pc_target_ex;
        ex_pc_plus4_d    = obs.pc_plus4_ex;
        pred_pc_target_d = obs.pred_pc_target;
    endfunction

endclass
