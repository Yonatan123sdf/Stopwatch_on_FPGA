`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/02/2026 04:40:21 PM
// Design Name: 
// Module Name: Ctl_tb
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

module Ctl_tb();

    reg clk, reset, trig, split, correct;
    wire init_regs, count_enabled;

    // -----------------------------
    // Instantiate UUT (Unit Under Test)
    // -----------------------------
    Ctl uut (
        .clk(clk),
        .reset(reset),
        .trig(trig),
        .split(split),
        .init_regs(init_regs),
        .count_enabled(count_enabled)
    );

    // -----------------------------
    // Reference model of the FSM
    // -----------------------------
    localparam IDLE     = 2'd0;
    localparam COUNTING = 2'd1;
    localparam PAUSED   = 2'd2;

    reg [1:0] exp_state;

    // expected outputs based on current state (Mealy, but here state-determined)
    task check_outputs;
        reg exp_init;
        reg exp_count;
        begin
            case (exp_state)
                IDLE:     begin exp_init = 1'b1; exp_count = 1'b0; end // 10
                COUNTING: begin exp_init = 1'b0; exp_count = 1'b1; end // 01
                PAUSED:   begin exp_init = 1'b0; exp_count = 1'b0; end // 00
                default:  begin exp_init = 1'b1; exp_count = 1'b0; end
            endcase

            if (init_regs !== exp_init || count_enabled !== exp_count) begin
                correct = 1'b0;
                $display("Mismatch: state=%0d (IDLE=0,CNT=1,PAUSE=2) | in reset=%0b trig=%0b split=%0b | got init=%0b cnt_en=%0b | exp init=%0b cnt_en=%0b | t=%0t",
                         exp_state, reset, trig, split, init_regs, count_enabled, exp_init, exp_count, $time);
            end
        end
    endtask

    // next-state function according to the FSM
    task update_exp_state_at_posedge;
        begin
            if (reset) begin
                exp_state <= IDLE;
            end else begin
                case (exp_state)
                    IDLE: begin
                        if (trig) exp_state <= COUNTING;
                        else      exp_state <= IDLE;
                    end
                    COUNTING: begin
                        if (trig) exp_state <= PAUSED;
                        else      exp_state <= COUNTING;
                    end
                    PAUSED: begin
                        if (trig)       exp_state <= COUNTING;
                        else if (split) exp_state <= IDLE;
                        else            exp_state <= PAUSED;
                    end
                    default: exp_state <= IDLE;
                endcase
            end
        end
    endtask

    // One "cycle step": apply inputs during low phase, check outputs immediately,
    // then advance the expected state on the next posedge.
    task step;
        input r, t, s;
        begin
            @(negedge clk);
            reset = r;
            trig  = t;
            split = s;

            #1;             // outputs are combinational -> should respond immediately
            check_outputs(); // check outputs for *current* state (cycle t)

            @(posedge clk);
            update_exp_state_at_posedge(); // state updates at t+1
        end
    endtask

    // -----------------------------
    // Test sequence (hits all states)
    // -----------------------------
    initial begin
        correct = 1'b1;

        clk = 0;
        reset = 1;
        trig  = 0;
        split = 0;

        exp_state = IDLE; // after reset, expected state is IDLE

        // Hold reset a bit and check IDLE outputs
        step(1,0,0); // IDLE, outputs 10
        step(1,1,1); // still reset => IDLE, outputs 10 (inputs don't care)

        // Release reset, stay IDLE
        step(0,0,0); // IDLE -> IDLE, outputs 10

        // IDLE -> COUNTING by trig
        step(0,1,0); // during this cycle still IDLE outputs 10, next becomes COUNTING
        step(0,0,0); // now COUNTING outputs 01

        // COUNTING -> PAUSED by trig
        step(0,1,0); // cycle in COUNTING outputs 01, next becomes PAUSED
        step(0,0,0); // now PAUSED outputs 00

        // PAUSED self-loop (000)
        step(0,0,0); // PAUSED outputs 00

        // PAUSED -> COUNTING by trig
        step(0,1,0); // PAUSED outputs 00, next COUNTING
        step(0,0,0); // COUNTING outputs 01

        // COUNTING -> IDLE by reset (check that outputs still 01 while counting)
        step(1,0,0); // COUNTING outputs 01, next IDLE
        step(0,0,0); // IDLE outputs 10

        // Go to PAUSED again, then PAUSED -> IDLE by split (001)
        step(0,1,0); // IDLE -> COUNTING next
        step(0,0,0); // COUNTING outputs 01
        step(0,1,0); // COUNTING -> PAUSED next
        step(0,0,0); // PAUSED outputs 00
        step(0,0,1); // split in PAUSED => outputs 00, next IDLE
        step(0,0,0); // IDLE outputs 10

        #10;
        if (correct)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end

    always #5 clk = ~clk;

endmodule
