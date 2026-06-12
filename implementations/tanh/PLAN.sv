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
    localparam signed [31:0] X_3P0 = 32'sd12288;

    localparam signed [31:0] Y_0P5 = 32'sd1893;
    localparam signed [31:0] Y_1P0 = 32'sd3119;
    localparam signed [31:0] Y_1P5 = 32'sd3707;
    localparam signed [31:0] Y_2P0 = 32'sd3949;
    localparam signed [31:0] Y_MAX = 32'sd4093;

    wire signed [31:0] x_ext;
    wire signed [31:0] x_abs;

    assign x_ext = {{16{x[15]}}, x};
    assign x_abs = x_ext[31] ? -x_ext : x_ext;

    reg signed [31:0] y_abs;
    reg signed [31:0] dx;

    always @(*) begin
        if (x_abs >= X_3P0) begin
            y_abs = Y_MAX;
        end else if (x_abs >= X_2P0) begin
            dx = x_abs - X_2P0;
            y_abs = Y_2P0 + (dx >>> 5);
        end else if (x_abs >= X_1P5) begin
            dx = x_abs - X_1P5;
            y_abs = Y_1P5 + (dx >>> 3);
        end else if (x_abs >= X_1P0) begin
            dx = x_abs - X_1P0;
            y_abs = Y_1P0 + (dx >>> 2);
        end else if (x_abs >= X_0P5) begin
            dx = x_abs - X_0P5;
            y_abs = Y_0P5 + (dx >>> 1);
        end else begin
            y_abs = x_abs;
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