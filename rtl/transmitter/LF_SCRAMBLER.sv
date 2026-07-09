`timescale 1ns/1ps
`ifndef LF_SCRAMBLER_SV
`define LF_SCRAMBLER_SV

import LF_pkg::*;

module LF_SCRAMBLER
#(
    parameter DATA_WIDTH = 16
)
(
    input  logic                  clk,
    input  logic                  rst_n,

    //------------------------------------------------------------
    // Input Stream
    //------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic                  valid_in,
    input  logic                  sop_in,
    input  logic                  eop_in,

    //------------------------------------------------------------
    // Output Stream
    //------------------------------------------------------------
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  valid_out,
    output logic                  sop_out,
    output logic                  eop_out
);

    //------------------------------------------------------------
    // 7-bit LFSR
    //------------------------------------------------------------

    logic [6:0] lfsr;

    logic [DATA_WIDTH-1:0] scramble_data;

    integer i;

    //------------------------------------------------------------
    // Scrambler Logic
    //------------------------------------------------------------

    always_comb
    begin

        logic [6:0] temp_lfsr;

        temp_lfsr = lfsr;

        scramble_data = '0;

        for(i=0;i<DATA_WIDTH;i=i+1)
        begin

            scramble_data[i] =
                data_in[i] ^
                temp_lfsr[6] ^
                temp_lfsr[3];

            temp_lfsr =
            {
                temp_lfsr[5:0],
                temp_lfsr[6] ^ temp_lfsr[3]
            };

        end

    end

    //------------------------------------------------------------
    // Sequential Logic
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            lfsr <= 7'b1011101;

            data_out  <= '0;

            valid_out <= 1'b0;

            sop_out   <= 1'b0;
            eop_out   <= 1'b0;

        end

        else
        begin

            valid_out <= 1'b0;

            //----------------------------------------------------
            // New Packet
            //----------------------------------------------------

            if(valid_in && sop_in)
            begin

                lfsr <= 7'b1011101;

            end

            //----------------------------------------------------
            // Scramble
            //----------------------------------------------------

            if(valid_in)
            begin

                data_out  <= scramble_data;

                valid_out <= 1'b1;

                sop_out   <= sop_in;
                eop_out   <= eop_in;

                //------------------------------------------------
                // Advance LFSR
                //------------------------------------------------

                for(i=0;i<DATA_WIDTH;i=i+1)
                begin

                    lfsr <=
                    {
                        lfsr[5:0],
                        lfsr[6] ^ lfsr[3]
                    };

                end

            end

        end

    end

endmodule

`endif