module relu (din_relu, dout_relu);

input  [31:0] din_relu;
output [31:0] dout_relu;

assign dout_relu = din_relu[31] ? 32'd0 : din_relu;

endmodule