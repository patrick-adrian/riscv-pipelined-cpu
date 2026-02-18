`timescale 1ns/1ps

module vvp_basics;

    reg [3:0] counter;
    integer i;

    initial begin
        $display("========================================");
        $display("VVP Simulation Basics");
        $display("========================================");
        $display("Simulation started at time %0t", $time);
        
        counter = 0;
        
        // Demonstrate simulation progression
        for (i = 0; i < 5; i = i + 1) begin
            #10;
            counter = counter + 1;
            $display("Time %0t: counter = %0d", $time, counter);
        end
        
        $display("========================================");
        $display("Simulation completed at time %0t", $time);
        $display("========================================");
        #10;
        $finish;
    end
endmodule