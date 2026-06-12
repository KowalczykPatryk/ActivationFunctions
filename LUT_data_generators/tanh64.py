"""
Ten skrypt generuje plik z danymi do pamięci ROM (BRAM) w formacie binarnym.
Każdy wiersz pliku tanh_data64.mem zawiera jedną liczbę zakodowaną jako fixed-point w U2
(two's complement), odpowiadającą wartości funkcji tanh(x) dla kolejnych argumentów
z zakresu [-4.0, +4.0).

Można pomyśleć o tym jak o słowniku, gdzie kluczem jest numer linii w pliku (czyli adres),
a wartością jest wynik funkcji tanh dla tej konkretnej wartości argumentu, zakodowany
w formacie fixed-point.

Opis działania skryptu:
- Przechodzi przez wszystkie możliwe wartości 6-bitowego adresu od 0 do 63.
- Mapuje adres liniowo na zakres wejściowy [-4.0, +4.0):
      x = X_MIN + STEP * addr
      x = -4.0  +  (8 / 64) * addr
      x = addr / 8 - 4.0
- Oblicza math.tanh(x_float).
- Zamienia wynik na 16-bitowy zapis binarny fixed-point Q4.12.
- Zapisuje wszystko do pliku tanh_data64.mem, po jednej linii na wartość.

Co będzie znajdować się w pliku tanh_data64.mem:

    Adres 0  ->  x = -4.0000  ->  tanh(-4.0) == -0.9993
    Adres 1  ->  x = -3.8750  ->  tanh(-3.8750)
    itd.
    Adres 32  ->  x =  0.0000  ->  tanh( 0.0) ==  0.0
    itd.
    Adres 63  ->  x = +3.8750  ->  tanh(+3.8750) == +0.9993

Mapowanie adresu odpowiada modułowi Verilog (tanh_lut.sv):
    addr = (x_Q4.12_int + 4·2^Q) >> (Q + 3 - AW)
         = (x_Q4.12_int + 16384) >> 9          (dla Q=12, AW=6)
    odwrotnie:
         x = addr / 8 - 4.0

Ten kod zakłada, że:
- adres jest mapowany liniowo na przedział [-4.0, +4.0),
- wyjście jest zapisane jako signed fixed-point U2 z 12 bitami ułamkowymi (Q4.12).
"""

import math

# Parametry LUT zmienione na 64 wpisy
AW = 6           # liczba bitów adresu -> 2^6 = 64 wpisy
DW = 16          # szerokość danych wyjściowych
Q_OUT = 12       # liczba bitów ułamkowych w wyjściu (Q4.12)

# Zakres próbkowania funkcji tanh dla LUT
X_MIN = -4.0
X_MAX = 4.0
NUM_ENTRIES = 1 << AW
STEP = (X_MAX - X_MIN) / NUM_ENTRIES   # 8 / 64 = 0.125


def float_to_fixed_bin(val: float, width: int, q_bits: int) -> str:
    """
    Zamienia liczbę float na zapis binarny U2 fixed-point.
    """
    fixed_val = int(round(val * (1 << q_bits)))

    max_val = (1 << (width - 1)) - 1
    min_val = -(1 << (width - 1))

    if fixed_val > max_val:
        fixed_val = max_val
    elif fixed_val < min_val:
        fixed_val = min_val

    if fixed_val < 0:
        fixed_val = (1 << width) + fixed_val

    return format(fixed_val, f"0{width}b")


if __name__ == "__main__":
    with open("tanh_data64.mem", "w") as f:
        for addr in range(NUM_ENTRIES):
            x_float = X_MIN + addr * STEP
            y_float = math.tanh(x_float)
            bin_str = float_to_fixed_bin(y_float, DW, Q_OUT)
            f.write(bin_str + "\n")

    x_last = X_MIN + (NUM_ENTRIES - 1) * STEP
    print(
        f"Wygenerowano plik tanh_data64.mem: {NUM_ENTRIES} wpisów, "
        f"x in [{X_MIN}, {x_last:.4f}], krok = {STEP:.4f}"
    )