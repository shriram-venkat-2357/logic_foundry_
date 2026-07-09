//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_equalizer
//------------------------------------------------------------------------------
// Description:
// Zero-Forcing Equalizer (Hackathon Version)
//
// Currently performs pass-through when channel gain = 1.
// Interface is compatible with future DSP implementation.
//==============================================================================

module lf_equalizer #

(

parameter DATA_WIDTH = 16

)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

input logic signed [DATA_WIDTH-1:0] real_i,
input logic signed [DATA_WIDTH-1:0] imag_i,

input logic signed [DATA_WIDTH-1:0] channel_gain_i,

input logic valid_i,

output logic signed [DATA_WIDTH-1:0] real_o,
output logic signed [DATA_WIDTH-1:0] imag_o,

output logic valid_o

);

always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)

begin

    if(!lf_rst_n_i)

    begin

        real_o  <= '0;
        imag_o  <= '0;
        valid_o <= 1'b0;

    end

    else

    begin

        valid_o <= valid_i;

        //------------------------------------------
        // Hackathon Pass-through
        //------------------------------------------

        if(valid_i)
        begin

            real_o <= real_i;
            imag_o <= imag_i;

        end

    end

end

endmodule
