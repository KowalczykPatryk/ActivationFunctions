module tanh_lut #(
    parameter AW = 6,  // szerokość adresu (64 komórki)
    parameter DW = 16, // szerokość danych (wejście Q4.12 i wyjście Q4.12)
    parameter Q  = 12  // liczba bitów ułamkowych (Q4.12)
)(
    input  wire clk, // zegar
    input  wire rst_n, // reset asynchroniczny, aktywny niskim poziomem
    input  wire [DW-1:0] x, // wejście stałoprzecinkowe Q4.12, zakres [-4.0, +4.0]
    output reg  [DW-1:0] y // wyjście stałoprzecinkowe Q4.12
);

    // bardziej szczegółowo jest to opisane w pliku LUT_data_generators/tanh.py

    // deklaracja pamięci (od 0 do 2^AW - 1)
    (* rom_style = "block" *) reg [DW-1:0] mem [0 : (1<<AW)-1];

    initial begin
        // ładowanie wygenerowanych danych (wersja 64-punktowa)
        $readmemb("tanh_data64.mem", mem);
    end

    // Przeliczenie wejścia Q4.12 na adres LUT
    // LUT pokrywa liniowo zakres [-4.0, +4.0] -> adresy [0, 2^AW - 1]
    // addr = (x_int + 4·2^Q) >> (Q + 3 - AW)
    //
    // Przykłady (Q=12, AW=6):
    //   x = -4.0  ->  x_int = -16384 ->  addr =   0
    //   x =  0.0  ->  x_int =      0 ->  addr =  32
    //   x = +4.0  ->  x_int = +16384 ->  addr =  63 (nasycenie)
    // ---------------------------------------------------------------
    localparam OFFSET = 4 << Q; // 4.0 w formacie Q -> 16384 dla Q=12
    localparam RSHIFT = Q + 3 - AW;  // 9 dla Q=12, AW=6

    wire signed [DW:0] x_shifted = $signed({x[DW-1], x}) + OFFSET;

    wire [AW-1:0] addr =
        (x_shifted < 0)                     ? {AW{1'b0}} :  // nasycenie dolne (x < -4.0)
        (x_shifted >= (1 << (AW + RSHIFT))) ? {AW{1'b1}} :  // nasycenie górne (x >= +4.0)
        x_shifted[AW + RSHIFT - 1 -: AW];                    // zakres normalny

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y <= '0;
        else
            y <= mem[addr];
    end

endmodule