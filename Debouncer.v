`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/02/2026 05:27:54 PM
// Design Name: 
// Module Name: Debouncer
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
module Debouncer(clk, input_unstable, output_stable);

   input clk, input_unstable;
   output reg output_stable;

   parameter COUNTER_BITS = 7;

   reg [COUNTER_BITS-1:0] counter; // Hysteresis (saturating) counter
   reg prev_msb;
   reg [COUNTER_BITS-1:0] counter_next;
   // Initialization (not required for hardware, useful for clean simulation start)
   initial begin
     counter       = {COUNTER_BITS{1'b0}};
     prev_msb      = 1'b0;
     output_stable = 1'b0;
   end

   always @(posedge clk)
     begin
        // Compute the next counter value for this clock cycle
        counter_next = counter;

        // Saturating up/down counter based on unstable input
        if (input_unstable == 1)
            counter_next = (counter < {COUNTER_BITS{1'b1}}) ? (counter + 1) : counter;
        else
            counter_next = (counter > {COUNTER_BITS{1'b0}}) ? (counter - 1) : counter;

        // Update the counter register
        counter <= counter_next;

        // ---------------------------------------------------------
        // Generate a single-cycle pulse when the counter MSB
        // transitions from 0 to 1 (boundary crossing,
        // e.g., 3 -> 4 in a 3-bit counter)
        // ---------------------------------------------------------
        output_stable <= (~prev_msb) & counter_next[COUNTER_BITS-1];

        // Store the MSB value for the next cycle (to detect 0->1 transition)
        prev_msb <= counter_next[COUNTER_BITS-1];
     end

endmodule
