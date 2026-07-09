//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_channel_est
//------------------------------------------------------------------------------
// Description:
// Simple Pilot-Based Channel Estimation Wrapper
//
// Assumption:
// Pilot symbol = +1 + j0
//
// Current implementation forwards samples unchanged while storing
// the measured pilot for future equalization.
//==============================================================================

module lf_channel_est #

(

parameter DATA_WIDTH = 16

)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

input logic signed [DATA_WIDTH-1:0] real_i,
input logic signed [DATA_WIDTH-1:0] imag_i,

input logic valid_i,

input logic pilot_i,

output logic signed [DATA_WIDTH-1:0] real_o,
output logic signed [DATA_WIDTH-1:0] imag_o,

output logic valid_o,

output logic signed [DATA_WIDTH-1:0] channel_gain_o

);

logic signed [DATA_WIDTH-1:0] channel_gain;

always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)

begin

    if(!lf_rst_n_i)

    begin

        real_o <= '0;
        imag_o <= '0;
        valid_o <= 0;
        channel_gain <= '0;

    end

    else

    begin

        //--------------------------------------
        // Forward Data
        //--------------------------------------

        real_o <= real_i;
        imag_o <= imag_i;
        valid_o <= valid_i;

        //--------------------------------------
        // Pilot Detection
        //--------------------------------------

        if(valid_i && pilot_i)

            channel_gain <= real_i;

    end

end

assign channel_gain_o = channel_gain;

endmodule
