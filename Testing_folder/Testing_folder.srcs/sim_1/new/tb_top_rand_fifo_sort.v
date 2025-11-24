`timescale 1ns / 1ps

module tb_top_rand_fifo_sort();

    reg wr_clk = 0;
    reg rd_clk = 0;
    reg reset = 1;

    wire [63:0] sort_out;
    wire        done;

    top_rand_fifo_sort uut (
        .wr_clk (wr_clk),
        .rd_clk (rd_clk),
        .reset  (reset),
        .sort_out(sort_out),
        .done    (done)
    );

    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    integer i;

    initial begin
        $dumpfile("tb_top_rand_fifo_sort.vcd");
        $dumpvars(0, tb_top_rand_fifo_sort);
        #1;
        reset = 1;
        #100;
        reset = 0;

        i = 0;
        while (1) begin
            @(posedge rd_clk);
            if (done) begin
                $display("%0t ns: SORTED = %h", $time, sort_out);
                i = i + 1;
                if (i == 8) begin
                    #20;
                    $finish;
                end
            end
        end

        #20;
        $finish;
    end

endmodule
