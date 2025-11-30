`timescale 1ns / 1ps

module random_gen(
    input  wire        clk,
    input  wire        rst,
    output reg  [63:0] rnd64,
    output reg         valid64
);

    reg  [7:0] lfsr_byte;
    wire [7:0] lfsr_byte_next;
    wire       fb_byte;
    assign fb_byte = lfsr_byte[7] ^ lfsr_byte[5] ^ lfsr_byte[4] ^ lfsr_byte[3];
    assign lfsr_byte_next = { lfsr_byte[6:0], fb_byte };

    reg  [7:0] dlfsr;
    wire [7:0] dlfsr_next;
    assign dlfsr_next = { dlfsr[6:0], dlfsr[7] ^ dlfsr[5] ^ dlfsr[3] ^ dlfsr[2] };

    reg  [4:0] delay_val;
    reg [7:0] byte_array [0:6];
    reg [2:0] byte_index;
    reg [4:0] delay_cnt;

    wire sample_enable = (delay_cnt == 5'd0);

    // LFSR and delay value update on NEGATIVE edge
    always @(posedge clk , negedge rst) begin
        if (!rst) begin
            lfsr_byte <= 8'h01;
            dlfsr     <= 8'hA5;
            delay_val <= 5'd4;
        end
        else begin
            if (sample_enable) begin
                dlfsr     <= dlfsr_next;
                lfsr_byte <= lfsr_byte_next;
                if ((dlfsr_next[3:0] ^ dlfsr_next[7:4]) == 4'd0)
                    delay_val <= 5'd8;
                else
                    delay_val <= {1'b0, (dlfsr_next[3:0] ^ dlfsr_next[7:4])};
            end
        end
    end

    // Byte collection and rnd64 / valid64 generation on NEGATIVE edge
    always @(posedge clk,negedge rst) begin
        if (!rst) begin
            byte_index <= 3'd0;
            delay_cnt  <= 5'd1;
            rnd64      <= 64'd0;
            valid64    <= 1'b0;
        end
        else begin
            valid64 <= 1'b0;
            if (delay_cnt == 5'd0) begin
                if (byte_index == 3'd7) begin
                    rnd64 <= {
                        lfsr_byte,
                        byte_array[6],
                        byte_array[5],
                        byte_array[4],
                        byte_array[3],
                        byte_array[2],
                        byte_array[1],
                        byte_array[0]
                    };
                    valid64    <= 1'b1;
                    byte_index <= 3'd0;
                end
                else begin
                    byte_array[byte_index] <= lfsr_byte;
                    byte_index             <= byte_index + 3'd1;
                end

                if (delay_val < 2)
                    delay_cnt <= 5'd1;
                else
                    delay_cnt <= delay_val - 5'd1;
            end
            else begin
                delay_cnt <= delay_cnt - 5'd1;
            end
        end
    end

endmodule
