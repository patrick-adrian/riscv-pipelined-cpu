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

    // Clocking block for race-free driver updates and monitor sampling.
    // - Driver outputs land in the clocking block output region at `posedge clk`
    // - Monitor samples `pc` after NBA updates (via #1step input skew)
    clocking cb @(posedge clk);
        default input #1step output #0;
        output pc_src, stall, pc_target_ex, pc_plus4_ex, pred_pc_target;
        input  pc;
    endclocking

endinterface

