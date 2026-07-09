//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_qam16_demod
//------------------------------------------------------------------------------
// Description:
// Simplified 16-QAM Demodulator
//
// Thresholds:
// >= +200 -> 11
// >=    0 -> 10
// >= -200 -> 01
// <  -200 -> 00
//
// Output:
// {I_bits,Q_bits}
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

            //----------------------------
            // I Decision
            //----------------------------

            if(lf_i_data_i >= 16'sd200)
                lf_bits_o[3:2] <= 2'b11;

            else if(lf_i_data_i >= 16'sd0)
                lf_bits_o[3:2] <= 2'b10;

            else if(lf_i_data_i >= -16'sd200)
                lf_bits_o[3:2] <= 2'b01;

            else
                lf_bits_o[3:2] <= 2'b00;

            //----------------------------
            // Q Decision
            //----------------------------

            if(lf_q_data_i >= 16'sd200)
                lf_bits_o[1:0] <= 2'b11;

            else if(lf_q_data_i >= 16'sd0)
                lf_bits_o[1:0] <= 2'b10;

            else if(lf_q_data_i >= -16'sd200)
                lf_bits_o[1:0] <= 2'b01;

            else
                lf_bits_o[1:0] <= 2'b00;

            lf_valid_o <= 1'b1;

        end

    end

end

endmodule
