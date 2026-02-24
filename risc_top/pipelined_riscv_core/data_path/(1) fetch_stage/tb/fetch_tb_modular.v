`timescale 1ns/1ps

`include "control_macros.sv"

// To run TB:
// iverilog -g2012 fetch_tb.sv ../fetch_stage.sv  -I ../../../../../common/ ../../../../../common/adder.sv ../../../../../common/flop.sv -o fetch_tb_modular.out
// vvp fetch_tb_modular.out
// gtkwave fetch_tb_modular.vcd

//Stimulus Module
module fetch_stage_stimulus(
    output reg        clk_i,
    output reg        reset_i,
    output reg [1:0]  pc_src_i,
    output reg        stall_fi_i,
    output reg [31:0] pc_target_ex_i,         // branch/jump target from ex stage
    output reg [31:0] pc_plus4_ex_i,          // sequential PC (PC + 4) from ex stage
    output reg [31:0] pred_pc_target_fi_i,    // prediction from branch predictor
);

    //LeClock
    initial begin
        clk_i = 0;                    // Start at logic 0
        forever #10 clk_i = ~clk_i;     // Toggle every 10ns (half period)
    end

    initial begin

        // Default values
        pc_src_i            = 2'b00;
        stall_fi_i          = 0;
        pc_target_ex_i      = 32'hAAAA_0000;
        pc_plus4_ex_i       = 32'hBBBB_0000;
        pred_pc_target_fi_i = 32'hCCCC_0000;

        // Reset (pc reg should be zero)
        reset_i = 1;
        repeat (2) @(posedge clk_i);
        reset_i = 0;
    
    end

endmodule

//Monitor process
module fetch_stage_monitor(
    input wire        clk_i,
    input wire        reset_i,
    input wire [1:0]  pc_src_i,
    input wire        stall_fi_i,
    input wire [31:0] pc_target_ex_i,         // branch/jump target from ex stage
    input wire [31:0] pc_plus4_ex_i,          // sequential PC (PC + 4) from ex stage
    input wire [31:0] pred_pc_target_fi_i,    // prediction from branch predictor

    input wire [31:0] pc_fi_o,                // output PC
    input wire [31:0] pc_plus4_fi_o 
);

always @(posedge clk_i) begin

    $display("[MONITOR] Time %0t: Read addr0=%0d -> data0=0x%02h, addr1=%0d -> data1=0x%02h", $time, raddr0, rdata0, raddr1, rdata1);

end

endmodule

//Checker
module fetch_stage_checker(
    input wire        clk_i,
    input wire        reset_i,
    input wire [1:0]  pc_src_i,
    input wire        stall_fi_i,
    input wire [31:0] pc_target_ex_i,         // branch/jump target from ex stage
    input wire [31:0] pc_plus4_ex_i,          // sequential PC (PC + 4) from ex stage
    input wire [31:0] pred_pc_target_fi_i,    // prediction from branch predictor

    input wire [31:0] pc_fi_o,                // output PC
    input wire [31:0] pc_plus4_fi_o 
);




endmodule