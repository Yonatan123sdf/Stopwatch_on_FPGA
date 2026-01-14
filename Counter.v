`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 00:19 AM
// Design Name:     EE3 lab1
// Module Name:     Counter
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     a counter that advances its reading as long as time_reading 
//                  signal is high and zeroes its reading upon init_regs=1 input.
//                  the time_reading output represents: 
//                  {dekaseconds,seconds}
// Dependencies:    Lim_Inc
//
// Revision         3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module Counter #(
    parameter integer CLK_FREQ = 100000000
)(
    input  wire       clk,
    input  wire       init_regs,
    input  wire       count_enabled,
    output wire [7:0] time_reading
);

    // --------------------------------------------------
    // Registers
    // --------------------------------------------------
    reg [$clog2(CLK_FREQ)-1:0] clk_cnt;
    reg [3:0] ones_seconds;
    reg [3:0] tens_seconds;
    
    // Wires (Lim_Inc outputs)
    
    wire [$clog2(CLK_FREQ)-1:0] clk_div_next;
    wire sec_tick;

    wire [3:0] sec_next;
    wire dasec_tick;

    wire [3:0] dasec_next;

   // FILL HERE THE LIMITED-COUNTER INSTANCES

    // Stage 1: Clock divider ? 1 Hz
    Lim_Inc #(.L(CLK_FREQ)) lim_inc_clk (
        .a(clk_cnt),
        .ci(1'b1),
        .sum(clk_div_next),
        .co(sec_tick)
    );

    // Stage 2: Seconds counter (0-9)
    Lim_Inc #(.L(10)) lim_inc_sec (
        .a(ones_seconds),
        .ci(sec_tick),
        .sum(sec_next),
        .co(dasec_tick)
    );

    // Stage 3: Tens of seconds counter (0-9)
    Lim_Inc #(.L(10)) lim_inc_dasec (
        .a(tens_seconds),
        .ci(dasec_tick),
        .sum(dasec_next),
        .co() // carry intentionally unused
    );

    //------------- Synchronous ----------------
    always @(posedge clk)
    begin
    // FILL HERE THE ADVANCING OF THE REGISTERS AS A FUNCTION OF init_regs, count_enabled
        if (init_regs) begin
            clk_cnt <= 0;
            ones_seconds     <= 0;
            tens_seconds   <= 0;
        end else if (count_enabled) begin
            clk_cnt <= clk_div_next;
            if (sec_tick) begin
                ones_seconds <= sec_next;
                if (dasec_tick)
                    tens_seconds <= dasec_next;
            end
        end
    end

    // Output
    assign time_reading = {tens_seconds, ones_seconds};

endmodule
