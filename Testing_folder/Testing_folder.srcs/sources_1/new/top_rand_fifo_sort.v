`timescale 1ns / 1ps

module top_rand_fifo_sort(
    input  wire        wr_clk,
    input  wire        rd_clk,
    input  wire        reset,
    output reg  [63:0] sort_out,
    output reg         done
);

    reg                 rd_en;
    wire [63:0]         fifo_out;
    wire                fifo_empty;
    wire                fifo_full;
    wire                drop;

    top_random_fifo u_top_random_fifo (
        .wr_clk    (wr_clk),
        .rd_clk    (rd_clk),
        .rst       (reset),
        .rd_en     (rd_en),
        .fifo_dout (fifo_out),
        .fifo_empty(fifo_empty),
        .fifo_full (fifo_full),
        .drop      (drop)
    );

    localparam N = 8;
    localparam WIDTH = 8;

    reg  [N*WIDTH-1:0] sorter_data_in;
    reg                sorter_data_valid;
    wire [N*WIDTH-1:0] sorter_sorted;
    wire               sorter_sdone;

    insertion_sort #(
        .N(N),
        .WIDTH(WIDTH)
    ) u_insertion_sort (
        .clk        (rd_clk),
        .rst        (reset),
        .data_valid (sorter_data_valid),
        .data_in    (sorter_data_in),
        .sorted     (sorter_sorted),
        .sdone      (sorter_sdone)
    );

    reg fifo_empty_d, fifo_empty_d2;
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            fifo_empty_d  <= 1'b1;
            fifo_empty_d2 <= 1'b1;
        end else begin
            fifo_empty_d2 <= fifo_empty_d;
            fifo_empty_d  <= fifo_empty;
        end
    end

    wire fifo_went_nonempty = (fifo_empty_d2 == 1'b1 && fifo_empty_d == 1'b0);

    reg [1:0] state;
    localparam S_IDLE  = 2'd0;
    localparam S_PULSE = 2'd1;
    localparam S_WAIT  = 2'd2;

    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            rd_en <= 1'b0;
            sorter_data_valid <= 1'b0;
            sorter_data_in <= 64'b0;
            sort_out <= 64'b0;
            done <= 1'b0;
        end
        else begin
            rd_en <= 1'b0;
            sorter_data_valid <= 1'b0;
            done <= 1'b0;

            case (state)

                // --------------------------
                // INITIAL PUSH
                // --------------------------
                S_IDLE: begin
                    if (sorter_sdone && !fifo_empty) begin
                        rd_en <= 1'b1;
                        sorter_data_in <= fifo_out;
                        state <= S_PULSE;
                    end
                    else if (fifo_went_nonempty) begin
                        rd_en <= 1'b1;
                        sorter_data_in <= fifo_out;
                        state <= S_PULSE;
                    end
                end

                // Send data_valid to sorter
                S_PULSE: begin
                    rd_en <= 1'b0;
                    sorter_data_valid <= 1'b1;
                    state <= S_WAIT;
                end

                // Wait for sorter to finish
                S_WAIT: begin
                    if (sorter_sdone) begin
                        sort_out <= sorter_sorted;
                        done <= 1'b1;
                        state <= S_IDLE;
                    end
                    else state <= S_WAIT;
                end
            endcase
        end
    end

endmodule
