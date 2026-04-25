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

            // ======================================================
            // RESET HANDLING
            // ======================================================
            if (tr.reset) begin
                exp_pc     = 32'h0;
                reset_seen = 1'b1;

                `uvm_info("SCOREBOARD",
                    "Reset observed: exp_pc initialized to 0",
                    UVM_HIGH)

                continue;
            end

            // Ignore everything until reset happens
            if (!reset_seen)
                continue;

            // ======================================================
            // COMPARE DUT vs MODEL
            // ======================================================
            if (tr.pc !== exp_pc) begin

                `uvm_error("FETCH_SCOREBOARD",
                    $sformatf(
                        "PC MISMATCH | DUT=%h EXP=%h | src=%0d stall=%0b reset=%0b",
                        tr.pc,
                        exp_pc,
                        tr.pc_src,
                        tr.stall,
                        tr.reset
                    )
                )

            end
            else begin

                `uvm_info("FETCH_SCOREBOARD",
                    $sformatf("OK | pc=%h exp_pc=%h", tr.pc, exp_pc),
                    UVM_LOW)

            end

            // ======================================================
            // MODEL UPDATE (next-cycle expected PC)
            // ======================================================
            if (!tr.stall) begin

                case (tr.pc_src)

                    `PC_SRC_SEQ_F: begin
                        exp_pc = exp_pc + 32'd4;
                    end

                    `PC_SRC_PRED_F: begin
                        exp_pc = tr.pred_pc_target;
                    end

                    `PC_SRC_SEQ_E: begin
                        exp_pc = tr.pc_plus4_ex;
                    end

                    `PC_SRC_TARGET_E: begin
                        exp_pc = tr.pc_target_ex;
                    end

                    default: begin
                        exp_pc = exp_pc;
                    end

                endcase

            end

        end

    endtask

endclass