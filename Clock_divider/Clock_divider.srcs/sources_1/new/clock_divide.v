`timescale 1ns / 1ps

module clock_divider(
    input  wire clk,    // 100 MHz input clock
    input  wire rst_n,  // active-low reset
    output reg  clk_24,  // ~25 MHz output clock
    output wire clk_100
);

    reg [3:0] counter;
    assign clk_100 = clk;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 2'd0;
            clk_24  <= 1'b0;
        end else begin
            if (counter == 8) begin
                counter <= 0;
                clk_24  <= ~clk_24; // toggle every 2 input cycles
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
