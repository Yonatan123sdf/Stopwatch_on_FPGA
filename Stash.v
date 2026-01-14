`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Leo Segre
// 
// Create Date:     05/05/2019 00:19 AM
// Design Name:     EE3 lab1
// Module Name:     Stash
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     a Stash that stores all the samples in order upon sample_in and sample_in_valid.
//                  It exposes the chosen sample by sample_out and the exposed sample can be changed by next_sample. 
// Dependencies:    Lim_Inc
//
// Revision         1.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Stash(clk, reset, sample_in, sample_in_valid, next_sample, sample_out);

   parameter DEPTH = 5;
   
   input clk, reset, sample_in_valid, next_sample;
   input [7:0] sample_in;
   output [7:0] sample_out;
  
    // Calculate pointer bit width
    localparam PTR_BITS = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    
    //------------------------------------------
    // Storage registers
    //------------------------------------------
    reg [7:0] samples [0:DEPTH-1];  // Sample storage array
    
    //------------------------------------------
    // Pointer registers
    //------------------------------------------
    reg [PTR_BITS-1:0] write_ptr_reg;  // Where to write next sample
    reg [PTR_BITS-1:0] read_ptr_reg;   // Which sample to display
    
    //------------------------------------------
    // Lim_Inc outputs for pointer management
    //------------------------------------------
    wire [PTR_BITS-1:0] write_ptr_next;
    wire                write_ptr_wrap;
    
    wire [PTR_BITS-1:0] read_ptr_next;
    wire                read_ptr_wrap;
    
    //------------------------------------------
    // Lim_Inc instances for circular pointers
    //------------------------------------------
    
    // Write pointer: increments on sample_in_valid, wraps at DEPTH
    Lim_Inc #(.L(DEPTH)) lim_inc_write (
        .a(write_ptr_reg),
        .ci(sample_in_valid),
        .sum(write_ptr_next),
        .co(write_ptr_wrap)
    );
    
    // Read pointer: increments on next_sample, wraps at DEPTH
    Lim_Inc #(.L(DEPTH)) lim_inc_read (
        .a(read_ptr_reg),
        .ci(next_sample),
        .sum(read_ptr_next),
        .co(read_ptr_wrap)
    );
    
    //------------------------------------------
    // Sequential logic - Register and memory updates
    //------------------------------------------
    integer i;
    
    always @(posedge clk) begin
        if (reset) begin
            // Clear all samples and reset pointers
            write_ptr_reg <= 0;
            read_ptr_reg  <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                samples[i] <= 8'h00;
            end
        end else begin
            // Handle sample storage
            if (sample_in_valid) begin
                // Store new sample at write pointer
                samples[write_ptr_reg] <= sample_in;
                // Update write pointer
                write_ptr_reg <= write_ptr_next;
                // Jump read pointer to show new sample immediately
                read_ptr_reg <= write_ptr_reg;
            end else if (next_sample) begin
                // Only advance read pointer (no new sample)
                read_ptr_reg <= read_ptr_next;
            end
        end
    end
    
    //------------------------------------------
    // Output multiplexer
    // When sample_in_valid, show the new sample immediately
    // Otherwise, show the sample at read_ptr
    //------------------------------------------
    assign sample_out = sample_in_valid ? sample_in : samples[read_ptr_reg];

endmodule

