module wptr_full #(
    parameter ADDR_SIZE = 7                  // 2^7 = 128 locations
)(
    output reg                  wfull,       // Full flag
    output      [ADDR_SIZE-1:0] waddr,       // Write address to memory
    output reg  [ADDR_SIZE:0]   wptr,        // Write pointer (Gray)
    input       [ADDR_SIZE:0]   wq2_rptr,    // Synchronized read pointer (Gray) in write clock domain
    input                       winc,        // Write increment
    input                       wclk,        // Write clock
    input                       wrst_n       // Active-low async reset
);

    reg  [ADDR_SIZE:0] wbin;                 // Binary write pointer
    wire [ADDR_SIZE:0] wgray_next;           // Next write pointer (Gray)
    wire [ADDR_SIZE:0] wbin_next;            // Next write pointer (binary)
    wire               wfull_val;            // Next full flag value

    // Binary & Gray write pointers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)                         // Active-low reset
            {wbin, wptr} <= { (ADDR_SIZE+1+ADDR_SIZE+1){1'b0} };
        else
            {wbin, wptr} <= {wbin_next, wgray_next};
    end

    // Write address from binary pointer
    assign waddr     = wbin[ADDR_SIZE-1:0];

    // Increment binary pointer when write enabled and not full
    assign wbin_next = wbin + (winc & ~wfull);

    // Binary to Gray conversion
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;

    // Full when next Gray write pointer equals read pointer with MSBs inverted
    assign wfull_val =
        (wgray_next == {~wq2_rptr[ADDR_SIZE:ADDR_SIZE-1], wq2_rptr[ADDR_SIZE-2:0]});

    // Full flag register
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wfull <= 1'b0;                   // Not full after reset
        else
            wfull <= wfull_val;
    end

endmodule
