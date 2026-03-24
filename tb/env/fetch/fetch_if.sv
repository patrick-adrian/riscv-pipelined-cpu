interface fetch_if(input logic clk);

    logic        reset;

    logic [1:0]  pc_src;
    logic        stall;

    logic [31:0] pc_target_ex;
    logic [31:0] pc_plus4_ex;
    logic [31:0] pred_pc_target;

    logic [31:0] pc;
    logic [31:0] pc_plus4;

    int          cycle;

    // Clocking block used to synchronize the passive monitor to each fetch
    // clock edge before it samples the raw interface signals.
    clocking cb @(posedge clk);
        default input #1step;
        input  reset;
        input  pc_src, stall;
        input  pc_target_ex, pc_plus4_ex, pred_pc_target;
        input  pc, pc_plus4;
    endclocking

endinterface

