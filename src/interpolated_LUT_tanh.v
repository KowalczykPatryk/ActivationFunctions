module tanh_lut #(
    parameter AW = 10, 
    parameter DW = 16,
    parameter N = 16,
    parameter Q = 12
    )(
    input clk,
    input [N-1:0] phase,
    output [DW-1:0] tanh
    );

    reg [9:0] addra_reg;
    reg [9:0] addrb_reg;
    wire [15:0] tanha;
    wire [15:0] tanhb;
    wire ovr1,ovr2;

    wire [15:0] frac,one_minus_frac;
    wire [15:0] A1,A2;
    wire [15:0] one;
    wire [DW-1:0] tanh_temp;


    (* ram_style = "block" *)reg [15:0] mem [1<<10-1:0];
    initial 
    begin
        $readmemb("tanh_data.mem",mem);
    end
    always@(posedge clk)
    begin
        addra_reg <= phase[9:0];
        addrb_reg <= phase[9:0] + 1'b1;
    end
    assign tanha = mem[addra_reg];
    assign tanhb = mem[addrb_reg];
    assign frac = {'d0,phase[N-AW-'d2-1:0]};
    assign one = 16'b0001000000000000;
    assign one_minus_frac = one - frac;
    qmult #(N,Q) mul1 (tanha,frac,A1,ovr1);
    qmult #(N,Q) mul2 (tanhb,one_minus_frac,A2,ovr2);
    assign tanh_temp = A1 + A2;
    assign tanh = (phase [N-1]) ? (phase[N-2] ? (16'b1111000000000000) : (~tanh_temp + 1'b1)) :(phase[N-2] ? (16'b0001000000000000):(tanh_temp));

endmodule