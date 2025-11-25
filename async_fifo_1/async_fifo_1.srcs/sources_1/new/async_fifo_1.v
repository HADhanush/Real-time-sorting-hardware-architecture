module async_fifo_1 #(
    parameter DSIZE = 8,           // Data width
    parameter ASIZE = 7            // Address width -> depth = 2^ASIZE = 128
)(
    output [DSIZE-1:0] rdata,      // Output data - data to be read
    output              wfull,     // Write full signal
    output              rempty,    // Read empty signal
    input  [DSIZE-1:0]  wdata,     // Input data - data to be written
    input               winc,      // Write increment (Write enable)
    input               wclk,      // Write clock
    input               wrst_n,    // Write reset (active-low)
    input               rinc,      // Read increment (Read enable)
    input               rclk,      // Read clock
    input               rrst_n     // Read reset (active-low)
);

    // Address and pointer widths
    wire [ASIZE-1:0] waddr, raddr;       // addr = ASIZE bits (0..127)
    wire [ASIZE:0]   wptr, rptr;         // pointers = ASIZE+1 bits (Gray/binary)
    wire [ASIZE:0]   wq2_rptr, rq2_wptr; // synchronized pointers

    // Read pointer synchronized into write clock domain
    two_ff_sync #(
        .SIZE(ASIZE+1)
    ) sync_r2w (
        .q2   (wq2_rptr),
        .din  (rptr),
        .clk  (wclk),
        .rst_n(wrst_n)
    );

    // Write pointer synchronized into read clock domain
    two_ff_sync #(
        .SIZE(ASIZE+1)
    ) sync_w2r (
        .q2   (rq2_wptr),
        .din  (wptr),
        .clk  (rclk),
        .rst_n(rrst_n)
    );

    // FIFO memory: depth = 2^ASIZE = 128
    FIFO_memory #(
        .DATA_SIZE(DSIZE),
        .ADDR_SIZE(ASIZE)
    ) fifomem (
        .rdata  (rdata),
        .wdata  (wdata),
        .waddr  (waddr),
        .raddr  (raddr),
        .wclk_en(winc),
        .wfull  (wfull),
        .wclk   (wclk)
    );

    // Read-side pointer and empty logic
    rptr_empty #(
        .ADDR_SIZE(ASIZE)
    ) u_rptr_empty (
        .rempty  (rempty),
        .raddr   (raddr),
        .rptr    (rptr),
        .rq2_wptr(rq2_wptr),
        .rinc    (rinc),
        .rclk    (rclk),
        .rrst_n  (rrst_n)
    );

    // Write-side pointer and full logic
    wptr_full #(
        .ADDR_SIZE(ASIZE)
    ) u_wptr_full (
        .wfull   (wfull),
        .waddr   (waddr),
        .wptr    (wptr),
        .wq2_rptr(wq2_rptr),
        .winc    (winc),
        .wclk    (wclk),
        .wrst_n  (wrst_n)
    );

endmodule
