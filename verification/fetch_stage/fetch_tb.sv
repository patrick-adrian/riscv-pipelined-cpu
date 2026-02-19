
module fetch_stage_tb;
    
    reg       clk;
    reg       reset_i;
    
    // Enable signal (1 = count, 0 = hold current value)
    reg       en;
    
    // Counter output (4-bit: values 0-15)
    // 'wire' type because it's driven by DUT
    wire [3:0] count;


    fetch_stage dut (
        .clk(clk),      // Clock input
        .rst_n(rst_n),  // Active-low reset
        .en(en),        // Enable signal
        .count(count)   // 4-bit counter output
    );
    
    always begin
        clk = 0;        // Set clock low
        #10;            // Wait 10ns (half period)
        clk = 1;        // Set clock high
        #10;            // Wait 10ns (half period)
        // Loop continues indefinitely
    end


endmodule