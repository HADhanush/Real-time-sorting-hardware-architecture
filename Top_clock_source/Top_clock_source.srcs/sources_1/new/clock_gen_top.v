module clock_gen_top(
    input  wire clk_in,
    input  wire reset,
    output wire clk_100,
    output wire clk_90,
    output wire locked
);

    clk_wiz_1 u_clk_wiz (
        .clk_in1 (clk_in),
        .reset   (reset),
        .clk_out1(clk_100),
        .clk_out2(clk_90),
        .locked  (locked)
    );

endmodule
