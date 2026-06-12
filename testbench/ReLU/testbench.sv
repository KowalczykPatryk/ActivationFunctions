`timescale 1ns/1ps

module relu_tb;

    reg  signed [31:0] din_relu;
    wire signed [31:0] dout_relu;

    reg signed [31:0] expected;
    integer i;
    integer errors = 0;

    relu dut (
        .din_relu(din_relu),
        .dout_relu(dout_relu)
    );

    task check;
        begin
            expected = (din_relu < 0) ? 0 : din_relu;

            #1;

            $display("IN=%0d | OUT=%0d | EXPECTED=%0d",
                     din_relu, dout_relu, expected);

            if (dout_relu !== expected) begin
                $display("  -> ERROR!");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("=== RELU TEST START ===");

        // testy podstawowe
        din_relu = -10;  #10; check();
        din_relu = -1;   #10; check();
        din_relu = 0;    #10; check();
        din_relu = 1;    #10; check();
        din_relu = 5;    #10; check();

        // granice
        din_relu = 32'sh7fffffff; #10; check();
        din_relu = 32'sh80000000; #10; check();

        // random
        for (i = 0; i < 20; i = i + 1) begin
            din_relu = $random;
            #10;
            check();
        end

        $display("=== TEST SUMMARY ===");
        $display("Total errors: %0d", errors);

        $finish;
    end

endmodule