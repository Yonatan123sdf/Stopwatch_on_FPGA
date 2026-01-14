`timescale 1ns / 1ps

module Stash_tb();

    parameter DEPTH = 10;
    localparam integer CLK_PERIOD = 10; // 100MHz -> 10ns

    reg  clk, reset, sample_in_valid, next_sample, correct, loop_was_skipped;
    reg  [7:0] sample_in;
    wire [7:0] sample_out;

    integer ini;

    // ---------------------------
    // UUT
    // ---------------------------
    Stash #(.DEPTH(DEPTH)) uut (
        .clk(clk),
        .reset(reset),
        .sample_in(sample_in),
        .sample_in_valid(sample_in_valid),
        .next_sample(next_sample),
        .sample_out(sample_out)
    );

    // ---------------------------
    // One clock generator (keep ONLY one)
    // ---------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ---------------------------
    // Reference model (expected behavior)
    // ---------------------------
    reg [7:0] mem [0:DEPTH-1];
    integer wr_ptr, show_ptr;
    reg [7:0] exp_out;

    task init_model;
        integer k;
        begin
            wr_ptr   = 0;
            show_ptr = 0;
            exp_out  = 8'h00;
            for (k = 0; k < DEPTH; k = k + 1)
                mem[k] = 8'h00;
        end
    endtask

    // Update the reference model on each posedge, same as synchronous DUT
    // Priority: reset > sample_in_valid (jump to new sample) > next_sample
    task model_posedge_update;
        begin
            if (reset) begin
                init_model();
            end else begin
                if (sample_in_valid) begin
                    mem[wr_ptr] = sample_in;
                    show_ptr    = wr_ptr;                 // jump to new sample
                    wr_ptr      = (wr_ptr + 1) % DEPTH;   // overwrite oldest when full
                end else if (next_sample) begin
                    show_ptr    = (show_ptr + 1) % DEPTH; // wrap around
                end
                exp_out = mem[show_ptr];
            end
        end
    endtask

    // ---------------------------
    // Test sequence
    // ---------------------------
    initial begin
        correct = 1'b1;
        loop_was_skipped = 1'b1;

        // init inputs
        reset = 1'b1;
        sample_in_valid = 1'b0;
        next_sample = 1'b0;
        sample_in = 8'h00;

        init_model();

        // Hold reset for a couple cycles
        repeat (2) @(posedge clk);
        model_posedge_update(); // keep model aligned
        repeat (1) @(posedge clk);
        model_posedge_update();

        reset = 1'b0;

        // ---------------------------------------------------------
        // Part A: Stimulate at least DEPTH+1 samples (here: DEPTH+2)
        // Write 7 samples for DEPTH=5, so we definitely overwrite.
        // ---------------------------------------------------------
        for (ini = 0; ini < (DEPTH + 2); ini = ini + 1) begin
            // Drive inputs before the clock edge
            @(negedge clk);
            sample_in       = 8'hA0 + ini; // any changing pattern
            sample_in_valid = 1'b1;

            // also sometimes assert next_sample, but sample_in_valid must dominate
            next_sample     = (ini == 2) ? 1'b1 : 1'b0;

            // Apply on posedge
            @(posedge clk);
            model_posedge_update();

            // Let DUT settle (NBA/comb)
            #1;

            // Check: output must show the new sample immediately (jump)
            if (sample_out !== exp_out) begin
                correct = 1'b0;
                $display("Mismatch WRITE: i=%0d in=%0h | got out=%0h exp=%0h | t=%0t",
                         ini, sample_in, sample_out, exp_out, $time);
            end

            // Deassert valid after the write cycle
            @(negedge clk);
            sample_in_valid = 1'b0;
            next_sample     = 1'b0;

            loop_was_skipped = 1'b0;
        end

        // ---------------------------------------------------------
        // Part B: Now test next_sample wrap-around (no new writes)
        // Step through more than DEPTH times and compare output.
        // ---------------------------------------------------------
        for (ini = 0; ini < (DEPTH + 2); ini = ini + 1) begin
            @(negedge clk);
            next_sample = 1'b1;
            sample_in_valid = 1'b0;

            @(posedge clk);
            model_posedge_update();
            #1;

            if (sample_out !== exp_out) begin
                correct = 1'b0;
                $display("Mismatch NEXT: step=%0d | got out=%0h exp=%0h | t=%0t",
                         ini, sample_out, exp_out, $time);
            end

            @(negedge clk);
            next_sample = 1'b0;

            loop_was_skipped = 1'b0;
        end

        // Final result
        #5;
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end

endmodule
