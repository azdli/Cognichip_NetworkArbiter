// 8x8 Switch Arbiter with 0=idle, 1-8=port encoding
// Implements round-robin arbitration for an 8-input, 8-output crossbar switch
// Each input can request any output (1-8), and each output grants to at most one input
// Request value of 0 means idle (not requesting)
// Self-requests (input[i] -> output[i]) are blocked as they serve no purpose

module switch_arbiter_8x8 (
    input  wire        clock,
    input  wire        reset,
    
    // Request signals: 4-bit values where 0=idle, 1-8=requested output
    input  wire [3:0]  request_0,  // Input 0 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_1,  // Input 1 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_2,  // Input 2 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_3,  // Input 3 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_4,  // Input 4 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_5,  // Input 5 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_6,  // Input 6 requests (0=idle, 1-8=output)
    input  wire [3:0]  request_7,  // Input 7 requests (0=idle, 1-8=output)
    
    // Acknowledge signals from outputs (1-8 encoding)
    input  wire [7:0]  ack,         // ack[output_port-1] for outputs 1-8
    
    // Grant signals: 4-bit values where 0=no grant, 1-8=granted output
    output reg  [3:0]  grant_0,
    output reg  [3:0]  grant_1,
    output reg  [3:0]  grant_2,
    output reg  [3:0]  grant_3,
    output reg  [3:0]  grant_4,
    output reg  [3:0]  grant_5,
    output reg  [3:0]  grant_6,
    output reg  [3:0]  grant_7,
    
    // Grant valid signals (derived from grant != 0)
    output reg  [7:0]  grant_valid  // grant_valid[input_port]
);

    // Convert 4-bit requests to one-hot for each output
    // Each output collects which inputs are requesting it
    wire [7:0] output_requests [7:0];  // output_requests[output-1][input]
    
    // Output 1 (index 0): check which inputs request output 1
    assign output_requests[0] = {
        (request_7 == 4'd1) & (4'd1 != 4'd8),  // Input 7, not self
        (request_6 == 4'd1) & (4'd1 != 4'd7),  // Input 6, not self
        (request_5 == 4'd1) & (4'd1 != 4'd6),  // Input 5, not self
        (request_4 == 4'd1) & (4'd1 != 4'd5),  // Input 4, not self
        (request_3 == 4'd1) & (4'd1 != 4'd4),  // Input 3, not self
        (request_2 == 4'd1) & (4'd1 != 4'd3),  // Input 2, not self
        (request_1 == 4'd1) & (4'd1 != 4'd2),  // Input 1, not self
        (request_0 == 4'd1) & (4'd1 != 4'd1)   // Input 0, not self
    };
    
    // Output 2 (index 1)
    assign output_requests[1] = {
        (request_7 == 4'd2) & (4'd2 != 4'd8),
        (request_6 == 4'd2) & (4'd2 != 4'd7),
        (request_5 == 4'd2) & (4'd2 != 4'd6),
        (request_4 == 4'd2) & (4'd2 != 4'd5),
        (request_3 == 4'd2) & (4'd2 != 4'd4),
        (request_2 == 4'd2) & (4'd2 != 4'd3),
        (request_1 == 4'd2) & (4'd2 != 4'd2),  // Self-blocked
        (request_0 == 4'd2) & (4'd2 != 4'd1)
    };
    
    // Output 3 (index 2)
    assign output_requests[2] = {
        (request_7 == 4'd3) & (4'd3 != 4'd8),
        (request_6 == 4'd3) & (4'd3 != 4'd7),
        (request_5 == 4'd3) & (4'd3 != 4'd6),
        (request_4 == 4'd3) & (4'd3 != 4'd5),
        (request_3 == 4'd3) & (4'd3 != 4'd4),
        (request_2 == 4'd3) & (4'd3 != 4'd3),  // Self-blocked
        (request_1 == 4'd3) & (4'd3 != 4'd2),
        (request_0 == 4'd3) & (4'd3 != 4'd1)
    };
    
    // Output 4 (index 3)
    assign output_requests[3] = {
        (request_7 == 4'd4) & (4'd4 != 4'd8),
        (request_6 == 4'd4) & (4'd4 != 4'd7),
        (request_5 == 4'd4) & (4'd4 != 4'd6),
        (request_4 == 4'd4) & (4'd4 != 4'd5),
        (request_3 == 4'd4) & (4'd4 != 4'd4),  // Self-blocked
        (request_2 == 4'd4) & (4'd4 != 4'd3),
        (request_1 == 4'd4) & (4'd4 != 4'd2),
        (request_0 == 4'd4) & (4'd4 != 4'd1)
    };
    
    // Output 5 (index 4)
    assign output_requests[4] = {
        (request_7 == 4'd5) & (4'd5 != 4'd8),
        (request_6 == 4'd5) & (4'd5 != 4'd7),
        (request_5 == 4'd5) & (4'd5 != 4'd6),
        (request_4 == 4'd5) & (4'd5 != 4'd5),  // Self-blocked
        (request_3 == 4'd5) & (4'd5 != 4'd4),
        (request_2 == 4'd5) & (4'd5 != 4'd3),
        (request_1 == 4'd5) & (4'd5 != 4'd2),
        (request_0 == 4'd5) & (4'd5 != 4'd1)
    };
    
    // Output 6 (index 5)
    assign output_requests[5] = {
        (request_7 == 4'd6) & (4'd6 != 4'd8),
        (request_6 == 4'd6) & (4'd6 != 4'd7),
        (request_5 == 4'd6) & (4'd6 != 4'd6),  // Self-blocked
        (request_4 == 4'd6) & (4'd6 != 4'd5),
        (request_3 == 4'd6) & (4'd6 != 4'd4),
        (request_2 == 4'd6) & (4'd6 != 4'd3),
        (request_1 == 4'd6) & (4'd6 != 4'd2),
        (request_0 == 4'd6) & (4'd6 != 4'd1)
    };
    
    // Output 7 (index 6)
    assign output_requests[6] = {
        (request_7 == 4'd7) & (4'd7 != 4'd8),
        (request_6 == 4'd7) & (4'd7 != 4'd7),  // Self-blocked
        (request_5 == 4'd7) & (4'd7 != 4'd6),
        (request_4 == 4'd7) & (4'd7 != 4'd5),
        (request_3 == 4'd7) & (4'd7 != 4'd4),
        (request_2 == 4'd7) & (4'd7 != 4'd3),
        (request_1 == 4'd7) & (4'd7 != 4'd2),
        (request_0 == 4'd7) & (4'd7 != 4'd1)
    };
    
    // Output 8 (index 7)
    assign output_requests[7] = {
        (request_7 == 4'd8) & (4'd8 != 4'd8),  // Self-blocked
        (request_6 == 4'd8) & (4'd8 != 4'd7),
        (request_5 == 4'd8) & (4'd8 != 4'd6),
        (request_4 == 4'd8) & (4'd8 != 4'd5),
        (request_3 == 4'd8) & (4'd8 != 4'd4),
        (request_2 == 4'd8) & (4'd8 != 4'd3),
        (request_1 == 4'd8) & (4'd8 != 4'd2),
        (request_0 == 4'd8) & (4'd8 != 4'd1)
    };

    // Round-robin priority pointers for each output (REGISTERED)
    reg [2:0] rr_priority [7:0];
    
    // Combinatorial grant decisions
    reg [2:0] comb_granted_input [7:0];
    reg [7:0] comb_grant_valid;

    // Registered copies of grant decisions for ack matching
    reg [2:0] reg_granted_input [7:0];
    reg [7:0] reg_grant_valid;

    integer comb_i, comb_j;
    reg [2:0] comb_search_idx;
    reg       comb_found;
    
    // COMBINATORIAL ARBITRATION LOGIC
    // Computes grants based on current registered priority and current requests
    always @(*) begin
        for (comb_i = 0; comb_i < 8; comb_i = comb_i + 1) begin
            comb_found                     = 1'b0;
            comb_grant_valid[comb_i]       = 1'b0;
            comb_granted_input[comb_i]     = 3'b000;
            
            // Round-robin search starting from registered priority pointer
            for (comb_j = 0; comb_j < 8; comb_j = comb_j + 1) begin
                comb_search_idx = (rr_priority[comb_i] + comb_j[2:0]) & 3'b111;
                
                if (!comb_found && output_requests[comb_i][comb_search_idx]) begin
                    comb_granted_input[comb_i] = comb_search_idx;
                    comb_grant_valid[comb_i]   = 1'b1;
                    comb_found                 = 1'b1;
                end
            end
        end
    end
    
    // SEQUENTIAL LOGIC: Priority Update + Output Registration
    // Updates priority pointers based on registered grants and acks
    // Registers grant outputs to eliminate glitches
    always @(posedge clock) begin
        if (reset) begin
            rr_priority[0] <= 3'b000; rr_priority[1] <= 3'b000;
            rr_priority[2] <= 3'b000; rr_priority[3] <= 3'b000;
            rr_priority[4] <= 3'b000; rr_priority[5] <= 3'b000;
            rr_priority[6] <= 3'b000; rr_priority[7] <= 3'b000;

            reg_granted_input[0] <= 3'b000; reg_granted_input[1] <= 3'b000;
            reg_granted_input[2] <= 3'b000; reg_granted_input[3] <= 3'b000;
            reg_granted_input[4] <= 3'b000; reg_granted_input[5] <= 3'b000;
            reg_granted_input[6] <= 3'b000; reg_granted_input[7] <= 3'b000;

            reg_grant_valid <= 8'b0;

            grant_0     <= 4'b0000;
            grant_1     <= 4'b0000;
            grant_2     <= 4'b0000;
            grant_3     <= 4'b0000;
            grant_4     <= 4'b0000;
            grant_5     <= 4'b0000;
            grant_6     <= 4'b0000;
            grant_7     <= 4'b0000;
            grant_valid <= 8'b0;
        end else begin

            // Save combinatorial decisions into registered copies
            reg_granted_input[0] <= comb_granted_input[0];
            reg_granted_input[1] <= comb_granted_input[1];
            reg_granted_input[2] <= comb_granted_input[2];
            reg_granted_input[3] <= comb_granted_input[3];
            reg_granted_input[4] <= comb_granted_input[4];
            reg_granted_input[5] <= comb_granted_input[5];
            reg_granted_input[6] <= comb_granted_input[6];
            reg_granted_input[7] <= comb_granted_input[7];
            reg_grant_valid      <= comb_grant_valid;

            // Update priority pointer when grant is acknowledged
            // Uses registered grant from previous cycle to correctly align with ack timing
            if (reg_grant_valid[0] && ack[0]) rr_priority[0] <= (reg_granted_input[0] + 3'b001) & 3'b111;
            if (reg_grant_valid[1] && ack[1]) rr_priority[1] <= (reg_granted_input[1] + 3'b001) & 3'b111;
            if (reg_grant_valid[2] && ack[2]) rr_priority[2] <= (reg_granted_input[2] + 3'b001) & 3'b111;
            if (reg_grant_valid[3] && ack[3]) rr_priority[3] <= (reg_granted_input[3] + 3'b001) & 3'b111;
            if (reg_grant_valid[4] && ack[4]) rr_priority[4] <= (reg_granted_input[4] + 3'b001) & 3'b111;
            if (reg_grant_valid[5] && ack[5]) rr_priority[5] <= (reg_granted_input[5] + 3'b001) & 3'b111;
            if (reg_grant_valid[6] && ack[6]) rr_priority[6] <= (reg_granted_input[6] + 3'b001) & 3'b111;
            if (reg_grant_valid[7] && ack[7]) rr_priority[7] <= (reg_granted_input[7] + 3'b001) & 3'b111;

            // Register grant outputs to eliminate glitches - default to 0 (idle)
            grant_0     <= 4'b0000;
            grant_1     <= 4'b0000;
            grant_2     <= 4'b0000;
            grant_3     <= 4'b0000;
            grant_4     <= 4'b0000;
            grant_5     <= 4'b0000;
            grant_6     <= 4'b0000;
            grant_7     <= 4'b0000;
            grant_valid <= 8'b0;
            
            // Map combinatorial grants to registered outputs
            // Output is numbered 1-8 (not 0-7)
            if (comb_grant_valid[0]) case (comb_granted_input[0])
                3'd0: begin grant_0 <= 4'd1; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd1; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd1; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd1; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd1; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd1; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd1; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd1; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[1]) case (comb_granted_input[1])
                3'd0: begin grant_0 <= 4'd2; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd2; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd2; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd2; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd2; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd2; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd2; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd2; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[2]) case (comb_granted_input[2])
                3'd0: begin grant_0 <= 4'd3; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd3; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd3; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd3; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd3; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd3; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd3; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd3; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[3]) case (comb_granted_input[3])
                3'd0: begin grant_0 <= 4'd4; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd4; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd4; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd4; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd4; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd4; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd4; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd4; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[4]) case (comb_granted_input[4])
                3'd0: begin grant_0 <= 4'd5; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd5; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd5; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd5; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd5; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd5; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd5; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd5; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[5]) case (comb_granted_input[5])
                3'd0: begin grant_0 <= 4'd6; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd6; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd6; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd6; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd6; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd6; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd6; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd6; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[6]) case (comb_granted_input[6])
                3'd0: begin grant_0 <= 4'd7; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd7; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd7; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd7; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd7; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd7; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd7; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd7; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[7]) case (comb_granted_input[7])
                3'd0: begin grant_0 <= 4'd8; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 4'd8; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 4'd8; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 4'd8; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 4'd8; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 4'd8; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 4'd8; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 4'd8; grant_valid[7] <= 1'b1; end
            endcase
        end
    end

endmodule
