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

    clocking drv_cb @(posedge clk);
        output reset;
        output tb_valid;
        output pc_src;
        output stall;
        output pc_target_ex;
        output pc_plus4_ex;
        output pred_pc_target;
        input  pc;
        input  pc_plus4;
    endclocking

    clocking mon_cb @(posedge clk);
        input reset;
        input tb_valid;
        input pc_src;
        input stall;
        input pc_target_ex;
        input pc_plus4_ex;
        input pred_pc_target;
        input pc;
        input pc_plus4;
    endclocking

endinterface
