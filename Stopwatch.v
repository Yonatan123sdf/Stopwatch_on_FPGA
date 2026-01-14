`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2026 01:01:03 PM
// Design Name: 
// Module Name: Stopwatch
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

module Stopwatch(
    input  wire       clk,        // 100MHz system clock
    input  wire       btnC,       // Center button - Reset
    input  wire       btnU,       // Up button - Trigger/Next Sample
    input  wire       btnR,       // Right button - Split
    input  wire       btnL,       // Left button - Toggle display
    input  wire       btnD,       // Down button - Sample to Stash
    output wire [6:0] seg,        // 7-segment cathodes
    output wire [3:0] an,         // 7-segment anodes
    output wire       dp,         // Decimal point
    output wire [2:0] led_left,   // Left LEDs (stopwatch indicator)
    output wire [2:0] led_right   // Right LEDs (stash indicator)
);

    //------------------------------------------
    // Parameters
    //------------------------------------------
    parameter CLK_FREQ = 100000000;  // 100MHz
    parameter DEBOUNCE_BITS = 20;    // ~10ms debounce at 100MHz
    parameter STASH_DEPTH = 5;       // Number of samples in stash
    
    //------------------------------------------
    // Debounced button signals
    //------------------------------------------
    wire btn_reset;      // Debounced reset (btnC)
    wire btn_trig;       // Debounced trigger (btnU)
    wire btn_split;      // Debounced split (btnR)
    wire btn_toggle;     // Debounced toggle (btnL)
    wire btn_sample;     // Debounced sample (btnD)

    //------------------------------------------
    // Focus mode register
    // 0 = Stopwatch focus (btnU ? FSM)
    // 1 = Stash focus (btnU ? next_sample)
    //------------------------------------------

    reg display_stash;
    
    //------------------------------------------
    // Debouncer instances for all buttons
    //------------------------------------------
    Debouncer #(.COUNTER_BITS(DEBOUNCE_BITS)) debounce_reset (
        .clk(clk),
        .input_unstable(btnC),
        .output_stable(btn_reset)
    );
    
    Debouncer #(.COUNTER_BITS(DEBOUNCE_BITS)) debounce_trig (
        .clk(clk),
        .input_unstable(btnU),
        .output_stable(btn_trig)
    );
    
    Debouncer #(.COUNTER_BITS(DEBOUNCE_BITS)) debounce_split (
        .clk(clk),
        .input_unstable(btnR),
        .output_stable(btn_split)
    );
    
    Debouncer #(.COUNTER_BITS(DEBOUNCE_BITS)) debounce_toggle (
        .clk(clk),
        .input_unstable(btnL),
        .output_stable(btn_toggle)
    );
    
    Debouncer #(.COUNTER_BITS(DEBOUNCE_BITS)) debounce_sample (
        .clk(clk),
        .input_unstable(btnD),
        .output_stable(btn_sample)
    );
    
    //------------------------------------------
    // Control FSM signals
    //------------------------------------------
    wire init_regs;
    wire count_enabled;
    
    //------------------------------------------
    // Control FSM instance
    //------------------------------------------
    Ctl control_fsm (
        .clk(clk),
        .reset(btn_reset),
        .trig(btn_trig && !display_stash),  
        .split(btn_split),
        .init_regs(init_regs),
        .count_enabled(count_enabled)
    );
    
    //------------------------------------------
    // Counter signals
    //------------------------------------------
    wire [7:0] time_reading;  // {dasec[3:0], sec[3:0]}
    
    //------------------------------------------
    // Counter instance
    //------------------------------------------
    Counter #(.CLK_FREQ(CLK_FREQ)) counter_inst (
        .clk(clk),
        .init_regs(init_regs),
        .count_enabled(count_enabled),
        .time_reading(time_reading)
    );
    
    //------------------------------------------
    // Split display register
    // Captures time when split is pressed in COUNTING state
    //------------------------------------------
    reg [7:0] split_time;
    reg       split_active;
    
    // Detect if we're in COUNTING state (count_enabled=1 and not reset)
    wire in_counting = count_enabled && !init_regs;
    
    always @(posedge clk) begin
        if (init_regs) begin
            // Reset clears split
            split_time <= 8'h00;
            split_active <= 1'b0;
        end else if (in_counting && btn_split) begin
            // In COUNTING: split captures current time
            split_time <= time_reading;
            split_active <= 1'b1;
        end else if (!count_enabled && !init_regs) begin
            // Entering PAUSED: show real time
            split_active <= 1'b0;
        end
    end
    
    // Stopwatch display value: split time if active, else real time
    wire [7:0] stopwatch_display = split_active ? split_time : time_reading;
    
    //------------------------------------------
    // Stash signals
    //------------------------------------------
    wire [7:0] stash_out;
    
    //------------------------------------------
    // Stash instance
    //------------------------------------------
    Stash #(.DEPTH(STASH_DEPTH)) stash_inst (
        .clk(clk),
        .reset(btn_reset),
        .sample_in(time_reading),
        .sample_in_valid(btn_sample),
        .next_sample(btn_trig && display_stash),  // Use trig as next when in stash mode
        .sample_out(stash_out)
    );
    
    //------------------------------------------
    // Display mode toggle
    // 0 = Show stopwatch, 1 = Show stash
    //------------------------------------------
    
    
    always @(posedge clk) begin
        if (btn_reset) begin
            display_stash <= 1'b0;  // Default to stopwatch
        end else if (btn_toggle) begin
            display_stash <= ~display_stash;  // Toggle on button press
        end
    end
    
    //------------------------------------------
    // Display value selection
    //------------------------------------------
    
    // Expand 8-bit {dasec, sec} to 16-bit for 4-digit display
    // Left 2 digits show dasec.sec, right 2 digits show same
    wire [15:0] display_16bit = {stopwatch_display, stash_out};
    
    //------------------------------------------
    // 7-Segment Display instance
    //------------------------------------------
    Seg_7_Display display_inst (
        .x(display_16bit),
        .clk(clk),
        .clr(btn_reset),
        .a_to_g(seg),
        .an(an),
        .dp(dp)
    );
    
    //------------------------------------------
    // LED indicators
    // Stopwatch mode: left LEDs ON
    // Stash mode: right LEDs ON
    //------------------------------------------
    assign led_left  = display_stash ? 3'b000 : 3'b111;
    assign led_right = display_stash ? 3'b111 : 3'b000;

endmodule
