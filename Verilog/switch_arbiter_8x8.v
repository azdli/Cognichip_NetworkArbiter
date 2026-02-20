// 8x8 Switch Arbiter
// Implements round-robin arbitration for an 8-input, 8-output crossbar switch
// Each input can request any output, and each output grants to at most one input
// Self-requests (input[i] -> output[i]) are blocked as they serve no purpose

module switch_arbiter_8x8 (
    input  wire        clock,
    input  wire        reset,
    
    // Request signals: request[input_port][output_port]
    input  wire [7:0]  request_0,  // Input 0 requests to outputs [7:0]
    input  wire [7:0]  request_1,  // Input 1 requests to outputs [7:0]
    input  wire [7:0]  request_2,  // Input 2 requests to outputs [7:0]
    input  wire [7:0]  request_3,  // Input 3 requests to outputs [7:0]
    input  wire [7:0]  request_4,  // Input 4 requests to outputs [7:0]
    input  wire [7:0]  request_5,  // Input 5 requests to outputs [7:0]
    input  wire [7:0]  request_6,  // Input 6 requests to outputs [7:0]
    input  wire [7:0]  request_7,  // Input 7 requests to outputs [7:0]
    
    // Acknowledge signals from outputs
    input  wire [7:0]  ack,         // ack[output_port]
    
    // Grant signals: grant[input_port] indicates which output was granted
    output reg  [2:0]  grant_0,
    output reg  [2:0]  grant_1,
    output reg  [2:0]  grant_2,
    output reg  [2:0]  grant_3,
    output reg  [2:0]  grant_4,
    output reg  [2:0]  grant_5,
    output reg  [2:0]  grant_6,
    output reg  [2:0]  grant_7,
    
    // Grant valid signals
    output reg  [7:0]  grant_valid  // grant_valid[input_port]
);

    // Internal request matrix reorganized by output port
    wire [7:0] output_requests [7:0];  // output_requests[out][in]
    
    // Reorganize requests by output port, masking diagonal to block self-requests
    assign output_requests[0] = {request_7[0], request_6[0], request_5[0], request_4[0],
                                  request_3[0], request_2[0], request_1[0], request_0[0]}
                                  & 8'b1111_1110;

    assign output_requests[1] = {request_7[1], request_6[1], request_5[1], request_4[1],
                                  request_3[1], request_2[1], request_1[1], request_0[1]}
                                  & 8'b1111_1101;

    assign output_requests[2] = {request_7[2], request_6[2], request_5[2], request_4[2],
                                  request_3[2], request_2[2], request_1[2], request_0[2]}
                                  & 8'b1111_1011;

    assign output_requests[3] = {request_7[3], request_6[3], request_5[3], request_4[3],
                                  request_3[3], request_2[3], request_1[3], request_0[3]}
                                  & 8'b1111_0111;

    assign output_requests[4] = {request_7[4], request_6[4], request_5[4], request_4[4],
                                  request_3[4], request_2[4], request_1[4], request_0[4]}
                                  & 8'b1110_1111;

    assign output_requests[5] = {request_7[5], request_6[5], request_5[5], request_4[5],
                                  request_3[5], request_2[5], request_1[5], request_0[5]}
                                  & 8'b1101_1111;

    assign output_requests[6] = {request_7[6], request_6[6], request_5[6], request_4[6],
                                  request_3[6], request_2[6], request_1[6], request_0[6]}
                                  & 8'b1011_1111;

    assign output_requests[7] = {request_7[7], request_6[7], request_5[7], request_4[7],
                                  request_3[7], request_2[7], request_1[7], request_0[7]}
                                  & 8'b0111_1111;

    // Round-robin priority pointers for each output (REGISTERED)
    reg [2:0] rr_priority [7:0];
    
    // Combinatorial grant decisions (WIRES, not registers!)
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

            grant_0     <= 3'b000;
            grant_1     <= 3'b000;
            grant_2     <= 3'b000;
            grant_3     <= 3'b000;
            grant_4     <= 3'b000;
            grant_5     <= 3'b000;
            grant_6     <= 3'b000;
            grant_7     <= 3'b000;
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

            // Register grant outputs to eliminate glitches
            grant_0     <= 3'b000;
            grant_1     <= 3'b000;
            grant_2     <= 3'b000;
            grant_3     <= 3'b000;
            grant_4     <= 3'b000;
            grant_5     <= 3'b000;
            grant_6     <= 3'b000;
            grant_7     <= 3'b000;
            grant_valid <= 8'b0;
            
            // Map combinatorial grants to registered outputs
            if (comb_grant_valid[0]) case (comb_granted_input[0])
                3'd0: begin grant_0 <= 3'd0; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd0; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd0; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd0; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd0; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd0; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd0; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd0; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[1]) case (comb_granted_input[1])
                3'd0: begin grant_0 <= 3'd1; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd1; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd1; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd1; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd1; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd1; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd1; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd1; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[2]) case (comb_granted_input[2])
                3'd0: begin grant_0 <= 3'd2; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd2; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd2; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd2; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd2; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd2; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd2; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd2; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[3]) case (comb_granted_input[3])
                3'd0: begin grant_0 <= 3'd3; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd3; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd3; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd3; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd3; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd3; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd3; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd3; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[4]) case (comb_granted_input[4])
                3'd0: begin grant_0 <= 3'd4; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd4; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd4; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd4; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd4; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd4; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd4; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd4; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[5]) case (comb_granted_input[5])
                3'd0: begin grant_0 <= 3'd5; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd5; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd5; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd5; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd5; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd5; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd5; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd5; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[6]) case (comb_granted_input[6])
                3'd0: begin grant_0 <= 3'd6; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd6; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd6; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd6; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd6; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd6; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd6; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd6; grant_valid[7] <= 1'b1; end
            endcase
            if (comb_grant_valid[7]) case (comb_granted_input[7])
                3'd0: begin grant_0 <= 3'd7; grant_valid[0] <= 1'b1; end
                3'd1: begin grant_1 <= 3'd7; grant_valid[1] <= 1'b1; end
                3'd2: begin grant_2 <= 3'd7; grant_valid[2] <= 1'b1; end
                3'd3: begin grant_3 <= 3'd7; grant_valid[3] <= 1'b1; end
                3'd4: begin grant_4 <= 3'd7; grant_valid[4] <= 1'b1; end
                3'd5: begin grant_5 <= 3'd7; grant_valid[5] <= 1'b1; end
                3'd6: begin grant_6 <= 3'd7; grant_valid[6] <= 1'b1; end
                3'd7: begin grant_7 <= 3'd7; grant_valid[7] <= 1'b1; end
            endcase
        end
    end

endmodule