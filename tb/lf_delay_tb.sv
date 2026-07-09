`timescale 1ns/1ps

module lf_delay_tb;
    localparam DATA_WIDTH = 16;
    localparam MAX_DELAY  = 8;

    logic lf_clk_i = 0;
    logic lf_rst_n_i = 0;
    logic [3:0] delay_cfg_i = 4'd2;
    logic [DATA_WIDTH-1:0] lf_data_i = '0;
    logic lf_valid_i = 0;
    logic lf_ready_o;
    logic [DATA_WIDTH-1:0] lf_data_o;
    logic lf_valid_o;
    logic lf_ready_i = 1'b1;

    lf_delay #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_DELAY(MAX_DELAY)
    ) dut (
        .lf_clk_i(lf_clk_i),
        .lf_rst_n_i(lf_rst_n_i),
        .delay_cfg_i(delay_cfg_i),
        .lf_data_i(lf_data_i),
        .lf_valid_i(lf_valid_i),
        .lf_ready_o(lf_ready_o),
        .lf_data_o(lf_data_o),
        .lf_valid_o(lf_valid_o),
        .lf_ready_i(lf_ready_i)
    );

    always #5 lf_clk_i = ~lf_clk_i;

    initial begin
        $dumpfile("logs/lf_delay.vcd");
        $dumpvars(0, lf_delay_tb);

        repeat (2) @(posedge lf_clk_i);
        lf_rst_n_i = 1'b1;
        repeat (2) @(posedge lf_clk_i);

        lf_data_i = 16'h1234;
        lf_valid_i = 1'b1;
        @(posedge lf_clk_i);
        lf_valid_i = 1'b0;
        lf_data_i = 16'h0000;

        repeat (5) @(posedge lf_clk_i);

        if (lf_valid_o && lf_data_o === 16'h1234) begin
            $display("PASS: delayed data observed");
        end else begin
            $display("FAIL: expected delayed data");
        end

        $finish;
    end
endmodule
