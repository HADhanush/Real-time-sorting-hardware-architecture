`timescale 1ns / 1ps

module insertion_sort #(
    parameter N = 8,
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 data_valid,     // ONLY trigger to start sorting
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state  <= IDLE;
            sdone  <= 0;
            i      <= 0;
            j      <= 0;
            key    <= 0;
            sorted <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    sdone <= 0;
                    if (data_valid) begin
                        for (i = 0; i < N; i = i + 1)
                            arr[i] <= data_in[i*WIDTH +: WIDTH];
                        i <= 1;
                        state <= PICK;
                    end
                end

                PICK: begin
                    if (i < N) begin
                        key <= arr[i];
                        j   <= i - 1;
                        state <= COMPARE;
                    end else begin
                        state <= FINISH;
                    end
                end

                COMPARE: begin
                    if (j >= 0 && arr[j] > key) begin
                        arr[j+1] <= arr[j];
                        j <= j - 1;
                    end
                    else begin
                        state <= INSERT;
                    end
                end

                INSERT: begin
                    arr[j+1] <= key;
                    i <= i + 1;
                    state <= PICK;
                end

                FINISH: begin
                    for (j = 0; j < N; j = j + 1)
                        sorted[j*WIDTH +: WIDTH] <= arr[j];
                    sdone <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
