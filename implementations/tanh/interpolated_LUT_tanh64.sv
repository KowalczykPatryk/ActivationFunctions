module lut_interp #(
    parameter INPUT_W  = 16,
    parameter OUTPUT_W = 16,
    parameter Q_IN     = 12,
    parameter Q_OUT    = 12,
    parameter AW       = 6  // 64 wpisy zamiast 1024
)(
    input clk,
    input rst_n,
    input [INPUT_W-1:0] x,
    output reg [OUTPUT_W-1:0] y
);

    // Parametry wyliczane automatycznie do mapowania wejścia na adres
    localparam OFFSET   = 4 << Q_IN;
    localparam RSHIFT   = Q_IN + 3 - AW;
    localparam MAX_ADDR = (1 << AW) - 1;

    // Dwa niezależne banki jednoportowe pamięci ROM. Rozdzielenie na parzyste i nieparzyste 
    // pozwala na jednoczesny odczyt próbki bazowej i następnej w jednym cyklu zegara.
    (* syn_romstyle = "block" *) reg [OUTPUT_W-1:0] mem_even [0:(1<<(AW-1))-1];
    (* syn_romstyle = "block" *) reg [OUTPUT_W-1:0] mem_odd  [0:(1<<(AW-1))-1];

    // Bezpośrednie ładowanie danych z plików ułatwia syntezatorowi mapowanie na bloki BRAM
    initial begin
        $readmemb("tanh_even64.mem", mem_even);
        $readmemb("tanh_odd64.mem", mem_odd);
    end

    // Rejestrowanie wejścia na początku potoku poprawia timing i odciąża logikę kombinacyjną
    reg signed [INPUT_W-1:0] x_reg;

    always @(posedge clk) begin
        if (!rst_n)
            x_reg <= 0;
        else
            x_reg <= x;
    end

    // Przesunięcie wejścia do dziedziny dodatniej i wyznaczenie adresu bazowego 
    // wraz z uwzględnieniem nasycenia na krańcach przedziału
    wire signed [INPUT_W:0] x_shifted =
        $signed({x_reg[INPUT_W-1], x_reg}) + OFFSET;

    wire [AW-1:0] addr =
        (x_shifted <= 0)                    ? 0 :
        (x_shifted >= (1 << (AW + RSHIFT))) ? MAX_ADDR :
        x_shifted[AW + RSHIFT - 1 -: AW];

    // Logika rutingu dla banków pamięci. Obliczamy indeksy dla obu banków tak, 
    // aby zawsze odczytać aktualną próbkę i jedną próbkę w przód w celu interpolacji.
    wire [AW-2:0] lookup_idx = addr[AW-1:1];

    wire [AW-2:0] addr_even_bank = (addr[0] == 1'b0)  ? lookup_idx :
                                   (addr == MAX_ADDR) ? lookup_idx : 
                                   (lookup_idx + 1'b1);
                                   
    wire [AW-2:0] addr_odd_bank  = lookup_idx;

    // Drugi etap potoku: odczyt z pamięci i zatrzaśnięcie parametrów do interpolacji
    reg [OUTPUT_W-1:0] out_even;
    reg [OUTPUT_W-1:0] out_odd;
    reg                addr_lsb_reg;
    reg [RSHIFT-1:0]   frac_reg;

    wire [RSHIFT-1:0] frac_raw =
        (x_shifted <= 0 || x_shifted >= (1 << (AW + RSHIFT)))
            ? 0
            : x_shifted[RSHIFT-1:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            out_even     <= 0;
            out_odd      <= 0;
            addr_lsb_reg <= 0;
            frac_reg     <= 0;
        end else begin
            out_even     <= mem_even[addr_even_bank];
            out_odd      <= mem_odd[addr_odd_bank];
            addr_lsb_reg <= addr[0];
            frac_reg     <= frac_raw;
        end
    end

    // Trzeci etap: interpolacja liniowa. Najpierw odtwarzamy poprawną kolejność 
    // próbek na podstawie najmłodszego bitu adresu.
    wire signed [OUTPUT_W-1:0] y0_reg = (addr_lsb_reg == 1'b0) ? $signed(out_even) : $signed(out_odd);
    wire signed [OUTPUT_W-1:0] y1_reg = (addr_lsb_reg == 1'b0) ? $signed(out_odd)  : $signed(out_even);

    // Obliczenie różnicy i wymnożenie jej przez część ułamkową. 
    // Dodanie bitu znaku do frakcji zabezpiecza przed błędnym wnioskowaniem przez blok DSP.
    wire signed [OUTPUT_W:0] diff = y1_reg - y0_reg;
    wire signed [RSHIFT:0] frac_signed = {1'b0, frac_reg};
    wire signed [OUTPUT_W+RSHIFT+1:0] mult = diff * frac_signed;
    wire signed [OUTPUT_W-1:0] interp = mult >>> RSHIFT;

    // Wynik końcowy jest sumą wartości bazowej i wyliczonej poprawki interpolacyjnej
    always @(posedge clk) begin
        if (!rst_n)
            y <= 0;
        else
            y <= y0_reg + interp;
    end

endmodule