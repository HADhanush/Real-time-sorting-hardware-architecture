module FIFO_memory #(
    parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 7                 // 2^7 = 128 locations
)(
    output [DATA_SIZE-1:0] rdata,           // Output data - data to be read
    input  [DATA_SIZE-1:0] wdata,           // Input data - data to be written
    input  [ADDR_SIZE-1:0] waddr, raddr,    // Write and read address
    input                  wclk_en,         // Write clock enable
    input                  wfull,           // Write full flag
    input                  wclk             // Write clock
);

    localparam DEPTH = 1 << ADDR_SIZE;      // Depth of the FIFO memory = 128
    reg [DATA_SIZE-1:0] mem [0:DEPTH-1];    // Memory array

    // Asynchronous read using raddr
    assign rdata = mem[raddr];

    // Synchronous write using wclk
    always @(posedge wclk) begin
        if (wclk_en && !wfull)
            mem[waddr] <= wdata;
    end

endmodule
