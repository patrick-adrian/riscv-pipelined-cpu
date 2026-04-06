interface fetch_if(input logic clk);

    logic        reset;
    logic        tb_valid;

    logic [1:0]  pc_src;
    logic        stall;

    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target;

    logic [31:0] pc;
    logic [31:0] pc_plus4;

endinterface

