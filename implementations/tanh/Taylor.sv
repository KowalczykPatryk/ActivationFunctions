module tanh (
    input  wire                clk,
    input  wire                rst_n,
    input  wire signed [15:0] x,
    output wire signed [15:0] y
);

    localparam signed [31:0] ONE_Q12 = 32'sd4096;
    localparam signed [31:0] POS_MAX = 32'sd4096;
    localparam signed [31:0] NEG_MAX = -32'sd4096;

    wire signed [31:0] x_q12;
    assign x_q12 = {{16{x[15]}}, x};

    wire signed [63:0] x2_full;
    wire signed [31:0] x2_q12;

    assign x2_full = x_q12 * x_q12;
    assign x2_q12 = x2_full >>> 12;

    wire signed [63:0] x4_full;
    wire signed [31:0] x4_q12;

    assign x4_full = x2_q12 * x2_q12;
    assign x4_q12 = x4_full >>> 12;

    wire signed [31:0] term_q12;

    assign term_q12 = ONE_Q12
                    - (x2_q12 / 3)
                    + ((x4_q12 * 2) / 15);

    wire signed [63:0] y_full;
    wire signed [31:0] y_poly_q12;

    assign y_full = x_q12 * term_q12;
    assign y_poly_q12 = y_full >>> 12;

    reg signed [15:0] y_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_reg <= 16'sd0;
        end else begin
            if (y_poly_q12 > POS_MAX) begin
                y_reg <= 16'sd4096;
            end else if (y_poly_q12 < NEG_MAX) begin
                y_reg <= -16'sd4096;
            end else begin
                y_reg <= y_poly_q12[15:0];
            end
        end
    end

    assign y = y_reg;

endmodule