`timescale 1ns/1ps
`ifndef LF_PILOT_INSERT_SV
`define LF_PILOT_INSERT_SV

import LF_pkg::*;

module LF_PILOT_INSERT
#(
    parameter IQ_WIDTH        = 16,
    parameter FFT_SIZE        = 64,
    parameter PILOT_INTERVAL  = 4
)
(
    input logic clk,
    input logic rst_n,

    //------------------------------------------------------------
    // Input IQ Symbols
    //------------------------------------------------------------

    input logic signed [IQ_WIDTH-1:0] i_in,
    input logic signed [IQ_WIDTH-1:0] q_in,

    input logic valid_in,
    input logic sop_in,
    input logic eop_in,

    //------------------------------------------------------------
    // Output IQ Symbols
    //------------------------------------------------------------

    output logic signed [IQ_WIDTH-1:0] i_out,
    output logic signed [IQ_WIDTH-1:0] q_out,

    output logic valid_out,
    output logic sop_out,
    output logic eop_out
);

    //------------------------------------------------------------
    // Pilot Symbol
    //------------------------------------------------------------

    localparam signed [IQ_WIDTH-1:0] PILOT_I = 16'sd16384;
    localparam signed [IQ_WIDTH-1:0] PILOT_Q = 16'sd0;

    //------------------------------------------------------------
    // Subcarrier Counter
    //------------------------------------------------------------

    logic [$clog2(FFT_SIZE)-1:0] carrier_cnt;

    logic pilot_insert;
        //------------------------------------------------------------
    // Pilot Detection
    //------------------------------------------------------------

    always_comb
    begin

        if((carrier_cnt % PILOT_INTERVAL) == 0)
            pilot_insert = 1'b1;
        else
            pilot_insert = 1'b0;

    end

    //------------------------------------------------------------
    // Pilot Insertion
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            carrier_cnt <= '0;

            i_out <= '0;
            q_out <= '0;

            valid_out <= 1'b0;

            sop_out <= 1'b0;
            eop_out <= 1'b0;

        end

        else
        begin

            //----------------------------------------------------
            // Default
            //----------------------------------------------------

            valid_out <= 1'b0;

            //----------------------------------------------------
            // Process Valid Input
            //----------------------------------------------------

            if(valid_in)
            begin

                //------------------------------------------------
                // Insert Pilot
                //------------------------------------------------

                if(pilot_insert)
                begin

                    i_out <= PILOT_I;
                    q_out <= PILOT_Q;

                end

                //------------------------------------------------
                // Pass Data
                //------------------------------------------------

                else
                begin

                    i_out <= i_in;
                    q_out <= q_in;

                end

                //------------------------------------------------
                // Control Signals
                //------------------------------------------------

                valid_out <= 1'b1;

                sop_out <= sop_in;
                eop_out <= eop_in;

                //------------------------------------------------
                // Subcarrier Counter
                //------------------------------------------------

                if(carrier_cnt == FFT_SIZE-1)
                    carrier_cnt <= '0;
                else
                    carrier_cnt <= carrier_cnt + 1'b1;

            end

        end

    end
        //------------------------------------------------------------
    // Simulation Assertions
    //------------------------------------------------------------

`ifdef SIMULATION

    always_ff @(posedge clk)
    begin

        if(valid_out)
        begin

            //----------------------------------------------------
            // Counter Check
            //----------------------------------------------------

            assert(carrier_cnt < FFT_SIZE)
            else
                $error("LF_PILOT_INSERT : Invalid Carrier Index");

        end

    end

`endif

    //------------------------------------------------------------
    // Design Notes
    //------------------------------------------------------------
    //
    // Current Implementation:
    //  - Inserts one pilot every PILOT_INTERVAL carriers.
    //  - Pilot value = (PILOT_I, PILOT_Q)
    //
    // Future Improvements:
    //
    // 1. IEEE 802.11 Pilot Locations
    //    {-21,-7,+7,+21}
    //
    // 2. Configurable Pilot Pattern
    //
    // 3. Pseudo-Random Pilot Sequence
    //
    // 4. Dynamic Pilot Density
    //
    //------------------------------------------------------------

endmodule

`endif