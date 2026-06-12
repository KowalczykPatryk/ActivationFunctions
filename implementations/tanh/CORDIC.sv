module tanh (
    input  wire                clk,
    input  wire                rst_n,
    input  wire signed [15:0] x,
    output wire signed [15:0] y
);

    localparam IW = 22;

    localparam signed [IW-1:0] ONE_Q16 = 22'sh10000;

    localparam signed [IW-1:0] ATANH_1 = 22'sh08CA0;
    localparam signed [IW-1:0] ATANH_2 = 22'sh0416A;

    localparam signed [IW-1:0] STEP_1 = 22'sh08000;
    localparam signed [IW-1:0] STEP_2 = 22'sh04000;
    localparam signed [IW-1:0] STEP_3 = 22'sh02000;
    localparam signed [IW-1:0] STEP_4 = 22'sh01000;
    localparam signed [IW-1:0] STEP_5 = 22'sh00800;
    localparam signed [IW-1:0] STEP_6 = 22'sh00400;
    localparam signed [IW-1:0] STEP_7 = 22'sh00200;
    localparam signed [IW-1:0] STEP_8 = 22'sh00100;

    wire signed [IW-1:0] x_q16;

    assign x_q16 = { {(IW-16){x[15]}}, x } <<< 4;

    wire signed [IW-1:0] h0_x;
    wire signed [IW-1:0] h0_y;
    wire signed [IW-1:0] h0_z;

    wire signed [IW-1:0] h1_x;
    wire signed [IW-1:0] h1_y;
    wire signed [IW-1:0] h1_z;

    wire signed [IW-1:0] h2_x;
    wire signed [IW-1:0] h2_y;
    wire signed [IW-1:0] h2_z;

    wire signed [IW-1:0] h3_x;
    wire signed [IW-1:0] h3_y;
    wire signed [IW-1:0] h3_z;

    wire signed [IW-1:0] h4_x;
    wire signed [IW-1:0] h4_y;
    wire signed [IW-1:0] h4_z;

    wire signed [IW-1:0] h5_x;
    wire signed [IW-1:0] h5_y;
    wire signed [IW-1:0] h5_z;

    wire signed [IW-1:0] h6_x;
    wire signed [IW-1:0] h6_y;
    wire signed [IW-1:0] h6_z;

    wire signed [IW-1:0] h7_x;
    wire signed [IW-1:0] h7_y;
    wire signed [IW-1:0] h7_z;

    wire signed [IW-1:0] h8_x;
    wire signed [IW-1:0] h8_y;

    assign h0_x = ONE_Q16;
    assign h0_y = 22'sd0;
    assign h0_z = x_q16;

    assign h1_x = h0_z[IW-1] ? h0_x - (h0_y >>> 1) : h0_x + (h0_y >>> 1);
    assign h1_y = h0_z[IW-1] ? h0_y - (h0_x >>> 1) : h0_y + (h0_x >>> 1);
    assign h1_z = h0_z[IW-1] ? h0_z + ATANH_1 : h0_z - ATANH_1;

    assign h2_x = h1_z[IW-1] ? h1_x - (h1_y >>> 1) : h1_x + (h1_y >>> 1);
    assign h2_y = h1_z[IW-1] ? h1_y - (h1_x >>> 1) : h1_y + (h1_x >>> 1);
    assign h2_z = h1_z[IW-1] ? h1_z + ATANH_1 : h1_z - ATANH_1;

    assign h3_x = h2_z[IW-1] ? h2_x - (h2_y >>> 1) : h2_x + (h2_y >>> 1);
    assign h3_y = h2_z[IW-1] ? h2_y - (h2_x >>> 1) : h2_y + (h2_x >>> 1);
    assign h3_z = h2_z[IW-1] ? h2_z + ATANH_1 : h2_z - ATANH_1;

    assign h4_x = h3_z[IW-1] ? h3_x - (h3_y >>> 1) : h3_x + (h3_y >>> 1);
    assign h4_y = h3_z[IW-1] ? h3_y - (h3_x >>> 1) : h3_y + (h3_x >>> 1);
    assign h4_z = h3_z[IW-1] ? h3_z + ATANH_1 : h3_z - ATANH_1;

    assign h5_x = h4_z[IW-1] ? h4_x - (h4_y >>> 1) : h4_x + (h4_y >>> 1);
    assign h5_y = h4_z[IW-1] ? h4_y - (h4_x >>> 1) : h4_y + (h4_x >>> 1);
    assign h5_z = h4_z[IW-1] ? h4_z + ATANH_1 : h4_z - ATANH_1;

    assign h6_x = h5_z[IW-1] ? h5_x - (h5_y >>> 1) : h5_x + (h5_y >>> 1);
    assign h6_y = h5_z[IW-1] ? h5_y - (h5_x >>> 1) : h5_y + (h5_x >>> 1);
    assign h6_z = h5_z[IW-1] ? h5_z + ATANH_1 : h5_z - ATANH_1;

    assign h7_x = h6_z[IW-1] ? h6_x - (h6_y >>> 1) : h6_x + (h6_y >>> 1);
    assign h7_y = h6_z[IW-1] ? h6_y - (h6_x >>> 1) : h6_y + (h6_x >>> 1);
    assign h7_z = h6_z[IW-1] ? h6_z + ATANH_1 : h6_z - ATANH_1;

    assign h8_x = h7_z[IW-1] ? h7_x - (h7_y >>> 2) : h7_x + (h7_y >>> 2);
    assign h8_y = h7_z[IW-1] ? h7_y - (h7_x >>> 2) : h7_y + (h7_x >>> 2);

    wire signed [IW-1:0] d0_x;
    wire signed [IW-1:0] d0_y;
    wire signed [IW-1:0] d0_z;

    wire signed [IW-1:0] d1_y;
    wire signed [IW-1:0] d1_z;

    wire signed [IW-1:0] d2_y;
    wire signed [IW-1:0] d2_z;

    wire signed [IW-1:0] d3_y;
    wire signed [IW-1:0] d3_z;

    wire signed [IW-1:0] d4_y;
    wire signed [IW-1:0] d4_z;

    wire signed [IW-1:0] d5_y;
    wire signed [IW-1:0] d5_z;

    wire signed [IW-1:0] d6_y;
    wire signed [IW-1:0] d6_z;

    wire signed [IW-1:0] d7_y;
    wire signed [IW-1:0] d7_z;

    wire signed [IW-1:0] d8_z;

    wire d0_diff;
    wire d1_diff;
    wire d2_diff;
    wire d3_diff;
    wire d4_diff;
    wire d5_diff;
    wire d6_diff;
    wire d7_diff;

    assign d0_x = h8_x;
    assign d0_y = h8_y;
    assign d0_z = 22'sd0;

    assign d0_diff = d0_y[IW-1] ^ d0_x[IW-1];
    assign d1_y = d0_diff ? d0_y + (d0_x >>> 1) : d0_y - (d0_x >>> 1);
    assign d1_z = d0_diff ? d0_z - STEP_1 : d0_z + STEP_1;

    assign d1_diff = d1_y[IW-1] ^ d0_x[IW-1];
    assign d2_y = d1_diff ? d1_y + (d0_x >>> 2) : d1_y - (d0_x >>> 2);
    assign d2_z = d1_diff ? d1_z - STEP_2 : d1_z + STEP_2;

    assign d2_diff = d2_y[IW-1] ^ d0_x[IW-1];
    assign d3_y = d2_diff ? d2_y + (d0_x >>> 3) : d2_y - (d0_x >>> 3);
    assign d3_z = d2_diff ? d2_z - STEP_3 : d2_z + STEP_3;

    assign d3_diff = d3_y[IW-1] ^ d0_x[IW-1];
    assign d4_y = d3_diff ? d3_y + (d0_x >>> 4) : d3_y - (d0_x >>> 4);
    assign d4_z = d3_diff ? d3_z - STEP_4 : d3_z + STEP_4;

    assign d4_diff = d4_y[IW-1] ^ d0_x[IW-1];
    assign d5_y = d4_diff ? d4_y + (d0_x >>> 5) : d4_y - (d0_x >>> 5);
    assign d5_z = d4_diff ? d4_z - STEP_5 : d4_z + STEP_5;

    assign d5_diff = d5_y[IW-1] ^ d0_x[IW-1];
    assign d6_y = d5_diff ? d5_y + (d0_x >>> 6) : d5_y - (d0_x >>> 6);
    assign d6_z = d5_diff ? d5_z - STEP_6 : d5_z + STEP_6;

    assign d6_diff = d6_y[IW-1] ^ d0_x[IW-1];
    assign d7_y = d6_diff ? d6_y + (d0_x >>> 7) : d6_y - (d0_x >>> 7);
    assign d7_z = d6_diff ? d6_z - STEP_7 : d6_z + STEP_7;

    assign d7_diff = d7_y[IW-1] ^ d0_x[IW-1];
    assign d8_z = d7_diff ? d7_z - STEP_8 : d7_z + STEP_8;

    wire signed [IW-1:0] q_round;
    wire signed [15:0] y_calc;

    assign q_round = d8_z[IW-1] ? d8_z - 22'sd8 : d8_z + 22'sd8;
    assign y_calc = q_round[19:4];

    reg signed [15:0] y_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_reg <= 16'sd0;
        end else begin
            if (x == 16'sd0) begin
                y_reg <= 16'sd0;
            end else begin
                y_reg <= y_calc;
            end
        end
    end

    assign y = y_reg;

endmodule

