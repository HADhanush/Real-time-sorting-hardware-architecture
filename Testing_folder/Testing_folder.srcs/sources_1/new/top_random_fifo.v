`timescale 1ns / 1ps

module top_random_fifo (
    input  wire        wr_clk,
    input  wire        rd_clk,
    input  wire        rst,
    input  wire        rd_en,
    output wire [63:0] fifo_dout,
    output wire        fifo_empty,
    output wire        fifo_full,
    output wire        drop
);

    wire [63:0] rnd64;
    wire        valid64;
    reg         wr_en;
    wire [63:0] din;
    reg         drop_r;

    random_gen u_random (
        .clk(wr_clk),
        .rst(rst),
        .rnd64(rnd64),
        .valid64(valid64)
    );

    assign din = rnd64;

    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_en <= 1'b0;
            drop_r <= 1'b0;
        end
        else begin
            drop_r <= 1'b0;
            if (valid64) begin
                if (!fifo_full) begin
                    wr_en <= 1'b1;
                end
                else begin
                    wr_en <= 1'b0;
                    drop_r <= 1'b1;
                end
            end
            else begin
                wr_en <= 1'b0;
            end
        end
    end

    async_fifo #(
        .DATA_WIDTH(64),
        .ADDR_WIDTH(3)
    ) u_fifo (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .din(din),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(fifo_dout),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    assign drop = drop_r;

endmodule
