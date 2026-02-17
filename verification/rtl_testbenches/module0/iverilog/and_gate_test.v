//simple tb

'timescale 1ns/1ps

module and_gate_test;

    reg a, b;   //driven by testbench -> use reg
    wire y;     //monitored by testbench -> use wire

    and_gate dut (
        .a(a),      //DUT port a to testbench signal a
        .b(b),
        .y(y)
    )

    initial begin

        $display("AND Gate testbench")

        a = 0;      //Initial values
        b = 0;
        #10;        //wait 10 ns

        $display("Time |  a  |  b  |  y  | Expected");
        $display("-----|-----|-----|-----|----------");

        a = 0; b = 0;  // Apply test vector
        #5;            // Wait 5ns for combinational logic to propagate
        $display("%4t |  %b  |  %b  |  %b  |    0", $time, a, b, y);
        // Self-checking: verify output matches expected value
        // !== is case equality (checks value and X/Z states)
        if (y !== 0) $error("Test failed: 0 & 0 should be 0");

        /**
         * Test Case 2: 0 & 1 = 0
         * 
         * Tests second row of truth table.
         * One input is 0, so output should be 0 (AND requires both to be 1).
         */
        a = 0; b = 1;
        #5;
        $display("%4t |  %b  |  %b  |  %b  |    0", $time, a, b, y);
        if (y !== 0) $error("Test failed: 0 & 1 should be 0");

        /**
         * Test Case 3: 1 & 0 = 0
         * 
         * Tests third row of truth table.
         * Symmetric to test case 2.
         */
        a = 1; b = 0;
        #5;
        $display("%4t |  %b  |  %b  |  %b  |    0", $time, a, b, y);
        if (y !== 0) $error("Test failed: 1 & 0 should be 0");

                /**
         * Test Case 4: 1 & 1 = 1
         * 
         * Tests fourth row of truth table.
         * Both inputs are 1, so output should be 1 (only case where AND is true).
         */
        a = 1; b = 1;
        #5;
        $display("%4t |  %b  |  %b  |  %b  |    1", $time, a, b, y);
        if (y !== 1) $error("Test failed: 1 & 1 should be 1");
        
        // Test completion message
        $display("\n========================================");
        $display("All tests passed!");
        $display("========================================");
        #10;    // Final delay before finishing
        $finish; // Terminate simulation
    end

        /**
     * VCD (Value Change Dump) File Generation
     * 
     * This initial block generates a VCD file that can be viewed in GTKWave.
     * VCD files contain waveform data (signal values over time).
     * 
     * System Tasks:
     * - $dumpfile("filename.vcd"): Specifies output VCD file name
     * - $dumpvars(level, module): Dumps signals to VCD file
     *   - level 0: All signals in module and all submodules
     *   - level 1: Only signals in this module (not submodules)
     *   - level 2+: Deeper hierarchy levels
     * 
     * Viewing waveforms:
     *   gtkwave and_gate_test.vcd
     * 
     * Note: This block runs in parallel with the test sequence block above.
     *       Both initial blocks start at time 0 and run concurrently.
     */
    initial begin
        $dumpfile("and_gate_test.vcd");           // Set VCD output file
        $dumpvars(0, and_gate_test);              // Dump all signals (level 0 = all)
    end
            
endmodule