`timescale 1ns / 1ps

module top_rand_fifo_sort(
    input  wire        wr_clk,
    input  wire        rd_clk,
    input  wire        wrst_n,        // write-domain ACTIVE-LOW reset
    input  wire        rrst_n,        // read-domain  ACTIVE-LOW reset
    output reg  [63:0] sort_out,
    output reg         done
);

    // -------------------------------------
    // FIFO interface
    // -------------------------------------
    reg                 rd_en;        // read enable to FIFO (rd_clk domain)
    wire [63:0]         fifo_out;
    wire                fifo_empty;
    wire                fifo_full;
    wire                drop;

    // top_random_fifo now has: wrst_n, rrst_n, rd_en
    // Write enable is driven INTERNALLY by valid64 from the random generator.
    top_random_fifo u_top_random_fifo (
        .wr_clk    (wr_clk),
        .rd_clk    (rd_clk),
        .wrst_n    (wrst_n),
        .rrst_n    (rrst_n),
        .rd_en     (rd_en),       // controlled by state machine below
        .fifo_dout (fifo_out),
        .fifo_empty(fifo_empty),
        .fifo_full (fifo_full),
        .drop      (drop)
    );

    // -------------------------------------
    // Insertion sort instance (read domain)
    // -------------------------------------
    localparam N     = 8;
    localparam WIDTH = 8;

    reg  [N*WIDTH-1:0] sorter_data_in;
    reg                sorter_data_valid;
    wire [N*WIDTH-1:0] sorter_sorted;
    wire               sorter_sdone;

    insertion_sort #(
        .N    (N),
        .WIDTH(WIDTH)
    ) u_insertion_sort (
        .rd_clk    (rd_clk),
        .rrst_n    (rrst_n),           // ACTIVE-LOW reset (read domain)
        .data_valid(sorter_data_valid),
        .data_in   (sorter_data_in),
        .sorted    (sorter_sorted),
        .sdone     (sorter_sdone)
    );

    // -------------------------------------
    // Detect FIFO going from empty -> nonempty (read domain)
    // -------------------------------------
    reg fifo_empty_d, fifo_empty_d2;

    always @(posedge rd_clk or negedge rrst_n) begin
        if (!rrst_n) begin
            fifo_empty_d  <= 1'b1;
            fifo_empty_d2 <= 1'b1;
        end else begin
            fifo_empty_d2 <= fifo_empty_d;
            fifo_empty_d  <= fifo_empty;
        end
    end

    wire fifo_went_nonempty = (fifo_empty_d2 == 1'b1 && fifo_empty_d == 1'b0);

    // -------------------------------------
    // Simple FSM in read domain to:
    //  - request a read from FIFO
    //  - feed that word into sorter
    //  - wait for sort to complete
    // -------------------------------------
    reg [1:0] state;
    localparam S_IDLE  = 2'd0;
    localparam S_PULSE = 2'd1;
    localparam S_WAIT  = 2'd2;

    always @(posedge rd_clk or negedge rrst_n) begin
        if (!rrst_n) begin
            state             <= S_IDLE;
            rd_en             <= 1'b0;
            sorter_data_valid <= 1'b0;
            sorter_data_in    <= {N*WIDTH{1'b0}};
            sort_out          <= 64'b0;
            done              <= 1'b0;
        end
        else begin
            // defaults each cycle
            rd_en             <= 1'b0;
            sorter_data_valid <= 1'b0;
            done              <= 1'b0;

            case (state)

                // --------------------------
                // INITIAL / IDLE
                // --------------------------
                S_IDLE: begin
                    // If sorter just finished AND FIFO still has data, fetch next word
                    if (done && !fifo_empty) begin
                        rd_en          <= 1'b1;    // one-cycle read request
                        sorter_data_in <= fifo_out;
                        state          <= S_PULSE;
                    end
                    // Or: when FIFO transitions from empty -> nonempty (first word)
                    else if (fifo_went_nonempty) begin
                        rd_en          <= 1'b1;
                        sorter_data_in <= fifo_out;
                        state          <= S_PULSE;
                    end
                end

                // --------------------------
                // Pulse data_valid to sorter
                // --------------------------
                S_PULSE: begin
                    // rd_en was asserted in previous cycle; now present the word to sorter
                    sorter_data_valid <= 1'b1;    // one-cycle pulse
                    state             <= S_WAIT;
                end

                // --------------------------
                // Wait for sorter to finish
                // --------------------------
                S_WAIT: begin
                    if (sorter_sdone) begin
                        sort_out <= sorter_sorted;
                        done     <= 1'b1;         // one-cycle done pulse
                        state    <= S_IDLE;
                    end
                    else begin
                        state <= S_WAIT;
                    end
                end

            endcase
        end
    end

endmodule
