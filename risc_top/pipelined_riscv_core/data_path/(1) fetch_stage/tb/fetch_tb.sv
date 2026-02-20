`timescale 1ns/1ps

`include "control_macros.sv"

// To run TB:
// iverilog -g2012 fetch_tb.sv ../fetch_stage.sv  -I ../../../../../common/ ../../../../../common/adder.sv ../../../../../common/flop.sv -o fetch_tb.out
// vvp fetch_tb.out

module fetch_stage_tb;

    // -------------------------------------------------
    // DUT Signals
    // -------------------------------------------------
    logic        clk;
    logic        reset_i;

    logic [1:0]  pc_src_i;
    logic        stall_fi_i;

    logic [31:0] pc_target_ex_i;
    logic [31:0] pc_plus4_ex_i;
    logic [31:0] pred_pc_target_fi_i;

    logic [31:0] pc_fi_o;
    logic [31:0] pc_plus4_fi_o;

    // -------------------------------------------------
    // DUT Instance
    // -------------------------------------------------
    fetch_stage dut (
        .clk_i                  (clk),
        .reset_i                (reset_i),
        .pc_src_i               (pc_src_i),
        .stall_fi_i             (stall_fi_i),
        .pc_target_ex_i         (pc_target_ex_i),
        .pc_plus4_ex_i          (pc_plus4_ex_i),
        .pred_pc_target_fi_i    (pred_pc_target_fi_i),
        .pc_fi_o                (pc_fi_o),
        .pc_plus4_fi_o          (pc_plus4_fi_o)
    );

    // -------------------------------------------------
    // Clock Generation (10ns period)
    // -------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------
    // Scoreboard tracking expected PC
    // -------------------------------------------------
    logic [31:0] expected_pc;

    task automatic check_pc();
        #1; // settle
        if (pc_fi_o !== expected_pc) begin
            $display("❌ ERROR @ %0t | expected: %h | got: %h",
                     $time, expected_pc, pc_fi_o);
            $fatal;
        end
        else begin
            $display("✅ PASS @ %0t | PC = %h",
                     $time, pc_fi_o);
        end
    endtask

    // -------------------------------------------------
    // Test Sequence
    // -------------------------------------------------
    initial begin
        $display("Starting fetch_stage test...");

        // Default values
        pc_src_i            = 2'b00;
        stall_fi_i          = 0;
        pc_target_ex_i      = 32'hAAAA_0000;
        pc_plus4_ex_i       = 32'hBBBB_0000;
        pred_pc_target_fi_i = 32'hCCCC_0000;

        // Reset (pc reg should be zero)
        reset_i = 1;
        repeat (2) @(posedge clk);
        reset_i = 0;

        // -----------------------------------------
        // 1. Sequential increments (PC + 4)
        // -----------------------------------------
        pc_src_i = `PC_SRC_SEQ_F;

        expected_pc = 32'h0000_0000;
        //@(posedge clk);                           ts breaks it!
        check_pc();

        repeat (2) begin
            expected_pc = expected_pc + 4;
            @(posedge clk);
            check_pc();
        end

        // -----------------------------------------
        // 2. Branch prediction source
        // -----------------------------------------
        pc_src_i = `PC_SRC_PRED_F;
        expected_pc = pred_pc_target_fi_i;
        @(posedge clk);
        check_pc();

        // -----------------------------------------
        // 3. EX sequential redirect
        // -----------------------------------------
        pc_src_i = `PC_SRC_SEQ_E;
        expected_pc = pc_plus4_ex_i;
        @(posedge clk);
        check_pc();

        // -----------------------------------------
        // 4. EX target redirect
        // -----------------------------------------
        pc_src_i = `PC_SRC_TARGET_E;
        expected_pc = pc_target_ex_i;
        @(posedge clk);
        check_pc();

        // -----------------------------------------
        // 5. Stall check (PC must not change)
        // -----------------------------------------
        pc_src_i   = `PC_SRC_SEQ_F;
        stall_fi_i = 1;

        @(posedge clk);
        #1;
        if (pc_fi_o !== expected_pc) begin
            $display("❌ ERROR: Stall failed!");
            $fatal;
        end
        else
            $display("✅ PASS: Stall held PC");

        stall_fi_i = 0;

        $display("All tests PASSED.");
        $finish;
    end

endmodule