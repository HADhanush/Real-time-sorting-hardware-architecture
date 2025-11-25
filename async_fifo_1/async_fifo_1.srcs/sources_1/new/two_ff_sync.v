module two_ff_sync #(
    parameter SIZE = 8               // width of the signal to synchronize
)(
    output reg [SIZE-1:0] q2,        // synchronized output
    input      [SIZE-1:0] din,       // async input from other clock domain
    input                  clk,      // local clock
    input                  rst_n     // ACTIVE-LOW async reset
);

    reg [SIZE-1:0] q1;               // first stage FF

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {q2, q1} <= {2*SIZE{1'b0}};  // clear both stages
        else
            {q2, q1} <= {q1, din};       // shift din → q1 → q2
    end

endmodule
