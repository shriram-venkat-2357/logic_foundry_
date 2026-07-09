// tb/lf_monitor.sv
// Passively observes TX output and RX input, records transactions

module lf_monitor #(
    parameter DATA_WIDTH = 16,
    parameter string NAME = "UNNAMED"
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,

    // Observed Stream
    input  logic [DATA_WIDTH-1:0]  lf_data_i,
    input  logic                   lf_valid_i,
    input  logic                   lf_ready_i,

    // Output Queue (for scoreboard)
    output logic [DATA_WIDTH-1:0]  captured_data [$]
);

    logic [31:0] transaction_count;

    initial begin
        transaction_count = 0;
    end

    always @(posedge lf_clk_i) begin
        if (lf_rst_n_i && lf_valid_i && lf_ready_i) begin
            captured_data.push_back(lf_data_i);
            transaction_count++;
            if (transaction_count % 50 == 0)
                $display("[MONITOR-%s] Captured %0d transactions", NAME, transaction_count);
        end
    end

endmodule
