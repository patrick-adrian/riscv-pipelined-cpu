`timescale 1ns/1ps

`include "control_macros.sv"

// To run TB:
// make simulate, make clean

`include "fetch_if.sv"
`include "fetch_txn.sv"
`include "fetch_driver.sv"
`include "fetch_monitor.sv"
`include "fetch_scoreboard.sv"

module fetch_tb;

    logic clk;
    always #5 clk = ~clk;

    fetch_if vif(clk);

    fetch_stage dut (
        .clk_i(clk),
        .reset_i(vif.reset),
        .pc_src_i(vif.pc_src),
        .stall_fi_i(vif.stall),
        .pc_target_ex_i(vif.pc_target_ex),
        .pc_plus4_ex_i(vif.pc_plus4_ex),
        .pred_pc_target_fi_i(vif.pred_pc_target),
        .pc_fi_o(vif.pc),
        .pc_plus4_fi_o(vif.pc_plus4)
    );

    mailbox #(fetch_txn) drv_mbx = new();
    mailbox #(fetch_txn) scb_drv_mbx = new();
    mailbox #(logic [31:0]) mon_mbx = new();

    fetch_driver     driver;
    fetch_monitor    monitor;
    fetch_scoreboard scoreboard;

    initial begin
        clk = 0;
        vif.reset = 1;
        repeat(2) @(posedge clk);
        vif.reset = 0;

        driver = new(vif, drv_mbx);
        monitor = new(vif, mon_mbx);
        scoreboard = new(scb_drv_mbx, mon_mbx);

        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none

        // Generate transactions
        repeat (20) begin
            fetch_txn txn = new();
            assert(txn.randomize());
            drv_mbx.put(txn);
            scb_drv_mbx.put(txn);
        end

        #200 $finish;
    end

endmodule