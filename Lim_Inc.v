`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 00:16 AM
// Design Name:     EE3 lab1
// Module Name:     Lim_Inc
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Incrementor modulo L, where the input a is *saturated* at L 
//                  If a+ci>L, then the output will be s=0,co=1 anyway.
// 
// Dependencies:    Compadder
// 
// Revision:        3.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Lim_Inc(a, ci, sum, co);
    
    parameter L = 10;
    localparam N = $clog2(L);
    
    input [N-1:0] a;
    input ci;
    output [N-1:0] sum;
    output co;

    // Internal signals
    // Raw sum from CSA (a + ci)
    wire [N-1:0] raw_sum;
    wire raw_co;
    
    // Comparison result: is raw_sum >= L?
    wire overflow;
    
    // Step 1: Compute raw sum using CSA
    // We add 'a' + 'ci' (with b=0, except LSB=ci)
    wire [N-1:0] b_value;
    assign b_value = {{(N-1){1'b0}}, ci};  // b = ci (just the increment)
    
    CSA #(.N(N)) csa_add (
        .a(a),
        .b(b_value),
        .ci(1'b0),
        .sum(raw_sum),
        .co(raw_co)
    );
    
    // Step 2: Check if result >= L
    // overflow = (raw_sum >= L) OR raw_co
    // For unsigned comparison: raw_sum >= L
    // This is combinational comparison
    assign overflow = raw_co | (raw_sum >= L);
    
    // Step 3: Output selection
    // If overflow: sum=0, co=1
    // Else: sum=raw_sum, co=0
    
    assign sum = overflow ? {N{1'b0}} : raw_sum;
    assign co = overflow;

    
endmodule
