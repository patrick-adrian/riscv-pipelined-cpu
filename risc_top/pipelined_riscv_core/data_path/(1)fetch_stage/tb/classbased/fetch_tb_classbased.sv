`timescale 1ns/1ps

`include "control_macros.sv"

// ***iVerilog DOES NOT SUPPORT MAILBOX, CANNOT COMPILE
// To run TB:
// cd ../\(1)fetch_stage/tb
// iverilog -g2012 fetch_tb_classbased.sv ../fetch_stage.sv  -I ../../../../../common/ ../../../../../common/adder.sv ../../../../../common/flop.sv -o fetch_tb_classbased.out
// vvp fetch_tb_classbased.out
// gtkwave fetch_tb_classbased.vcd

interface fetch_if(input logic clk);

    logic reset_i;
    logic [1:0]  pc_src_i;
    logic        stall_fi_i;
    logic [31:0] pc_target_ex_i;
    logic [31:0] pc_plus4_ex_i;
    logic [31:0] pred_pc_target_fi_i;

    logic [31:0] pc_fi_o;
    logic [31:0] pc_plus4_fi_o;

endinterface

//Transaction: single stimulus
class fetch_txn;
    rand logic [1:0] pc_src;
    rand logic       stall;

    function void display();
        $display("[TXN] src=%0d stall=%0d", pc_src, stall);
    endfunction
endclass

//Generator, or "sequencer?"
//puts txns in a mailbox, passes to driver
class fetch_generator;

    mailbox #(fetch_txn) gen2drv;

    function new(mailbox #(fetch_txn) m);
        gen2drv = m;
    endfunction

    task run();
        fetch_txn tx;

        // Sequential cycles
        repeat (3) begin
            tx = new();
            tx.pc_src = `PC_SRC_SEQ_F;
            tx.stall  = 0;
            gen2drv.put(tx);
        end

        // Branch pred
        tx = new();
        tx.pc_src = `PC_SRC_PRED_F;
        tx.stall  = 0;
        gen2drv.put(tx);

        // EX seq
        tx = new();
        tx.pc_src = `PC_SRC_SEQ_E;
        tx.stall  = 0;
        gen2drv.put(tx);

        // EX target
        tx = new();
        tx.pc_src = `PC_SRC_TARGET_E;
        tx.stall  = 0;
        gen2drv.put(tx);

        // Stall
        tx = new();
        tx.pc_src = `PC_SRC_SEQ_F;
        tx.stall  = 1;
        gen2drv.put(tx);
    endtask

endclass

//Driver drives txns to DUT via interdace
class fetch_driver;

    virtual fetch_if vif;
    mailbox #(fetch_txn) gen2drv;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_txn) m);
        this.vif = vif;
        this.gen2drv = m;
    endfunction

    task run();
        fetch_txn tx;

        forever begin
            gen2drv.get(tx);

            vif.pc_src_i   <= tx.pc_src;
            vif.stall_fi_i <= tx.stall;

            @(posedge vif.clk);
        end
    endtask

endclass

//Observes DUT and forwards observed data
class fetch_monitor;

    virtual fetch_if vif;
    mailbox #(logic [31:0]) mon2scb;

    function new(virtual fetch_if vif,
                 mailbox #(logic [31:0]) m);
        this.vif = vif;
        this.mon2scb = m;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            mon2scb.put(vif.pc_fi_o);

            $display("[MON] t=%0t pc=%h",
                $time, vif.pc_fi_o);
        end
    endtask

endclass

//Reference model
class fetch_scoreboard;

    virtual fetch_if vif;
    mailbox #(logic [31:0]) mon2scb;

    logic [31:0] expected_pc;

    function new(virtual fetch_if vif,
                 mailbox #(logic [31:0]) m);
        this.vif = vif;
        this.mon2scb = m;
    endfunction

    task run();
        logic [31:0] observed;

        forever begin
            @(posedge vif.clk);

            if (vif.reset_i)
                expected_pc = 32'd0;
            else if (!vif.stall_fi_i) begin
                case (vif.pc_src_i)
                    `PC_SRC_SEQ_F:
                        expected_pc = expected_pc + 4;
                    `PC_SRC_PRED_F:
                        expected_pc = vif.pred_pc_target_fi_i;
                    `PC_SRC_SEQ_E:
                        expected_pc = vif.pc_plus4_ex_i;
                    `PC_SRC_TARGET_E:
                        expected_pc = vif.pc_target_ex_i;
                endcase
            end

            mon2scb.get(observed);

            if (!vif.reset_i && observed !== expected_pc) begin
                $display("❌ ERROR @ %0t | expected=%h got=%h",
                         $time, expected_pc, observed);
                $fatal;
            end
        end
    endtask

endclass

//connect everything
class fetch_env;

    fetch_generator  gen;
    fetch_driver     drv;
    fetch_monitor    mon;
    fetch_scoreboard scb;

    mailbox #(fetch_txn) gen2drv;
    mailbox #(logic [31:0]) mon2scb;

    function new(virtual fetch_if vif);

        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(vif, mon2scb);
    endfunction

    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask

endclass

//top-level
module fetch_tb;

    logic clk;

    initial clk = 0;
    always #10 clk = ~clk;

    fetch_if intf(clk);

    // DUT
    fetch_stage dut (
        .clk_i(clk),
        .reset_i(intf.reset_i),
        .pc_src_i(intf.pc_src_i),
        .stall_fi_i(intf.stall_fi_i),
        .pc_target_ex_i(intf.pc_target_ex_i),
        .pc_plus4_ex_i(intf.pc_plus4_ex_i),
        .pred_pc_target_fi_i(intf.pred_pc_target_fi_i),
        .pc_fi_o(intf.pc_fi_o),
        .pc_plus4_fi_o(intf.pc_plus4_fi_o)
    );

    fetch_env env;

    initial begin
        // Static inputs
        intf.pc_target_ex_i      = 32'hAAAA0000;
        intf.pc_plus4_ex_i       = 32'hBBBB0000;
        intf.pred_pc_target_fi_i = 32'hCCCC0000;

        // Reset
        intf.reset_i = 1;
        repeat (2) @(posedge clk);
        intf.reset_i = 0;

        env = new(intf);
        env.run();

        #500 $finish;
    end

    initial begin
        $dumpfile("fetch_tb_classbased.vcd");        
        $dumpvars(0, fetch_tb);             
        $dumpvars(1, dut);                         
    end

endmodule

