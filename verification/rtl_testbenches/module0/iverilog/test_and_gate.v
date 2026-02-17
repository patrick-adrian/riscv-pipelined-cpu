//comprehensive testbench

`timescale 1ns/1ps

module test_and_gate;

    // Testbench signals
    reg  a, b;
    wire y;
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    and_gate dut (
        .a(a),
        .b(b),
        .y(y)
    );

    // task is basically a function

    task check_and(input reg a_val, b_val, expected);
        begin
            a = a_val;
            b = b_val;  //apply test vectors to DUT inputs
            #5          //wait to propogate

            test_count = test_count + 1;

            //self-checking
            if(y === expected) begin
                //Pass
                pass_count = pass_count + 1;
                $display("[PASS] Test $0d: a=%b, b=%b, y=%b (expected %b)", test_count, a, b, y, expected)

            end else begin
                //Fail
                fail_count = fail_count + 1;
                $error("[FAIL] Test %0d: a=%b, b=%b, y=%b (expected %b)", 
                       test_count, a, b, y, expected);      // $error prints error message and continues simulation
                                                            // Use $fatal to abort simulation on error
            end
        end
    endtask

    //main test sequence

    initial begin
        check_and(0, 0, 0);  // Test case 1: Both inputs 0
        check_and(0, 1, 0);  // Test case 2: A=0, B=1
        check_and(1, 0, 0);  // Test case 3: A=1, B=0
        check_and(1, 1, 1);  // Test case 4: Both inputs 1

        $display("Total tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);

        if (fail_count == 0) begin
            $display("✓ All tests PASSED!");
        end else begin
            $display("✗ Some tests FAILED!");
            $finish(1);  // Exit with error code 1 (failure)
        end
        
        $display("========================================");
        #10;      // Final delay
        $finish;  // Exit with success code (0)
        
    end

    initial begin
        $dumpfile("test_and_gate.vcd");        // Set VCD output filename
        $dumpvars(0, test_and_gate);            // Dump all signals (full hierarchy)
    end


endmodule