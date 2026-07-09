//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_bpsk_demod
// Author  : Member-2
//------------------------------------------------------------------------------
// Description:
// BPSK Demodulator
//
// Decision Rule:
//   sample >= 0  --> Bit = 1
//   sample <  0  --> Bit = 0
//==============================================================================

module lf_bpsk_demod #(

    parameter int DATA_WIDTH = 16

)(

    input  logic                           lf_clk_i,
    input  logic                           lf_rst_n_i,

    input  logic signed [DATA_WIDTH-1:0]   lf_data_i,
    input  logic                           lf_valid_i,

    output logic                           lf_bit_o,
    output logic                           lf_valid_o

);

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            lf_bit_o   <= 1'b0;
            lf_valid_o <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------------------
            // Default
            //--------------------------------------------------------------

            lf_valid_o <= 1'b0;

            //--------------------------------------------------------------
            // Demodulation
            //--------------------------------------------------------------

            if(lf_valid_i)
            begin

                if(lf_data_i >= 0)
                    lf_bit_o <= 1'b1;
                else
                    lf_bit_o <= 1'b0;

                lf_valid_o <= 1'b1;

            end

        end

    end

endmodule
