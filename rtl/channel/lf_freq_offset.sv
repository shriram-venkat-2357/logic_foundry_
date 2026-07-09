// channel/lf_freq_offset.sv
module lf_freq_offset #(
    parameter DATA_WIDTH = 16
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,
    input  logic [7:0]             freq_offset_cfg_i, // 0=none, higher=more offset
    input  logic [DATA_WIDTH-1:0]  lf_data_i,
    input  logic                   lf_valid_i,
    output logic                   lf_ready_o,

    output logic [DATA_WIDTH-1:0]  lf_data_o,
    output logic                   lf_valid_o,
    input  logic                   lf_ready_i
);

    logic [15:0] phase_accumulator;
    logic [7:0]  phase_shift;

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            phase_accumulator <= '0;
        else if (lf_valid_i && lf_ready_i)
            phase_accumulator <= phase_accumulator + freq_offset_cfg_i;
    end

    // Simplified rotation: use top bits of phase to create a rotating mask
    assign phase_shift = phase_accumulator[15:8];
    
    // Apply rotation as a simple XOR perturbation (hackathon shortcut)
    // In production, this would be a complex multiply with sin/cos LUT
    assign lf_data_o  = lf_data_i ^ {{8{1'b0}}, phase_shift};
    assign lf_valid_o = lf_valid_i;
    assign lf_ready_o = lf_ready_i;

endmodule
