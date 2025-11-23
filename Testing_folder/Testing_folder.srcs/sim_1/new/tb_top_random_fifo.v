`timescale 1ns/1ps
module tb_top_random_fifo;

    reg wr_clk;
    reg rd_clk;
    reg rst;

    wire [63:0] fifo_dout;
    reg  rd_en;
    wire fifo_empty;
    wire fifo_full;
    wire drop;

    integer cycle_count;

    top_random_fifo dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .rd_en(rd_en),
        .fifo_dout(fifo_dout),
        .fifo_empty(fifo_empty),
        .fifo_full(fifo_full),
        .drop(drop)
    );

    initial wr_clk = 0;
    always #7 wr_clk = ~wr_clk;

    initial rd_clk = 0;
    always #5 rd_clk = ~rd_clk;

    task do_reset;
    begin
        rst = 1;
        rd_en = 0;
        cycle_count = 0;
        repeat (10) @(posedge wr_clk);
        rst = 0;
    end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top_random_fifo);

        do_reset;

        while (cycle_count < 20000) begin
            @(posedge rd_clk);
            cycle_count = cycle_count + 1;

            if (!fifo_empty)
                rd_en = 1;
            else
                rd_en = 0;
        end

        $display("Simulation complete.");
        $finish;
    end

    always @(posedge rd_clk) begin
        if (rd_en && !fifo_empty)
            $display("T=%0t  READ: %016h", $time, fifo_dout);
    end

    always @(posedge wr_clk) begin
        if (drop)
            $display("T=%0t  FIFO FULL → DROP", $time);
    end

endmodule
