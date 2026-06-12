module tanh (
    input  wire                clk,
    input  wire                rst_n,
    input  wire signed [15:0] x,
    output wire signed [15:0] y
);

    localparam signed [31:0] X_1P0 = 32'sd4096;
    localparam signed [31:0] X_2P0 = 32'sd8192;
    localparam signed [31:0] X_4P0 = 32'sd16384;

    localparam signed [17:0] A0 = -18'sd5329;
    localparam signed [17:0] B0 =  18'sd17807;
    localparam signed [31:0] C0 =  32'sd0;

    localparam signed [17:0] A1 = -18'sd2775;
    localparam signed [17:0] B1 =  18'sd11641;
    localparam signed [31:0] C1 =  32'sd903;

    localparam signed [17:0] A2 = -18'sd219;
    localparam signed [17:0] B2 =  18'sd1604;
    localparam signed [31:0] C2 =  32'sd3366;

    localparam signed [31:0] Y_MAX = 32'sd4093;
    localparam signed [31:0] Y_MIN = 32'sd0;

    wire signed [31:0] x_ext;
    wire signed [31:0] x_abs;

    assign x_ext = {{16{x[15]}}, x};
    assign x_abs = x_ext[31] ? -x_ext : x_ext;

    reg signed [17:0] a_sel;
    reg signed [17:0] b_sel;
    reg signed [31:0] c_sel;
    reg               sat_sel;

    always @(*) begin
        sat_sel = 1'b0;

        if (x_abs >= X_4P0) begin
            a_sel = 18'sd0;
            b_sel = 18'sd0;
            c_sel = Y_MAX;
            sat_sel = 1'b1;
        end else if (x_abs >= X_2P0) begin
            a_sel = A2;
            b_sel = B2;
            c_sel = C2;
        end else if (x_abs >= X_1P0) begin
            a_sel = A1;
            b_sel = B1;
            c_sel = C1;
        end else begin
            a_sel = A0;
            b_sel = B0;
            c_sel = C0;
        end
    end

    wire signed [63:0] x2_full;
    wire signed [31:0] x2_q12;

    assign x2_full = x_abs * x_abs;
    assign x2_q12 = x2_full >>> 12;

    wire signed [49:0] ax2_full;
    wire signed [49:0] bx_full;

    wire signed [31:0] ax2_q12;
    wire signed [31:0] bx_q12;

    assign ax2_full = a_sel * x2_q12;
    assign bx_full  = b_sel * x_abs;

    assign ax2_q12 = ax2_full >>> 14;
    assign bx_q12  = bx_full  >>> 14;

    wire signed [31:0] y_poly;
    reg  signed [31:0] y_abs;

    assign y_poly = ax2_q12 + bx_q12 + c_sel;

    always @(*) begin
        if (sat_sel) begin
            y_abs = Y_MAX;
        end else if (y_poly > Y_MAX) begin
            y_abs = Y_MAX;
        end else if (y_poly < Y_MIN) begin
            y_abs = Y_MIN;
        end else begin
            y_abs = y_poly;
        end
    end

    reg signed [15:0] y_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_reg <= 16'sd0;
        end else begin
            if (x_ext[31]) begin
                y_reg <= -$signed(y_abs[15:0]);
            end else begin
                y_reg <= $signed(y_abs[15:0]);
            end
        end
    end

    assign y = y_reg;

endmodule