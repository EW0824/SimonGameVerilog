// tb_button_decoder.v
`timescale 1ns/1ps

module tb_button_decoder;

    // Inputs
    reg  [3:0] btn_tb;

    // Outputs
    wire       valid_dut;
    wire [1:0] val_dut;

    // Instantiate the DUT
    button_decoder dut (
        .btn   (btn_tb),
        .valid (valid_dut),
        .val   (val_dut)
    );

    // Helper task for testing
    task test_case;
        input [3:0] btn_in;
        input       expected_valid;
        input [1:0] expected_val;
        begin
            btn_tb = btn_in;
            #1; // Allow combinational logic to settle

            if (valid_dut !== expected_valid || (valid_dut && val_dut !== expected_val)) begin
                $display("❌ FAIL: btn=%b -> valid=%b (exp %b), val=%b (exp %b) at time %0t", 
                         btn_tb, valid_dut, expected_valid, val_dut, expected_val, $time);
                $finish;
            end else begin
                $display("✅ PASS: btn=%b -> valid=%b, val=%b at time %0t", 
                         btn_tb, valid_dut, val_dut, $time);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("Starting button_decoder testbench...");

        // Test valid one-hot inputs
        $display("\nTesting valid one-hot inputs:");
        test_case(4'b0001, 1'b1, 2'd0); // btn 0
        test_case(4'b0010, 1'b1, 2'd1); // btn 1
        test_case(4'b0100, 1'b1, 2'd2); // btn 2
        test_case(4'b1000, 1'b1, 2'd3); // btn 3

        // Test invalid inputs
        $display("\nTesting invalid inputs:");
        test_case(4'b0000, 1'b0, 2'd0); // All zeros
        test_case(4'b0011, 1'b0, 2'd0); // Multi-hot
        test_case(4'b1001, 1'b0, 2'd0); // Multi-hot (non-adjacent)
        test_case(4'b1111, 1'b0, 2'd0); // All ones
        // Test other default cases (implicitly covered by default in DUT, but explicit is good)
        test_case(4'b0101, 1'b0, 2'd0);
        test_case(4'b1010, 1'b0, 2'd0);

        $display("\nAll button_decoder tests completed successfully!");
        $finish;
    end

    // Waveform dump (optional, but good practice)
    initial begin
        $dumpfile("tb_button_decoder.vcd");
        $dumpvars(0, tb_button_decoder);
    end

endmodule 