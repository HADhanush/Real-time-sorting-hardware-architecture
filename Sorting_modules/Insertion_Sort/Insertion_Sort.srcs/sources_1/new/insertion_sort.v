`timescale 1ns / 1ps

module insertion_sort #(
    parameter N     = 8,
    parameter WIDTH = 8
)(
    input  wire                 rd_clk,      // read clock
    input  wire                 rrst_n,      // ACTIVE-LOW async reset
    input  wire                 data_valid,  // trigger to start sorting
    input  wire [N*WIDTH-1:0]   data_in,
    output reg  [N*WIDTH-1:0]   sorted,
    output reg                  sdone
);

    reg [WIDTH-1:0] arr [0:N-1];
    reg [WIDTH-1:0] key;
    integer i, j;

    localparam
        IDLE    = 3'b000,
        LOAD    = 3'b001,
        PICK    = 3'b010,
        COMPARE = 3'b011,
        INSERT  = 3'b100,
        FINISH  = 3'b101;

    reg [2:0] state;

    // Async, active-low reset, synchronous to rd_clk
    always @(posedge rd_clk or negedge rrst_n) begin
        if (!rrst_n) begin
            state  <= IDLE;
            sdone  <= 1'b0;
            i      <= 0;
            j      <= 0;
            key    <= {WIDTH{1'b0}};
            sorted <= {N*WIDTH{1'b0}};
        end
        else begin
            case (state)

                IDLE: begin
                    sdone <= 1'b0;
                    if (data_valid) begin
                        // load input vector into array
                        for (i = 0; i < N; i = i + 1)
                            arr[i] <= data_in[i*WIDTH +: WIDTH];
                        i     <= 1;
                        state <= PICK;
                    end
                end

                PICK: begin
                    if (i < N) begin
                        key   <= arr[i];
                        j     <= i - 1;
                        state <= COMPARE;
                    end
                    else begin
                        state <= FINISH;
                    end
                end

                COMPARE: begin
                    if (j >= 0 && arr[j] > key) begin
                        arr[j+1] <= arr[j];
                        j        <= j - 1;
                    end
                    else begin
                        state <= INSERT;
                    end
                end

                INSERT: begin
                    arr[j+1] <= key;
                    i        <= i + 1;
                    state    <= PICK;
                end

                FINISH: begin
                    for (j = 0; j < N; j = j + 1)
                        sorted[j*WIDTH +: WIDTH] <= arr[j];
                    sdone <= 1'b1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
