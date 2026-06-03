module tanh_lut #(
    parameter AW = 10,
    parameter DW = 16,
    parameter N = 16,
    parameter Q = 12
    )(
    input clk,
    input [AW-1:0] phase,
    output [DW-1:0] tanh
    );
    reg [AW-1:0] addr_reg;
(* ram_style = "block" *)reg [DW-1:0] mem [1<<AW-1:0];
initial 
begin
    $readmemb("tanh_data.mem",mem);
end

always@(posedge clk)
begin
    addr_reg <= phase[AW-1:0];
end

assign tanh = mem[addr_reg];