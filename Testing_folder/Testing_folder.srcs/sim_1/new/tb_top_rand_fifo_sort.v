`timescale 1ns / 1ps

module tb_top_rand_fifo_sort();

    reg wr_clk  = 0;
    reg rd_clk  = 0;
    reg wrst_n  = 0;   // write-domain ACTIVE-LOW reset
    reg rrst_n  = 0;   // read-domain  ACTIVE-LOW reset

    wire [63:0] sort_out;
    wire        done;

    top_rand_fifo_sort uut (
        .wr_clk  (wr_clk),
        .rd_clk  (rd_clk),
        .wrst_n  (wrst_n),
        .rrst_n  (rrst_n),
        .sort_out(sort_out),
        .done    (done)
    );

    // clocks
    always #21 wr_clk = ~wr_clk;
    always #5 rd_clk = ~rd_clk;

    initial begin
        $dumpfile("tb_top_rand_fifo_sort.vcd");
        $dumpvars(0, tb_top_rand_fifo_sort);

        // hold both domains in reset (active-low)
        wrst_n = 1'b0;
        rrst_n = 1'b0;

        #100;
        // release resets
        wrst_n = 1'b1;
        rrst_n = 1'b1;

        // Let the simulation run forever:
        forever begin
            @(posedge rd_clk);
            if (done) begin
                $display("%0t ns: SORTED = %h", $time, sort_out);
            end
        end
    end

endmodule
