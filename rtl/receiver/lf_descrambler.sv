//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_descrambler
//------------------------------------------------------------------------------
// Description:
// 7-bit LFSR Descrambler
//
// Polynomial:
// x^7 + x^4 + 1
//==============================================================================

module lf_descrambler #

(

parameter int LFSR_WIDTH = 7,
parameter logic [LFSR_WIDTH-1:0] SEED = 7'b1011101

)

(

input  logic lf_clk_i,
input  logic lf_rst_n_i,

input  logic lf_valid_i,
input  logic lf_bit_i,

output logic lf_valid_o,
output logic lf_bit_o

);

logic [LFSR_WIDTH-1:0] lfsr;
logic feedback;

always_comb
begin
    feedback = lfsr[6] ^ lfsr[3];
end

always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
begin

    if(!lf_rst_n_i)
    begin

        lfsr       <= SEED;
        lf_bit_o   <= 0;
        lf_valid_o <= 0;

    end

    else
    begin

        lf_valid_o <= 0;

        if(lf_valid_i)
        begin

            //------------------------------------------
            // Descramble
            //------------------------------------------

            lf_bit_o <= lf_bit_i ^ feedback;

            //------------------------------------------
            // Update LFSR
            //------------------------------------------

            lfsr <= {lfsr[5:0],feedback};

            lf_valid_o <= 1'b1;

        end

    end

end

endmodule
