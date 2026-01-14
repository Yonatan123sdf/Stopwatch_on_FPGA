`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 00:16 AM
// Design Name:     EE3 lab1
// Module Name:     Lim_Inc_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Limited incrementor test bench
// 
// Dependencies:    Lim_Inc
// 
// Revision:        3.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Lim_Inc_tb();

    reg [3:0] a; 
    reg ci, correct, loop_was_skipped;
    wire [3:0] sum;
    wire co;
    
    integer ai,cii;
    parameter L = 11;
    // Instantiate the UUT (Unit Under Test)
    Lim_Inc #(L) uut (a, ci, sum, co);
    
	//FILL HERE
    reg [3:0] exp_sum;
    reg       exp_co;
    integer   tmp;
    initial begin
        correct = 1;
        loop_was_skipped = 1;
        #1
        //FILL HERE
        for (ai = 0; ai < 16; ai = ai + 1) begin
           for (cii = 0; cii <= 1; cii = cii + 1) begin

            a  = ai[3:0];
            ci = cii[0];
            #5
            tmp = a + ci;
            if (tmp >= L) begin
              exp_sum = 4'b0000;
              exp_co  = 1'b1;
            end else begin
              exp_sum = tmp[3:0];
              exp_co  = 1'b0;
            end

            if (sum !== exp_sum || co !== exp_co) begin
              correct = 0;
              $display("Mismatch: a=%0d ci=%0d | got sum=%0d co=%0b | exp sum=%0d co=%0b | t=%0t",a, ci, sum, co, exp_sum, exp_co, $time);
            end

            loop_was_skipped = 0;
           end
        end
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
endmodule
