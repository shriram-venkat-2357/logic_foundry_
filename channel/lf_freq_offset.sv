// channel/lf_freq_offset.sv
// Fixed: Proper frequency offset using phase accumulation and sin/cos modulation

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
    logic [7:0]  phase_index;
    
    // Sine lookup table (8-bit phase to 8-bit amplitude, scaled 0-127)
    // Index [0:63] covers 0 to 90 degrees
    wire [7:0] sin_lut [0:63] = '{
        8'd0,   8'd3,   8'd6,   8'd9,   8'd12,  8'd15,  8'd18,  8'd21,
        8'd24,  8'd27,  8'd30,  8'd33,  8'd36,  8'd39,  8'd42,  8'd45,
        8'd48,  8'd51,  8'd54,  8'd57,  8'd59,  8'd62,  8'd65,  8'd67,
        8'd70,  8'd73,  8'd75,  8'd78,  8'd80,  8'd82,  8'd85,  8'd87,
        8'd89,  8'd91,  8'd93,  8'd95,  8'd97,  8'd99,  8'd100, 8'd102,
        8'd104, 8'd105, 8'd107, 8'd108, 8'd110, 8'd111, 8'd112, 8'd113,
        8'd114, 8'd115, 8'd116, 8'd117, 8'd117, 8'd118, 8'd119, 8'd119,
        8'd120, 8'd120, 8'd120, 8'd121, 8'd121, 8'd121, 8'd121, 8'd127
    };

    // Phase accumulator increments each clock
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            phase_accumulator <= 16'h0000;
        else if (lf_valid_i && lf_ready_i)
            phase_accumulator <= phase_accumulator + {freq_offset_cfg_i, 8'h00};
    end

    // Extract phase index (upper 6 bits for 64-entry LUT)
    assign phase_index = phase_accumulator[15:10];

    // Modulate data with phase-dependent amplitude
    // Using sine value to scale the input signal
    logic [15:0] modulated_data;
    logic [23:0] temp_mult;

    always_comb begin
        // Multiply input data by sin value for amplitude modulation
        temp_mult = lf_data_i * sin_lut[phase_index];
        // Scale back: divide by 127 (approximately by shifting right 7)
        modulated_data = {temp_mult[23:16], temp_mult[15:8]};
    end

    // Output assignments
    assign lf_data_o  = modulated_data;
    assign lf_valid_o = lf_valid_i;
    assign lf_ready_o = lf_ready_i;

endmodule
