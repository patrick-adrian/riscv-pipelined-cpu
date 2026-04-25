class fetch_scoreboard extends uvm_scoreboard;

    // ---------------------------------------
    // UVM plumbing
    // ---------------------------------------
    uvm_analysis_export #(fetch_sample) analysis_export;
    uvm_tlm_analysis_fifo #(fetch_sample) fifo;

    `uvm_component_utils(fetch_scoreboard)

    // ---------------------------------------
    // Reference model state
    // ---------------------------------------
    logic [31:0] exp_pc;
    bit reset_seen;

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    function new(string name = "fetch_scoreboard", uvm_component parent = null);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
        fifo            = new("fifo", this);

        exp_pc          = 32'h0;
        reset_seen      = 0;
    endfunction

    // ---------------------------------------
    // Connect FIFO
    // ---------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        analysis_export.connect(fifo.analysis_export);
    endfunction

    // ---------------------------------------
    // Main scoring loop
    // ---------------------------------------
    task run_phase(uvm_phase phase);

        fetch_sample tr;

        forever begin
            fifo.get(tr);

            // RESET
            if (tr.reset) begin
                exp_pc     = 0;
                reset_seen = 1;
                continue;
            end

            if (!reset_seen)
                continue;

            // -------------------------
            // 1. COMPARE FIRST
            // -------------------------
            if (tr.pc !== exp_pc) begin
                `uvm_error("SCOREBOARD",
                    $sformatf("PC MISMATCH DUT=%h EXP=%h", tr.pc, exp_pc))
            end

            // -------------------------
            // 2. THEN UPDATE MODEL
            // -------------------------
            if (!tr.stall) begin
                case (tr.pc_src)
                    `PC_SRC_SEQ_F:    exp_pc = exp_pc + 4;
                    `PC_SRC_PRED_F:   exp_pc = tr.pred_pc_target;
                    `PC_SRC_SEQ_E:    exp_pc = tr.pc_plus4_ex;
                    `PC_SRC_TARGET_E: exp_pc = tr.pc_target_ex;
                endcase

            end

        end

    endtask

endclass