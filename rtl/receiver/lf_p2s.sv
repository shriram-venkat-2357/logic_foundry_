//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_p2s
//------------------------------------------------------------------------------
// Description:
// Parallel-to-Serial Converter
//
// Converts a 4-bit word into a serial bit stream.
//
//==============================================================================

module lf_p2s #

(

parameter DATA_WIDTH = 4

)

(

input  logic                     lf_clk_i,
input  logic                     lf_rst_n_i,

input  logic [DATA_WIDTH-1:0]    lf_data_i,
input  logic                     lf_valid_i,

output logic                     lf_bit_o,
output logic                     lf_valid_o,
output logic                     lf_busy_o

);

    //----------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------

    logic [DATA_WIDTH-1:0] shift_reg;

    logic [$clog2(DATA_WIDTH):0] bit_cnt;

    logic busy;

    //----------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            shift_reg  <= '0;
            bit_cnt    <= '0;

            lf_bit_o   <= 1'b0;
            lf_valid_o <= 1'b0;

            busy       <= 1'b0;

        end

        else
        begin

            lf_valid_o <= 1'b0;

            //--------------------------------------------------
            // Load Parallel Word
            //--------------------------------------------------

            if(lf_valid_i && !busy)
            begin

                shift_reg <= lf_data_i;
                bit_cnt   <= DATA_WIDTH;
                busy      <= 1'b1;

            end

            //--------------------------------------------------
            // Shift Out Bits
            //--------------------------------------------------

            else if(busy)
            begin

                lf_bit_o   <= shift_reg[DATA_WIDTH-1];
                lf_valid_o <= 1'b1;

                shift_reg <= {shift_reg[DATA_WIDTH-2:0],1'b0};

                bit_cnt <= bit_cnt - 1'b1;

                if(bit_cnt == 1)
                    busy <= 1'b0;

            end

        end

    end

    assign lf_busy_o = busy;

endmodule
