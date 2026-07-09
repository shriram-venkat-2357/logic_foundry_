//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_fft
//------------------------------------------------------------------------------
// Description:
// FFT Wrapper Module
//
// Placeholder for future FFT IP integration.
//==============================================================================

module lf_fft #

(

parameter DATA_WIDTH = 16

)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

input logic signed [DATA_WIDTH-1:0] real_i,
input logic signed [DATA_WIDTH-1:0] imag_i,
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

        real_o  <= real_i;
        imag_o  <= imag_i;
        valid_o <= valid_i;

    end

end

endmodule
