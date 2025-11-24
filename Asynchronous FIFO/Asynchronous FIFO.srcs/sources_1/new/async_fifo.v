`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 3
)(
    input  wire                   wr_clk,
    input  wire                   rd_clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  din,
    input  wire                   wr_en,
    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  dout,
    output wire                   full,
    output wire                   empty
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_bin_next;
    reg [PTR_WIDTH-1:0] wr_ptr_gray, wr_ptr_gray_next;
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];

    reg [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_bin_next;
    reg [PTR_WIDTH-1:0] rd_ptr_gray, rd_ptr_gray_next;
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];

    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] g;
        integer i;
        begin
            gray_to_bin[PTR_WIDTH-1] = g[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                gray_to_bin[i] = gray_to_bin[i+1] ^ g[i];
        end
    endfunction

    wire [PTR_WIDTH-1:0] rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_sync2);
    assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2], rd_ptr_gray_sync2[PTR_WIDTH-3:0]});

    wire [PTR_WIDTH-1:0] wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_sync2);
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

    always @(*) begin
        wr_ptr_bin_next = wr_ptr_bin;
        if (wr_en && !full)
            wr_ptr_bin_next = wr_ptr_bin + 1'b1;
        wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    end

    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_bin <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    always @(posedge wr_clk) begin
        if (wr_en && !full)
            mem[wr_addr] <= din;
    end

    reg [DATA_WIDTH-1:0] dout_reg;
    always @(posedge rd_clk) begin
        if (rd_en && !empty)
            dout_reg <= mem[rd_addr];
    end
    assign dout = dout_reg;

    always @(*) begin
        rd_ptr_bin_next = rd_ptr_bin;
        if (rd_en && !empty)
            rd_ptr_bin_next = rd_ptr_bin + 1'b1;
        rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;
    end

    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else begin
            rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

endmodule
