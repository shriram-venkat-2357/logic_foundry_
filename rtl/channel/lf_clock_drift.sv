// rtl/channel/lf_clock_drift.sv
// FIX: insert_sample now actually inserts (duplicates) a sample
module lf_clock_drift #(
    parameter DATA_WIDTH = 16
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,
    input  logic [7:0]             drift_cfg_i,  // 0=perfect, higher=more drift
    input  logic [DATA_WIDTH-1:0]  lf_data_i,
    input  logic                   lf_valid_i,
    output logic                   lf_ready_o,

    output logic [DATA_WIDTH-1:0]  lf_data_o,
    output logic                   lf_valid_o,
    input  logic                   lf_ready_i
);

    logic [15:0] drift_counter;
    logic        drop_sample;
    logic        insert_sample;
    logic        hold_data;
    logic [DATA_WIDTH-1:0] held_data;
    logic        holding;

    // Periodically drop or duplicate a sample to simulate clock drift
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            drift_counter <= '0;
        else
            drift_counter <= drift_counter + 1;
    end

    // Drop a sample when counter wraps to 0 (if drift enabled)
    assign drop_sample   = (drift_cfg_i > 0) && (drift_counter == 16'h0000);

    // Insert (duplicate) a sample at the midpoint
    assign insert_sample = (drift_cfg_i > 0) && (drift_counter == {8'h00, drift_cfg_i});

    // Hold register for inserted sample
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i) begin
            holding   <= 1'b0;
            held_data <= '0;
        end else begin
            if (lf_valid_i && !holding)
                held_data <= lf_data_i;
            holding <= lf_valid_i;
        end
    end

    // Output mux: normal pass-through, drop, or insert
    always_comb begin
        lf_ready_o = lf_ready_i;
        lf_data_o  = lf_data_i;

        if (drop_sample && lf_valid_i) begin
            // Drop: suppress output
            lf_valid_o = 1'b0;
            lf_data_o  = '0;
        end else if (insert_sample && holding && lf_ready_i) begin
            // Insert: output the held (previous) sample again
            lf_valid_o = 1'b1;
            lf_data_o  = held_data;
        end else begin
            // Normal pass-through
            lf_valid_o = lf_valid_i;
        end
    end

endmodule