//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_cp_remove
// Author  : Member-2
//------------------------------------------------------------------------------
// Description:
// Removes the Cyclic Prefix (CP) from an OFDM symbol.
//==============================================================================

module lf_cp_remove #(
    parameter int DATA_WIDTH = 16,
    parameter int CP_LEN      = 4,
    parameter int SYMBOL_LEN  = 16
)(
    input  logic                    lf_clk_i,
    input  logic                    lf_rst_n_i,

    input  logic [DATA_WIDTH-1:0]   lf_data_i,
    input  logic                    lf_valid_i,

    output logic [DATA_WIDTH-1:0]   lf_data_o,
    output logic                    lf_valid_o
);

    //----------------------------------------------------------------------
    // Sample Counter
    //----------------------------------------------------------------------

    localparam TOTAL_LEN = CP_LEN + SYMBOL_LEN;

    logic [$clog2(TOTAL_LEN):0] sample_count;

    //----------------------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            sample_count <= '0;
            lf_data_o     <= '0;
            lf_valid_o    <= 1'b0;

        end

        else
        begin

            lf_valid_o <= 1'b0;

            if(lf_valid_i)
            begin

                //----------------------------------------------------------
                // Discard Cyclic Prefix
                //----------------------------------------------------------

                if(sample_count < CP_LEN)
                begin
                    sample_count <= sample_count + 1'b1;
                end

                //----------------------------------------------------------
                // Forward OFDM Symbol
                //----------------------------------------------------------

                else if(sample_count < TOTAL_LEN)
                begin

                    lf_data_o  <= lf_data_i;
                    lf_valid_o <= 1'b1;

                    sample_count <= sample_count + 1'b1;

                end

                //----------------------------------------------------------
                // New OFDM Symbol
                //----------------------------------------------------------

                if(sample_count == TOTAL_LEN-1)
                begin
                    sample_count <= '0;
                end

            end

        end

    end

endmodule
