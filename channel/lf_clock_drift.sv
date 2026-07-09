// channel/lf_clock_drift.sv
// Fixed: Implement sample dropping logic and remove unused signals

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

    // Periodically drop or duplicate a sample to simulate clock drift
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            drift_counter <= 16'h0000;
        else if (lf_valid_i && lf_ready_i)
            drift_counter <= drift_counter + 1;
    end

    // Drop a sample every (256 - drift_cfg) cycles if drift is enabled
    // insert_sample pattern: duplicate sample when counter reaches drift_cfg threshold
    assign drop_sample   = (drift_cfg_i > 0) && (drift_counter[7:0] == 8'h00);
    assign insert_sample = (drift_cfg_i > 0) && (drift_counter[7:0] == drift_cfg_i[7:0]);

    // Combine drop and insert logic for clock drift effect
    // If dropping, suppress valid; if inserting, duplicate (hold) the sample
    assign lf_data_o  = lf_data_i;
    assign lf_valid_o = lf_valid_i && !drop_sample;  // Drop suppresses output
    assign lf_ready_o = lf_ready_i && !insert_sample; // Insert creates backpressure

endmodule
