// 4x4 Round Robin Arbiter
// Provides fair arbitration among 4 requesters using round robin scheme
// Priority rotates to ensure fairness

module round_robin_arbiter (
    input  logic       clock,
    input  logic       reset,
    input  logic [3:0] request,   // Request signals from 4 sources
    output logic [3:0] grant      // Grant signals (one-hot encoded)
);

    // Priority pointer - tracks which requester was last granted (or init state)
    logic [1:0] priority_ptr;
    logic [1:0] next_priority_ptr;
    
    // Internal signals
    logic       grant_valid;      // Indicates if any grant is issued
    
    // Priority pointer update - rotates to next position after a grant
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            priority_ptr <= 2'b00;  // Start checking from position 0
        end else if (grant_valid) begin
            priority_ptr <= next_priority_ptr;
        end
    end
    
    // Grant logic - round robin arbitration
    always_comb begin
        // Default values
        grant = 4'b0000;
        next_priority_ptr = priority_ptr;
        grant_valid = 1'b0;
        
        // Check requests starting from current priority
        case (priority_ptr)
            2'b00: begin  // Priority: 0 > 1 > 2 > 3
                if (request[0]) begin
                    grant = 4'b0001;
                    next_priority_ptr = 2'b01;
                    grant_valid = 1'b1;
                end else if (request[1]) begin
                    grant = 4'b0010;
                    next_priority_ptr = 2'b10;
                    grant_valid = 1'b1;
                end else if (request[2]) begin
                    grant = 4'b0100;
                    next_priority_ptr = 2'b11;
                    grant_valid = 1'b1;
                end else if (request[3]) begin
                    grant = 4'b1000;
                    next_priority_ptr = 2'b00;
                    grant_valid = 1'b1;
                end
            end
            
            2'b01: begin  // Priority: 1 > 2 > 3 > 0
                if (request[1]) begin
                    grant = 4'b0010;
                    next_priority_ptr = 2'b10;
                    grant_valid = 1'b1;
                end else if (request[2]) begin
                    grant = 4'b0100;
                    next_priority_ptr = 2'b11;
                    grant_valid = 1'b1;
                end else if (request[3]) begin
                    grant = 4'b1000;
                    next_priority_ptr = 2'b00;
                    grant_valid = 1'b1;
                end else if (request[0]) begin
                    grant = 4'b0001;
                    next_priority_ptr = 2'b01;
                    grant_valid = 1'b1;
                end
            end
            
            2'b10: begin  // Priority: 2 > 3 > 0 > 1
                if (request[2]) begin
                    grant = 4'b0100;
                    next_priority_ptr = 2'b11;
                    grant_valid = 1'b1;
                end else if (request[3]) begin
                    grant = 4'b1000;
                    next_priority_ptr = 2'b00;
                    grant_valid = 1'b1;
                end else if (request[0]) begin
                    grant = 4'b0001;
                    next_priority_ptr = 2'b01;
                    grant_valid = 1'b1;
                end else if (request[1]) begin
                    grant = 4'b0010;
                    next_priority_ptr = 2'b10;
                    grant_valid = 1'b1;
                end
            end
            
            2'b11: begin  // Priority: 3 > 0 > 1 > 2
                if (request[3]) begin
                    grant = 4'b1000;
                    next_priority_ptr = 2'b00;
                    grant_valid = 1'b1;
                end else if (request[0]) begin
                    grant = 4'b0001;
                    next_priority_ptr = 2'b01;
                    grant_valid = 1'b1;
                end else if (request[1]) begin
                    grant = 4'b0010;
                    next_priority_ptr = 2'b10;
                    grant_valid = 1'b1;
                end else if (request[2]) begin
                    grant = 4'b0100;
                    next_priority_ptr = 2'b11;
                    grant_valid = 1'b1;
                end
            end
        endcase
    end
    
endmodule
