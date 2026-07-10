//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_pkt_gen
//------------------------------------------------------------------------------
// Description:
// Packet Generator
//
// Generates packet framing signals for the transmitter pipeline.
//
// Packet Flow:
//
//      Data In
//         │
//         ▼
//     Packet Generator
//         │
//         ▼
//      CRC Generator
//
//==============================================================================

module lf_pkt_gen #

(
    parameter DATA_WIDTH = 16,
    parameter PACKET_LENGTH = 256
)

(

input logic lf_clk_i,
input logic lf_rst_n_i,

//------------------------------------------------------------
// Input Data
//------------------------------------------------------------

input logic [DATA_WIDTH-1:0] data_i,
input logic                  valid_i,

//------------------------------------------------------------
// Control
//------------------------------------------------------------

input logic pkt_start_i,

//------------------------------------------------------------
// Output Packet
//------------------------------------------------------------

output logic [DATA_WIDTH-1:0] data_o,

output logic valid_o,

output logic sop_o,
output logic eop_o,

output logic pkt_done_o

);

    //----------------------------------------------------------------------
    // Packet Counter
    //----------------------------------------------------------------------

    logic [$clog2(PACKET_LENGTH)-1:0] pkt_cnt;

    logic packet_active;

    //----------------------------------------------------------------------
    // Packet Generator
    //----------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            pkt_cnt <= '0;

            packet_active <= 1'b0;

            data_o <= '0;

            valid_o <= 1'b0;

            sop_o <= 1'b0;
            eop_o <= 1'b0;

            pkt_done_o <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------------------
            // Default
            //--------------------------------------------------------------

            valid_o <= 1'b0;
            sop_o <= 1'b0;
            eop_o <= 1'b0;
            pkt_done_o <= 1'b0;

            //--------------------------------------------------------------
            // Start Packet
            //--------------------------------------------------------------

            if(pkt_start_i)
            begin

                packet_active <= 1'b1;

                pkt_cnt <= '0;

            end

            //--------------------------------------------------------------
            // Packet Transmission
            //--------------------------------------------------------------

            if(packet_active && valid_i)
            begin

                data_o <= data_i;

                valid_o <= 1'b1;

                //----------------------------------------------------------
                // SOP
                //----------------------------------------------------------

                if(pkt_cnt == 0)
                    sop_o <= 1'b1;

                //----------------------------------------------------------
                // EOP
                //----------------------------------------------------------

                if(pkt_cnt == PACKET_LENGTH-1)
                begin

                    eop_o <= 1'b1;

                    pkt_done_o <= 1'b1;

                    packet_active <= 1'b0;

                    pkt_cnt <= '0';

                end

                else
                begin

                    pkt_cnt <= pkt_cnt + 1'b1;

                end

            end

        end

    end

endmodule