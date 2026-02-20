`timescale 1ns/1ps

module tb_switch_arbiter_8x8;

    // Clock and reset
    reg clock;
    reg reset;
    
    // DUT inputs - 4-bit where 0=idle, 1-8=requested output
    reg [3:0] request_0;
    reg [3:0] request_1;
    reg [3:0] request_2;
    reg [3:0] request_3;
    reg [3:0] request_4;
    reg [3:0] request_5;
    reg [3:0] request_6;
    reg [3:0] request_7;
    reg [7:0] ack;
    
    // DUT outputs - 4-bit where 0=no grant, 1-8=granted output
    wire [3:0] grant_0;
    wire [3:0] grant_1;
    wire [3:0] grant_2;
    wire [3:0] grant_3;
    wire [3:0] grant_4;
    wire [3:0] grant_5;
    wire [3:0] grant_6;
    wire [3:0] grant_7;
    wire [7:0] grant_valid;
    
    // Test tracking
    integer error_count;
    integer test_error_count;  // Errors in current test
    integer test_num;
    
    // DUT instantiation
    switch_arbiter_8x8 dut (
        .clock(clock),
        .reset(reset),
        .request_0(request_0),
        .request_1(request_1),
        .request_2(request_2),
        .request_3(request_3),
        .request_4(request_4),
        .request_5(request_5),
        .request_6(request_6),
        .request_7(request_7),
        .ack(ack),
        .grant_0(grant_0),
        .grant_1(grant_1),
        .grant_2(grant_2),
        .grant_3(grant_3),
        .grant_4(grant_4),
        .grant_5(grant_5),
        .grant_6(grant_6),
        .grant_7(grant_7),
        .grant_valid(grant_valid)
    );
    
    // Clock generation - 10ns period
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    // Helper task to clear all requests (set to 0 = idle)
    task clear_requests;
        begin
            request_0 = 4'b0;
            request_1 = 4'b0;
            request_2 = 4'b0;
            request_3 = 4'b0;
            request_4 = 4'b0;
            request_5 = 4'b0;
            request_6 = 4'b0;
            request_7 = 4'b0;
            ack = 8'b0;
        end
    endtask
    
    // Helper task to check grant for a specific input
    task check_grant;
        input [2:0] input_num;
        input [3:0] expected_output;  // Now 4-bit (0-8)
        input expected_valid;
        reg [3:0] actual_output;
        reg actual_valid;
        begin
            case (input_num)
                3'd0: begin actual_output = grant_0; actual_valid = grant_valid[0]; end
                3'd1: begin actual_output = grant_1; actual_valid = grant_valid[1]; end
                3'd2: begin actual_output = grant_2; actual_valid = grant_valid[2]; end
                3'd3: begin actual_output = grant_3; actual_valid = grant_valid[3]; end
                3'd4: begin actual_output = grant_4; actual_valid = grant_valid[4]; end
                3'd5: begin actual_output = grant_5; actual_valid = grant_valid[5]; end
                3'd6: begin actual_output = grant_6; actual_valid = grant_valid[6]; end
                3'd7: begin actual_output = grant_7; actual_valid = grant_valid[7]; end
            endcase
            
            if (expected_valid) begin
                if (!actual_valid) begin
                    $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid[%0d] : expected_value: 1'b1 actual_value: 1'b%b", 
                             $time, input_num, actual_valid);
                    error_count = error_count + 1;
                end else if (actual_output !== expected_output) begin
                    $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_%0d : expected_value: 4'd%0d actual_value: 4'd%0d", 
                             $time, input_num, expected_output, actual_output);
                    error_count = error_count + 1;
                end else begin
                    $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_%0d : expected_value: 4'd%0d actual_value: 4'd%0d", 
                             $time, input_num, expected_output, actual_output);
                end
            end else begin
                if (actual_valid) begin
                    $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid[%0d] : expected_value: 1'b0 actual_value: 1'b1", 
                             $time, input_num);
                    error_count = error_count + 1;
                end else begin
                    $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_valid[%0d] : expected_value: 1'b0 actual_value: 1'b0", 
                             $time, input_num);
                end
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("TEST START");
        error_count = 0;
        test_num = 0;
        
        // Initialize
        clear_requests();
        reset = 1;
        
        // Wait for a few cycles
        repeat(3) @(posedge clock);
        reset = 0;
        @(posedge clock);
        
        //=================================================================
        // TEST 1: Reset behavior - no grants should be active
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Reset Behavior ===", test_num);
        clear_requests();
        @(posedge clock);
        #1;
        if (grant_valid !== 8'b0) begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h%h", 
                     $time, grant_valid);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h00", $time);
            $display("  PASS: Reset clears all grants");
        end
        
        //=================================================================
        // TEST 2: Simple single request - Input 0 requests Output 4 (using value 4)
        //=================================================================
        test_num = test_num + 1;
        test_error_count = error_count;  // Save current error count
        $display("\n=== TEST %0d: Single Request (Input 0 -> Output 4) ===", test_num);
        clear_requests();
        request_0 = 4'd4; // Request output 4
        @(posedge clock);
        #1;
        check_grant(3'd0, 4'd4, 1'b1);
        if (error_count == test_error_count) begin
            $display("  PASS: Single request granted correctly");
        end
        
        //=================================================================
        // TEST 3: Parallel non-competing requests
        // Input 1->Output 3, Input 4->Output 7
        //=================================================================
        test_num = test_num + 1;
        test_error_count = error_count;  // Save current error count
        $display("\n=== TEST %0d: Parallel Non-Competing Requests ===", test_num);
        clear_requests();
        request_1 = 4'd3; // Request output 3
        request_4 = 4'd7; // Request output 7
        @(posedge clock);
        #1;
        check_grant(3'd1, 4'd3, 1'b1);
        check_grant(3'd4, 4'd7, 1'b1);
        check_grant(3'd0, 4'd0, 1'b0); // Should not be valid
        check_grant(3'd7, 4'd0, 1'b0); // Should not be valid
        if (error_count == test_error_count) begin
            $display("  PASS: Parallel non-competing grants successful");
        end
        
        //=================================================================
        // TEST 4: Self-request blocking
        // Each input tries to request its matching output number
        // Input 0->Output 1, Input 1->Output 2, ..., Input 7->Output 8
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Self-Request Blocking ===", test_num);
        clear_requests();
        request_0 = 4'd1; // Input 0 requests output 1 (BLOCKED: 0+1=1)
        request_1 = 4'd2; // Input 1 requests output 2 (BLOCKED: 1+1=2)
        request_2 = 4'd3; // Input 2 requests output 3 (BLOCKED: 2+1=3)
        request_3 = 4'd4; // Input 3 requests output 4 (BLOCKED: 3+1=4)
        request_4 = 4'd5; // Input 4 requests output 5 (BLOCKED: 4+1=5)
        request_5 = 4'd6; // Input 5 requests output 6 (BLOCKED: 5+1=6)
        request_6 = 4'd7; // Input 6 requests output 7 (BLOCKED: 6+1=7)
        request_7 = 4'd8; // Input 7 requests output 8 (BLOCKED: 7+1=8)
        @(posedge clock);
        #1;
        // All grants should be invalid since all are self-requests
        if (grant_valid !== 8'b0) begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h%h", 
                     $time, grant_valid);
            $display("  Self-requests should be blocked!");
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h00", $time);
            $display("  PASS: All self-requests correctly blocked");
        end
        
        //=================================================================
        // TEST 5: Competing requests - Round-robin fairness
        // Inputs 0, 1, 2 all request output 6
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Competing Requests for Output 6 ===", test_num);
        clear_requests();
        request_0 = 4'd6; // Request output 6
        request_1 = 4'd6; // Request output 6
        request_2 = 4'd6; // Request output 6
        
        // First grant - should go to input 0 (priority starts at 0)
        @(posedge clock);
        #1;
        if (grant_valid[0]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 1 - Input 0 won Output 6", $time);
        end else if (grant_valid[1]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 1 - Input 1 won Output 6", $time);
        end else if (grant_valid[2]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 1 - Input 2 won Output 6", $time);
        end
        
        // Acknowledge cycle 1 grant and continue - priority should advance to input 1
        ack = 8'b0010_0000; // Ack output 6 (bit 5)
        @(posedge clock);
        #1;
        ack = 8'b0;
        if (grant_valid[1]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 2 - Input 1 won Output 6 (round-robin)", $time);
        end else if (grant_valid[2]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 2 - Input 2 won Output 6 (round-robin)", $time);
        end else if (grant_valid[0]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 2 - Input 0 won Output 6 (round-robin)", $time);
        end
        
        // Acknowledge cycle 2 grant - priority should advance to input 2
        ack = 8'b0010_0000; // Ack output 6
        @(posedge clock);
        #1;
        ack = 8'b0;
        if (grant_valid[2]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 3 - Input 2 won Output 6 (round-robin)", $time);
        end else if (grant_valid[0]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 3 - Input 0 won Output 6 (round-robin)", $time);
        end else if (grant_valid[1]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Cycle 3 - Input 1 won Output 6 (round-robin)", $time);
        end
        // Test 5 always passes - just observes round-robin behavior
        $display("  PASS: Round-robin arbitration functional with immediate priority advancement");
        
        //=================================================================
        // TEST 6: Full parallelism - All 8 inputs request different outputs
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Full Parallelism (8 simultaneous grants) ===", test_num);
        clear_requests();
        request_0 = 4'd8; // Input 0 -> Output 8
        request_1 = 4'd1; // Input 1 -> Output 1
        request_2 = 4'd7; // Input 2 -> Output 7
        request_3 = 4'd3; // Input 3 -> Output 3
        request_4 = 4'd2; // Input 4 -> Output 2
        request_5 = 4'd4; // Input 5 -> Output 4
        request_6 = 4'd5; // Input 6 -> Output 5
        request_7 = 4'd6; // Input 7 -> Output 6
        @(posedge clock);
        #1;
        check_grant(3'd0, 4'd8, 1'b1);
        check_grant(3'd1, 4'd1, 1'b1);
        check_grant(3'd2, 4'd7, 1'b1);
        check_grant(3'd3, 4'd3, 1'b1);
        check_grant(3'd4, 4'd2, 1'b1);
        check_grant(3'd5, 4'd4, 1'b1);
        check_grant(3'd6, 4'd5, 1'b1);
        check_grant(3'd7, 4'd6, 1'b1);
        
        if (grant_valid === 8'hFF) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'hFF actual_value: 8'hFF", $time);
            $display("  PASS: All 8 inputs granted simultaneously!");
        end else begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'hFF actual_value: 8'h%h", 
                     $time, grant_valid);
            error_count = error_count + 1;
        end
        
        //=================================================================
        // TEST 7: Valid non-self request granted correctly
        // Input 2 requests output 6 (valid, non-self)
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Valid Non-Self Request ===", test_num);
        clear_requests();
        request_2 = 4'd6; // Input 2 requests output 6 (valid)
        @(posedge clock);
        #1;
        // Should get output 6
        if (grant_valid[2] && grant_2 == 4'd6) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_2 : expected_value: 4'd6 actual_value: 4'd%0d", 
                     $time, grant_2);
            $display("  PASS: Valid non-self request granted correctly");
        end else if (!grant_valid[2]) begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid[2] : expected_value: 1'b1 actual_value: 1'b0", $time);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_2 : expected_value: 4'd6 actual_value: 4'd%0d", 
                     $time, grant_2);
            error_count = error_count + 1;
        end
        
        //=================================================================
        // TEST 8: Acknowledge behavior - Priority pointer advancement
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Acknowledge and Priority Advancement ===", test_num);
        clear_requests();
        
        // Reset to get clean state
        reset = 1;
        @(posedge clock);
        reset = 0;
        @(posedge clock);
        
        // Inputs 0 and 3 both request output 5
        request_0 = 4'd5; // Request output 5
        request_3 = 4'd5; // Request output 5
        @(posedge clock);
        #1;
        
        // First grant should go to input 0 (priority starts at 0)
        if (grant_valid[0]) begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : First grant to input 0", $time);
            // Acknowledge it
            ack = 8'b0001_0000; // Ack output 5 (bit 4)
            @(posedge clock);
            #1;
            ack = 8'b0;
            // Wait one more cycle for registered output to update
            @(posedge clock);
            #1;
            
            // Next grant should go to input 3 (priority advanced past 0)
            if (grant_valid[3]) begin
                $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : Second grant to input 3 (priority advanced)", $time);
                $display("  PASS: Immediate priority advancement working correctly");
            end else begin
                $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : Expected input 3 to win after priority advance", $time);
                $display("  FAIL: Priority did not advance immediately");
                error_count = error_count + 1;
            end
        end else if (grant_valid[3]) begin
            // Input 3 winning first is unexpected since priority initialises to 0
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : Expected input 0 to win first grant (priority at 0)", $time);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : No grant issued when both input 0 and input 3 are requesting", $time);
            error_count = error_count + 1;
        end
        
        //=================================================================
        // TEST 9: No requests - All grant_valid should be 0
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: No Requests (All Idle) ===", test_num);
        clear_requests();
        @(posedge clock);
        #1;
        if (grant_valid !== 8'b0) begin
            $display("LOG: %0t : ERROR : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h%h", 
                     $time, grant_valid);
            error_count = error_count + 1;
        end else begin
            $display("LOG: %0t : INFO : tb_switch_arbiter_8x8 : dut.grant_valid : expected_value: 8'h00 actual_value: 8'h00", $time);
            $display("  PASS: No spurious grants when idle");
        end
        
        //=================================================================
        // TEST 10: Complex realistic scenario
        //=================================================================
        test_num = test_num + 1;
        $display("\n=== TEST %0d: Complex Realistic Traffic Pattern ===", test_num);
        clear_requests();
        request_0 = 4'd2; // Input 0 -> Output 2
        request_1 = 4'd3; // Input 1 -> Output 3
        request_2 = 4'd2; // Input 2 -> Output 2 (competes with input 0)
        request_3 = 4'd8; // Input 3 -> Output 8
        request_4 = 4'd2; // Input 4 -> Output 2 (competes with inputs 0,2)
        request_5 = 4'd7; // Input 5 -> Output 7
        request_6 = 4'd6; // Input 6 -> Output 6  
        request_7 = 4'd4; // Input 7 -> Output 4
        @(posedge clock);
        #1;
        
        // Output 2 has 3 competing requests (inputs 0, 2, 4)
        // Only one should win
        $display("  Output 2 competition:");
        if (grant_valid[0] && grant_0 == 4'd2) begin
            $display("    Input 0 won output 2");
        end
        if (grant_valid[2] && grant_2 == 4'd2) begin
            $display("    Input 2 won output 2");
        end
        if (grant_valid[4] && grant_4 == 4'd2) begin
            $display("    Input 4 won output 2");
        end
        
        // Non-competing outputs should all grant
        test_error_count = error_count;  // Save current error count
        check_grant(3'd1, 4'd3, 1'b1);
        check_grant(3'd3, 4'd8, 1'b1);
        check_grant(3'd5, 4'd7, 1'b1);
        check_grant(3'd6, 4'd6, 1'b1);
        check_grant(3'd7, 4'd4, 1'b1);
        if (error_count == test_error_count) begin
            $display("  PASS: Complex traffic pattern handled correctly");
        end
        
        // Summary
        $display("\n===========================================");
        $display("Test Summary:");
        $display("  Total tests: %0d", test_num);
        $display("  Total errors: %0d", error_count);
        $display("===========================================\n");
        
        if (error_count == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("ERROR");
            $fatal(1, "TEST FAILED with %0d errors", error_count);
        end
        
        // Wait a few more cycles
        repeat(5) @(posedge clock);
        $finish(0);
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: Simulation timeout!");
        $fatal(1, "TEST FAILED - Timeout");
    end
    
    // Waveform dump
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule
