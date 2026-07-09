//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_qpsk_demod
// Author  : Member-2
//------------------------------------------------------------------------------
// Description:
// QPSK Demodulator
//
// Decision Rule:
// I >= 0 -> MSB = 1
// I <  0 -> MSB = 0
//
// Q >= 0 -> LSB = 1
// Q <  0 -> LSB = 0
//
// Synthesizable RTL
//==============================================================================

module lf_qpsk_demod #(
    parameter int DATA_WIDTH = 16
)(
    input  logic                           lf_clk_i,
    input  logic                           lf_rst_n_i,

    input  logic signed [DATA_WIDTH-1:0]   lf_i_data_i,
    input  logic signed [DATA_WIDTH-1:0]   lf_q_data_i,

    input  logic                           lf_valid_i,

    output logic [1:0]                     lf_bits_o,
    output logic                           lf_valid_o
);

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        //----------------------------------------------------------
        // Reset
        //----------------------------------------------------------

        if(!lf_rst_n_i)
        begin

            lf_bits_o  <= 2'b00;
            lf_valid_o <= 1'b0;

        end

        //----------------------------------------------------------
        // Normal Operation
        //----------------------------------------------------------

        else
        begin

            // Default

            lf_valid_o <= 1'b0;

            if(lf_valid_i)
            begin

                //--------------------------------------------------
                // I Decision
                //--------------------------------------------------

                if(lf_i_data_i >= 0)
                    lf_bits_o[1] <= 1'b1;
                else
                    lf_bits_o[1] <= 1'b0;

                //--------------------------------------------------
                // Q Decision
                //--------------------------------------------------

                if(lf_q_data_i >= 0)
                    lf_bits_o[0] <= 1'b1;
                else
                    lf_bits_o[0] <= 1'b0;

                //--------------------------------------------------

                lf_valid_o <= 1'b1;

            end

        end

    end

endmodule
