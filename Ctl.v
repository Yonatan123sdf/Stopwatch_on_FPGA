`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/02/2026 04:21:08 PM
// Design Name: 
// Module Name: Ctl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Ctl(clk, reset, trig, split, init_regs, count_enabled);

   input clk, reset, trig, split;
   output reg init_regs;
   output reg count_enabled;
   
   
   //-------------Internal Constants--------------------------
   localparam SIZE = 3;
   localparam IDLE  = 3'b001, COUNTING = 3'b010, PAUSED = 3'b100 ;
   reg [SIZE-1:0] 	  state,next_state;

   //-------------Transition Function (Delta) ----------------
   always @(posedge clk)
     begin
        if (reset)
          state <= IDLE;
        else
          // FILL HERE STATE TRANSITIONS
		  state <= next_state;
     end
     
    //------------------------------------------
    // State transition logic (combinational)
    // Based on FSM diagram from lab document
    //------------------------------------------
    always @(*) begin
        // Default: stay in current state
        next_state = state;
        
        case (state)
            IDLE: begin
                // IDLE state transitions
                if (reset) begin
                    // 1**/-- : reset pressed, stay in IDLE
                    next_state = IDLE;
                end else if (trig) begin
                    // 01*/-- : trig pressed (no reset), go to COUNTING
                    next_state = COUNTING;
                end else begin
                    // 00*/-- : nothing pressed, stay in IDLE
                    next_state = IDLE;
                end
            end
            
            COUNTING: begin
                // COUNTING state transitions
                if (reset) begin
                    // 1**/-- : reset pressed, go to IDLE
                    next_state = IDLE;
                end else if (trig) begin
                    // 01*/-- : trig pressed (no reset), go to PAUSED
                    next_state = PAUSED;
                end else begin
                    // 00*/-- : nothing pressed, stay in COUNTING
                    next_state = COUNTING;
                end
            end
            
            PAUSED: begin
                // PAUSED state transitions
                if (reset) begin
                    // 1**/-- : reset pressed, go to IDLE
                    next_state = IDLE;
                end else if (trig) begin
                    // 01*/-- : trig pressed, go back to COUNTING
                    next_state = COUNTING;
                end else if (split) begin
                    // 001/-- : split pressed (no reset, no trig), go to IDLE
                    next_state = IDLE;
                end else begin
                    // 000/-- : nothing pressed, stay in PAUSED
                    next_state = PAUSED;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    //------------------------------------------
    // Output logic (combinational - Mealy)
    // Outputs depend on current state AND inputs
    //------------------------------------------
    always @(*) begin
        // Default outputs
        init_regs = 0;
        count_enabled = 0;
        
        case (state)
            IDLE: begin
                // In IDLE: always init_regs=1, count_enabled=0
                // (keeping counter reset while in IDLE)
                init_regs = 1;
                count_enabled = 0;
            end
            
            COUNTING: begin
                // In COUNTING: init_regs=0, count_enabled=1
                // Unless we're about to transition out
                if (reset) begin
                    // Transitioning to IDLE: 1**/01
                    init_regs = 0;
                    count_enabled = 1;
                end else if (trig) begin
                    // Transitioning to PAUSED: 01*/01
                    init_regs = 0;
                    count_enabled = 1;
                end else begin
                    // Staying in COUNTING: 00*/01
                    init_regs = 0;
                    count_enabled = 1;
                end
            end
            
            PAUSED: begin
                // In PAUSED: init_regs=0, count_enabled=0
                // Unless we're resuming counting
                if (reset) begin
                    // Transitioning to IDLE: 1**/00
                    init_regs = 0;
                    count_enabled = 0;
                end else if (trig) begin
                    // Transitioning to COUNTING: 01*/00
                    init_regs = 0;
                    count_enabled = 0;
                end else if (split) begin
                    // Transitioning to IDLE: 001/00
                    init_regs = 0;
                    count_enabled = 0;
                end else begin
                    // Staying in PAUSED: 000/00
                    init_regs = 0;
                    count_enabled = 0;
                end
            end
            
            default: begin
                init_regs = 1;
                count_enabled = 0;
            end
        endcase
    end
   //-------------Output Function (Lambda) ----------------
	// assign init_regs     = // FILL HERE
	// assign count_enabled = // FILL HERE

endmodule