`timescale 1ns/1ps
module relu (
    input wire signed [31:0] din_relu,
    output wire signed [31:0] dout_relu
);
    assign dout_relu = (din_relu < 0) ? 32'b0 : din_relu;
endmodule