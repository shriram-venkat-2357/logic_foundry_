//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_crc_check
//------------------------------------------------------------------------------
// Description:
// CRC-4 Checker
// 
// Polynomial:
// x^4 + x + 1
//
// Industry Style:
// - Streaming CRC
// - Registered Outputs
// - Parameterized Polynomial
//==============================================================================

module lf_crc_check #(

    parameter int CRC_WIDTH = 4,
    parameter logic [CRC_WIDTH-1:0] POLY = 4'b0011

)(

    input  logic                     lf_clk_i,
    input  logic                     lf_rst_n_i,

    input  logic                     lf_bit_i,
    input  logic                     lf_valid_i,

    input  logic                     lf_frame_end_i,

    output logic                     lf_crc_ok_o,
    output logic                     lf_crc_error_o

);

    //------------------------------------------------------------
    // CRC Register
    //------------------------------------------------------------

    logic [CRC_WIDTH-1:0] crc_reg;
    logic feedback;

    //------------------------------------------------------------
    // Sequential CRC Calculation
    //------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            crc_reg         <= '0;
            lf_crc_ok_o     <= 1'b0;
            lf_crc_error_o  <= 1'b0;
        end

        else
        begin

            //----------------------------------------------------
            // Default Outputs
            //----------------------------------------------------

            lf_crc_ok_o    <= 1'b0;
            lf_crc_error_o <= 1'b0;

            //----------------------------------------------------
            // Process Incoming Bits
            //----------------------------------------------------

            if(lf_valid_i)
            begin

                feedback = lf_bit_i ^ crc_reg[CRC_WIDTH-1];

                crc_reg <= {crc_reg[CRC_WIDTH-2:0],1'b0};

                if(feedback)
                    crc_reg <= ({crc_reg[CRC_WIDTH-2:0],1'b0} ^ POLY);

            end

            //----------------------------------------------------
            // End of Frame
            //----------------------------------------------------

            if(lf_frame_end_i)
            begin

                if(crc_reg == 0)
                    lf_crc_ok_o <= 1'b1;
                else
                    lf_crc_error_o <= 1'b1;

                crc_reg <= '0;

            end

        end

    end

endmodule
