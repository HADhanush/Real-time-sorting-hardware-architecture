module rptr_empty #(
    parameter ADDR_SIZE = 7                    // 2^7 = 128 locations
)(
    output reg                  rempty,        // Empty flag
    output      [ADDR_SIZE-1:0] raddr,         // Read address (to memory)
    output reg  [ADDR_SIZE:0]   rptr,          // Read pointer (Gray code)
    input       [ADDR_SIZE:0]   rq2_wptr,      // Synchronized write pointer (Gray) in read clock domain
    input                       rinc,          // Read increment
    input                       rclk,          // Read clock
    input                       rrst_n         // Active-low async reset
);

    reg  [ADDR_SIZE:0] rbin;                   // Binary read pointer
    wire [ADDR_SIZE:0] rgray_next;             // Next read pointer (Gray)
    wire [ADDR_SIZE:0] rbin_next;              // Next read pointer (binary)
    wire               rempty_val;             // Next empty flag value

    // Binary & Gray read pointers
    // Active-low async reset, synchronous release
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)                           // Reset -> clear pointers
            {rbin, rptr} <= { (ADDR_SIZE+1+ADDR_SIZE+1){1'b0} };
        else
            {rbin, rptr} <= {rbin_next, rgray_next};
    end

    // Read address comes from lower bits of binary pointer
    assign raddr     = rbin[ADDR_SIZE-1:0];

    // Increment binary pointer when rinc is asserted and FIFO not empty
    assign rbin_next = rbin + (rinc & ~rempty);

    // Binary to Gray conversion
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    // Empty when next Gray read pointer equals synchronized Gray write pointer
    assign rempty_val = (rgray_next == rq2_wptr);

    // Empty flag register
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty <= 1'b1;                    // FIFO is empty after reset
        else
            rempty <= rempty_val;
    end

endmodule
