module test;
    initial begin
        $display("========================================");
        $display("  MEMBER 3 ENVIRONMENT IS READY!");
        $display("  Verilator + Makefile is working.");
        $display("========================================");
        $dumpfile("waves/test.fst");
        $dumpvars(0, test);
        #10;
        $finish;
    end
endmodule
