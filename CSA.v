`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     11/10/2018 08:59:38 PM
// Design Name:     EE3 lab1
// Module Name:     CSA
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Variable length binary adder. The parameter N determines
//                  the bit width of the operands. Implemented according to 
//                  Conditional Sum Adder.
// 
// Dependencies:    FA
// 
// Revision:        2.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module CSA(a, b, ci, sum, co);

    parameter N=4;
    parameter K = N >> 1;
    
    input [N-1:0] a;
    input [N-1:0] b;
    input ci;
    output [N-1:0] sum;
    output co;
    
	
    // FILL HERE
     generate

        // Base case: Single bit - use Full Adder
        if (N == 1) begin : BASE_CASE

            FA fa_base 
            (
                .a(a[0]),
                .b(b[0]),
                .ci(ci),
                .sum(sum[0]),
                .co(co)
            );
            
        // Recursive case: Split and conquer
        end else begin : RECURSIVE_CASE
           
            // Calculate half width
            localparam UPPER = N - K;
            
            // Wires for lower half
            wire [K-1:0] lower_sum;
            wire lower_co;
            
            // Wires for upper half with ci=0
            wire [UPPER-1:0] upper_sum_0;
            wire upper_co_0;
            
            // Wires for upper half with ci=1
            wire [UPPER-1:0] upper_sum_1;
            wire upper_co_1;
            
            // Lower half: compute with actual carry-in
            CSA #(.N(K)) csa_lower (
                .a(a[K-1:0]),
                .b(b[K-1:0]),
                .ci(ci),
                .sum(lower_sum),
                .co(lower_co)
            );
                 
            // Upper half: compute both possibilities
            // Upper half assuming carry-in = 0
            CSA #(.N(UPPER)) csa_upper_0 (
                .a(a[N-1:K]),
                .b(b[N-1:K]),
                .ci(1'b0),
                .sum(upper_sum_0),
                .co(upper_co_0)
            );
            
            // Upper half assuming carry-in = 1
            CSA #(.N(UPPER)) csa_upper_1 (
                .a(a[N-1:K]),
                .b(b[N-1:K]),
                .ci(1'b1),
                .sum(upper_sum_1),
                .co(upper_co_1)
            );
                     
             // Output assignment   
            // Lower half sum is always used directly
            assign sum[K-1:0] = lower_sum;
            
            // Upper half: select based on lower carry-out
            // If lower_co=0, use sum_0; if lower_co=1, use sum_1
            assign sum[N-1:K] = lower_co ? upper_sum_1 : upper_sum_0;
            
            // Final carry-out: select based on lower carry-out
            assign co = lower_co ? upper_co_1 : upper_co_0;
            
        end
    endgenerate
    
endmodule
