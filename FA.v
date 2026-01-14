`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     04/05/2019 08:59:38 PM
// Design Name:     EE3 lab1
// Module Name:     FA
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Well known full adder
// 
// Dependencies:    None
// 
// Revision:        3.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FA(a, b, ci, sum, co);

  input   a, b, ci;
  output  sum, co;
  
  // FILL HERE
  
  wire a_xor_b;
  wire a_and_b;
  wire axorb_and_ci;
    
  assign a_xor_b = a ^ b;
  assign sum = a_xor_b ^ ci;
    
  assign a_and_b = a & b;
  assign axorb_and_ci = a_xor_b & ci;
  assign co = a_and_b | axorb_and_ci;

endmodule