//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_qam16_demod
//------------------------------------------------------------------------------
// Description:
// 16-QAM Demodulator
//
// FIX: Thresholds now match the actual QAM16 modulator constellation levels:
//   Modulator maps to: -24576, -8192, +8192, +24576 (Gray coded)
//   Decision boundaries (midpoints): -16384, 0, +16384
//
//   >= +16384 -> 11  (LEVEL3_P)
//   >=      0 -> 10  (LEVEL1_P)
//   >= -16384 -> 01  (LEVEL1_N)
//   <  -16384 -> 00  (LEVEL3_N)
//
// Output: {I_bits, Q_bits}
//==============================================================================

module lf_qam16_demod #(
    parameter int DATA_WIDTH = 16
)(
    input logic lf_clk_i,
    input logic lf_rst_n_i,

    input logic signed [DATA_WIDTH-1:0] lf_i_data_i,
    input logic signed [DATA_WIDTH-1:0] lf_q_data_i,

    input logic lf_valid_i,

    output logic [3:0] lf_bits_o,
    output logic lf_valid_o
);

    // Decision thresholds at midpoints between constellation levels
    // Levels: -24576, -8192, +8192, +24576
    // Midpoints: -16384, 0, +16384
    localparam signed [DATA_WIDTH-1:0] THRESH_HIGH = 16'sd16384;
    localparam signed [DATA_WIDTH-1:0] THRESH_LOW  = 16'sd0;

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin
        if(!lf_rst_n_i)
        begin
            lf_bits_o  <= 4'b0000;
            lf_valid_o <= 1'b0;
        end
        else
        begin
            lf_valid_o <= 1'b0;

            if(lf_valid_i)
            begin
                // I Decision (2 bits) — Gray coded
                if(lf_i_data_i >= THRESH_HIGH)
                    lf_bits_o[3:2] <= 2'b10;  // LEVEL3_P
                else if(lf_i_data_i >= THRESH_LOW)
                    lf_bits_o[3:2] <= 2'b11;  // LEVEL1_P
                else if(lf_i_data_i >= -THRESH_HIGH)
                    lf_bits_o[3:2] <= 2'b01;  // LEVEL1_N
                else
                    lf_bits_o[3:2] <= 2'b00;  // LEVEL3_N

                // Q Decision (2 bits) — Gray coded
                if(lf_q_data_i >= THRESH_HIGH)
                    lf_bits_o[1:0] <= 2'b10;
                else if(lf_q_data_i >= THRESH_LOW)
                    lf_bits_o[1:0] <= 2'b11;
                else if(lf_q_data_i >= -THRESH_HIGH)
                    lf_bits_o[1:0] <= 2'b01;
                else
                    lf_bits_o[1:0] <= 2'b00;

                lf_valid_o <= 1'b1;
            end
        end
    end

endmodule