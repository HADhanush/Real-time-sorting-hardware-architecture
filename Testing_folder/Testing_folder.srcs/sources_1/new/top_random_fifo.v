`timescale 1ns / 1ps

module top_random_fifo (
    input  wire        wr_clk,
    input  wire        rd_clk,

    // Separate ACTIVE-LOW async resets for write/read domains
    input  wire        wrst_n,     // write-domain reset (active-low)
    input  wire        rrst_n,     // read-domain reset  (active-low)

    // Only read enable from outside now
    input  wire        rd_en,      // read enable request  (read domain)

    output wire [63:0] fifo_dout,
    output wire        fifo_empty, // read-domain empty flag from FIFO
    output wire        fifo_full,  // write-domain full flag from FIFO
    output wire        drop        // one-cycle pulse when a word is dropped
);

    // Random generator outputs (write-domain)
    wire [63:0] rnd64;
    wire        valid64;   // THIS IS NOW THE EFFECTIVE wr_en
    wire [63:0] din;

    // FIFO control strobes
    reg         winc;      // write increment (to FIFO)
    reg         rinc;      // read increment  (to FIFO)
    reg         drop_r;    // drop pulse in write domain

    // ------------------------------------------------------------
    // RANDOM GENERATOR (write clock domain, active-low reset)
    // valid64 = "this 64-bit word is ready" → use as FIFO wr_en
    // ------------------------------------------------------------
//    lfsr_random_gen u_random (
//        .clk        (wr_clk),
//        .rst_n      (wrst_n),      // use write-domain reset for RNG
//        .random_out (rnd64),
//        .done       (valid64)      // acts as FIFO wr_en
//    );
    random_gen u_random_diff_freq(
        .clk    (wr_clk),
        .rst    (wrst_n),
        .rnd64  (rnd64),
        .valid64(valid64)
    );

    assign din = rnd64;

    // ------------------------------------------------------------
    // WRITE CLOCK DOMAIN (wr_clk)
    // - winc is 1-cycle pulse when: valid64 & !fifo_full
    // - drop_r pulses when: valid64 & fifo_full
    // ------------------------------------------------------------
    always @(posedge wr_clk or negedge wrst_n) begin
        if (!wrst_n) begin
            winc   <= 1'b0;
            drop_r <= 1'b0;
        end else begin
            // defaults each cycle
            winc   <= 1'b0;
            drop_r <= 1'b0;

            if (valid64) begin              // valid64 is our "write enable"
                if (!fifo_full) begin
                    winc <= 1'b1;          // actually write into FIFO
                end else begin
                    drop_r <= 1'b1;        // FIFO full → drop this word
                end
            end
        end
    end

    // ------------------------------------------------------------
    // READ CLOCK DOMAIN (rd_clk)
    // - rinc is 1-cycle pulse when: rd_en & !fifo_empty
    // ------------------------------------------------------------
    always @(posedge rd_clk or negedge rrst_n) begin
        if (!rrst_n) begin
            rinc <= 1'b0;
        end else begin
            rinc <= rd_en & ~fifo_empty;
        end
    end

    // ------------------------------------------------------------
    // ASYNC FIFO INSTANCE
    // DSIZE = 64 bits, ASIZE = 7 → depth = 2^7 = 128
    // ------------------------------------------------------------
    async_fifo_1 #(
        .DSIZE(64),
        .ASIZE(7)          // adjust if your FIFO uses a different ASIZE
    ) asyncfifomod (
        .rdata (fifo_dout),    // read-domain data out
        .wfull (fifo_full),    // write-domain full
        .rempty(fifo_empty),   // read-domain empty
        .wdata (din),          // write-domain data in
        .winc  (winc),
        .wclk  (wr_clk),
        .wrst_n(wrst_n),       // ACTIVE-LOW write reset
        .rinc  (rinc),
        .rclk  (rd_clk),
        .rrst_n(rrst_n)        // ACTIVE-LOW read reset
    );

    // Expose drop pulse
    assign drop = drop_r;

endmodule
