module tanh (
    input  wire                clk,
    input  wire                rst_n,
    input  wire signed [15:0] x,
    output wire signed [15:0] y
);

    localparam signed [31:0] X_0P5 = 32'sd2048;
    localparam signed [31:0] X_1P0 = 32'sd4096;
    localparam signed [31:0] X_1P5 = 32'sd6144;
    localparam signed [31:0] X_2P0 = 32'sd8192;
    localparam signed [31:0] X_4P0 = 32'sd16384;

    localparam signed [17:0] A0 = 18'sd15143;
    localparam signed [17:0] A1 = 18'sd9813;
    localparam signed [17:0] A2 = 18'sd4704;
    localparam signed [17:0] A3 = 18'sd1929;
    localparam signed [17:0] A4 = 18'sd289;

    localparam signed [31:0] B0 = 32'sd0;
    localparam signed [31:0] B1 = 32'sd666;
    localparam signed [31:0] B2 = 32'sd1943;
    localparam signed [31:0] B3 = 32'sd2984;
    localparam signed [31:0] B4 = 32'sd3804;

    localparam signed [31:0] Y_MAX = 32'sd4093;

    wire signed [31:0] x_ext;
    wire signed [31:0] x_abs;

    assign x_ext = {{16{x[15]}}, x};
    assign x_abs = x_ext[31] ? -x_ext : x_ext;

    reg signed [17:0] a_sel;
    reg signed [31:0] b_sel;
    reg               sat_sel;

    always @(*) begin
        sat_sel = 1'b0;

        if (x_abs >= X_4P0) begin
            a_sel = 18'sd0;
            b_sel = Y_MAX;
            sat_sel = 1'b1;
        end else if (x_abs >= X_2P0) begin
            a_sel = A4;
            b_sel = B4;
        end else if (x_abs >= X_1P5) begin
            a_sel = A3;
            b_sel = B3;
        end else if (x_abs >= X_1P0) begin
            a_sel = A2;
            b_sel = B2;
        end else if (x_abs >= X_0P5) begin
            a_sel = A1;
            b_sel = B1;
        end else begin
            a_sel = A0;
            b_sel = B0;
        end
    end

    wire signed [49:0] mul_full;
    wire signed [31:0] y_abs_calc;
    wire signed [31:0] y_abs;

    assign mul_full = a_sel * x_abs;
    assign y_abs_calc = (mul_full >>> 14) + b_sel;
    assign y_abs = sat_sel ? Y_MAX : y_abs_calc;

    reg signed [15:0] y_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_reg <= 16'sd0;
        end else begin
            if (x_ext[31]) begin
                y_reg <= -y_abs[15:0];
            end else begin
                y_reg <= y_abs[15:0];
            end
        end
    end

    assign y = y_reg;

endmodule