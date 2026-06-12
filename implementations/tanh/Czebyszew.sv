module tanh (
    input  wire                clk,
    input  wire                rst_n,
    input  wire signed [15:0] x,
    output wire signed [15:0] y
);

    localparam IW = 22;

    localparam signed [15:0] X_POS = 16'sd16384;
    localparam signed [15:0] X_NEG = -16'sd16384;

    localparam signed [21:0] U_POS = 22'sd4096;
    localparam signed [21:0] U_NEG = -22'sd4096;

    localparam signed [17:0] C1 = 18'sd20657;
    localparam signed [17:0] C3 = -18'sd5108;
    localparam signed [17:0] C5 = 18'sd2833;

    localparam signed [31:0] Y_POS = 32'sd4096;
    localparam signed [31:0] Y_NEG = -32'sd4096;

    wire signed [IW-1:0] x_q12;
    reg  signed [IW-1:0] u_q12;

    assign x_q12 = {{6{x[15]}}, x};

    always @(*) begin
        if (x >= X_POS) begin
            u_q12 = U_POS;
        end else if (x <= X_NEG) begin
            u_q12 = U_NEG;
        end else begin
            u_q12 = x_q12 >>> 2;
        end
    end

    wire signed [43:0] u2_full;
    wire signed [IW-1:0] u2_q12;

    assign u2_full = u_q12 * u_q12;
    assign u2_q12 = u2_full >>> 12;

    wire signed [43:0] u3_full;
    wire signed [IW-1:0] u3_q12;

    assign u3_full = u2_q12 * u_q12;
    assign u3_q12 = u3_full >>> 12;

    wire signed [43:0] u5_full;
    wire signed [IW-1:0] u5_q12;

    assign u5_full = u3_q12 * u2_q12;
    assign u5_q12 = u5_full >>> 12;

    wire signed [31:0] t1_q12;
    wire signed [31:0] t3_q12;
    wire signed [31:0] t5_q12;

    assign t1_q12 = u_q12;

    assign t3_q12 = (u3_q12 <<< 2)
                  - (u_q12 <<< 1)
                  -  u_q12;

    assign t5_q12 = (u5_q12 <<< 4)
                  - (u3_q12 <<< 4)
                  - (u3_q12 <<< 2)
                  + (u_q12 <<< 2)
                  +  u_q12;

    wire signed [49:0] p1_full;
    wire signed [49:0] p3_full;
    wire signed [49:0] p5_full;

    assign p1_full = t1_q12 * C1;
    assign p3_full = t3_q12 * C3;
    assign p5_full = t5_q12 * C5;

    wire signed [31:0] p1_q12;
    wire signed [31:0] p3_q12;
    wire signed [31:0] p5_q12;

    assign p1_q12 = p1_full >>> 14;
    assign p3_q12 = p3_full >>> 14;
    assign p5_q12 = p5_full >>> 14;

    wire signed [31:0] y_poly_q12;

    assign y_poly_q12 = p1_q12 + p3_q12 + p5_q12;

    reg signed [15:0] y_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_reg <= 16'sd0;
        end else begin
            if (y_poly_q12 > Y_POS) begin
                y_reg <= 16'sd4096;
            end else if (y_poly_q12 < Y_NEG) begin
                y_reg <= -16'sd4096;
            end else begin
                y_reg <= y_poly_q12[15:0];
            end
        end
    end

    assign y = y_reg;

endmodule