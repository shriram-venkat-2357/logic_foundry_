// tb/lf_scoreboard.sv
// Compares TX data with RX data and reports BER

module lf_scoreboard #(
    parameter DATA_WIDTH = 16
)(
    input  logic lf_clk_i,
    input  logic lf_rst_n_i
);

    // Queues from monitors
    logic [DATA_WIDTH-1:0] tx_queue [$];
    logic [DATA_WIDTH-1:0] rx_queue [$];

    // Statistics
    logic [63:0] total_bits;
    logic [63:0] error_bits;
    logic [31:0] packets_checked;
    logic [31:0] packets_passed;
    logic [31:0] packets_failed;
    real         ber;

    initial begin
        total_bits      = 0;
        error_bits      = 0;
        packets_checked = 0;
        packets_passed  = 0;
        packets_failed  = 0;
        ber             = 0.0;
    end

    // Comparison task
    task automatic check_packet();
        logic [DATA_WIDTH-1:0] tx_word, rx_word;
        logic [DATA_WIDTH-1:0] diff;
        int bit_errs;

        if (tx_queue.size() == 0 || rx_queue.size() == 0) return;

        tx_word = tx_queue.pop_front();
        rx_word = rx_queue.pop_front();
        diff    = tx_word ^ rx_word;

        // Count bit errors (popcount)
        bit_errs = 0;
        for (int i = 0; i < DATA_WIDTH; i++)
            bit_errs += diff[i];

        total_bits += DATA_WIDTH;
        error_bits += bit_errs;
        packets_checked++;

        if (bit_errs == 0)
            packets_passed++;
        else
            packets_failed++;

        ber = (total_bits > 0) ? real'(error_bits) / real'(total_bits) : 0.0;
    endtask

    // Run comparison whenever data is available
    always @(posedge lf_clk_i) begin
        if (lf_rst_n_i && tx_queue.size() > 0 && rx_queue.size() > 0) begin
            check_packet();
        end
    end

    // Final report
    function void print_report();
        $display("\n==============================================");
        $display("       LF_SCOREBOARD FINAL REPORT");
        $display("==============================================");
        $display("  Total Bits     : %0d", total_bits);
        $display("  Error Bits     : %0d", error_bits);
        $display("  BER            : %f", ber);
        $display("  Packets Checked: %0d", packets_checked);
        $display("  Packets Passed : %0d", packets_passed);
        $display("  Packets Failed : %0d", packets_failed);
        $display("==============================================");
        if (ber == 0.0)
            $display("  RESULT: PASS (Error-Free)");
        else
            $display("  RESULT: BER = %f (Channel Active)", ber);
        $display("==============================================\n");
    endfunction

endmodule
