`timescale 1ns / 1ps

module tb_top_clock_divider;

    reg clk;
    reg wrst_n;
    reg rrst_n;

    top_clock_divider dut (
        .clk   (clk),
        .wrst_n(wrst_n),
        .rrst_n(rrst_n)
    );

    // 100 MHz input clock (10 ns period)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Active-low resets
    initial begin
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        #100;           // hold reset low for 100 ns
        wrst_n = 1'b1;
        rrst_n = 1'b1;
    end

    // Optionally monitor PLL lock
    wire locked = dut.u_clk_gen.locked;

    // Tap internal signals from top_rand_fifo_sort (for observation)
    wire [63:0] sort_out = dut.Instance_I1.sort_out;
    wire        done     = dut.Instance_I1.done;

    always @(posedge done) begin
        $display("[%0t] DONE, sort_out = %h, locked = %b", $time, sort_out, locked);
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_top_clock_divider.vcd");
        $dumpvars(0, tb_top_clock_divider);
    end

    // Stop simulation after some time
    initial begin
        #200000;   // 200 us
        $finish;
    end

endmodule
