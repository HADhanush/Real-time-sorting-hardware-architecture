`timescale 1ns / 1ps

module top_clock_divider(
    input  wire clk,      // 100 MHz input clock from board
    input  wire wrst_n,   // write-domain reset  (active-low)
    input  wire rrst_n    // read-domain reset   (active-low)
);

    wire clk_100;
    wire clk_90;
    wire locked;

    // PLL expects active-HIGH reset
    wire pll_reset = ~(wrst_n & rrst_n);

    clock_gen_top u_clk_gen (
        .clk_in  (clk),
        .reset   (pll_reset),
        .clk_100 (clk_100),
        .clk_90  (clk_90),
        .locked  (locked)
    );

    wire rd_clk = clk_90;    // write clock: 80 MHz
    wire wr_clk = clk_100;   // read clock: 100 MHz

    wire [63:0] sort_out;
    wire        done;

    top_rand_fifo_sort Instance_I1 (
        .wr_clk (wr_clk),
        .rd_clk (rd_clk),
        .wrst_n (wrst_n),
        .rrst_n (rrst_n),
        .sort_out(sort_out),
        .done(done)
    );

endmodule
