# ActivationFunctions
Hardware implementation of activation functions: ReLU, sigmoid and tanh.

# Konfiguracja Środowiska LaTeX

Krótki przewodnik jak przygotować system Linux oraz Visual Studio Code do pracy z dokumentem.

---

## 1. Instalacja kompilatora (Linux)

Do kompilacji dokumentów wymagana jest dystrybucja **TeX Live**:

```bash
sudo apt update
sudo apt install texlive-full
sudo apt install python3-pygments
```

## 2. Wtyczka do Visual Studio Code

Do wygodnego pisania i automatycznego podglądu dokumentu używamy oficjalnego standardu:

1. Otwórz VS Code.
2. Wejdź w zakładkę rozszerzeń (skrót: `Ctrl + Shift + X`).
3. Wyszukaj i zainstaluj wtyczkę: **LaTeX Workshop** (autor: *James Yu*).

## 3. Setup minted używającego Pygments napisanego w Pythonie

Domyślnie LaTeX ze względów bezpieczeństwa ma zablokowaną możliwość uruchamiania jakichkolwiek programów z poziomu systemu operacyjnego. Musimy mu na to jawnie pozwolić, przekazując flagę -shell-escape. Trzeba dodać tę flagę do ustawień edytora:

1. Wciśnij skrót Ctrl + Shift + P, aby otworzyć paletę komend.

2. Wpisz: Preferences: Open User Settings (JSON)

3. Dodać:
```JSON
"latex-workshop.latex.tools": [
    {
        "name": "latexmk",
        "command": "latexmk",
        "args": [
            "-synctex=1",
            "-interaction=nonstopmode",
            "-file-line-error",
            "-pdf",
            "-outdir=%OUTDIR%",
            "-shell-escape",
            "%DOC%"
        ]
    },
    {
        "name": "pdflatex",
        "command": "pdflatex",
        "args": [
            "-synctex=1",
            "-interaction=nonstopmode",
            "-file-line-error",
            "-shell-escape",
            "%DOC%"
        ]
    }
],
```

---

## 3. Jak pracować z projektem?

* **Kompilacja:** Wtyczka kompiluje dokument automatycznie do formatu PDF przy każdym zapisaniu pliku (`Ctrl + S`).
* **Podgląd PDF:** Aby otworzyć podgląd na żywo obok kodu, użyj skrótu `Ctrl + Alt + V` lub kliknij ikonę z zakładką/lupą w prawym górnym rogu ekranu.
* **Nawigacja:** Kliknięcie z wciśniętym klawiszem `Ctrl` na tekst w podglądzie PDF przeniesie Cię do odpowiedniej linijki w kodzie `.tex` (i odwrotnie).
