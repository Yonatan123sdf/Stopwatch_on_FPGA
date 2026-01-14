`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     00:00:00  AM 05/05/2019 
// Design Name:     EE3 lab1
// Module Name:     Counter_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     test bench for Counter module
// Dependencies:    Counter
//
// Revision:        3.0
// Revision:        3.1 - changed  9999999 to 99999999 for a proper, 1sec delay, 
//                        in the inner test loop.
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Counter_tb();

    reg clk, init_regs, count_enabled, correct, loop_was_skipped;
    wire [7:0] time_reading;
    wire [3:0] tens_seconds_wire;
    wire [3:0] ones_seconds_wire;
    integer ts,os,sync;
    integer i;
    integer exp_total;
    reg [3:0] exp_tens;
    reg [3:0] exp_ones;
    // 100MHz clock => period 10ns (toggle every 5ns)
    localparam integer CLK_FREQ = 100000000;
    // Instantiate the UUT (Unit Under Test)
    Counter #(.CLK_FREQ(CLK_FREQ)) uut ( .clk(clk), .init_regs(init_regs), .count_enabled(count_enabled), .time_reading(time_reading));
    
    assign tens_seconds_wire = time_reading[7:4];
    assign ones_seconds_wire = time_reading[3:0];
    
    initial begin 
        correct = 1;
        loop_was_skipped = 1;

        clk = 1'b0;
        init_regs = 1'b1;
        count_enabled = 1'b0;

        // hold reset a tiny bit
        #20;
        init_regs = 1'b0;
        count_enabled = 1'b1;

        // Verify at least one second of correct counting.
        // We'll verify 2 seconds: after 1s -> 01, after 2s -> 02
        for (i = 1; i <= 2; i = i + 1) begin
            // wait exactly 1 second worth of clock cycles
            repeat (CLK_FREQ) @(posedge clk);
            #5
            // expected time after i seconds
            exp_total = i;
            exp_tens  = (exp_total / 10);
            exp_ones  = (exp_total % 10);

            if (tens_seconds_wire !== exp_tens || ones_seconds_wire !== exp_ones) begin
                correct = 0;
                $display("Mismatch after %0d sec: got %0d%0d, expected %0d%0d (t=%0t)",
                         i,
                         tens_seconds_wire, ones_seconds_wire,
                         exp_tens, exp_ones,
                         $time);
            end

            loop_was_skipped = 0;
        end
        
        #5
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
