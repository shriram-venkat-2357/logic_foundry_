`timescale 1ns/1ps
`ifndef LF_S2P_SV
`define LF_S2P_SV

import LF_pkg::*;

module LF_S2P
#(
    parameter IQ_WIDTH = 16,
    parameter FFT_SIZE = 64
)
(
    input logic clk,
    input logic rst_n,

    //------------------------------------------------------------
    // Serial IQ Input
    //------------------------------------------------------------

    input logic signed [IQ_WIDTH-1:0] i_in,
    input logic signed [IQ_WIDTH-1:0] q_in,

    input logic valid_in,
    input logic sop_in,
    input logic eop_in,

    //------------------------------------------------------------
    // Parallel IQ Output
    //------------------------------------------------------------

    output logic signed [IQ_WIDTH-1:0] i_out [0:FFT_SIZE-1],
    output logic signed [IQ_WIDTH-1:0] q_out [0:FFT_SIZE-1],

    output logic frame_valid
);

    //------------------------------------------------------------
    // Internal Memories
    //------------------------------------------------------------

    logic signed [IQ_WIDTH-1:0] i_mem [0:FFT_SIZE-1];
    logic signed [IQ_WIDTH-1:0] q_mem [0:FFT_SIZE-1];

    //------------------------------------------------------------
    // Write Pointer
    //------------------------------------------------------------

    logic [$clog2(FFT_SIZE)-1:0] wr_ptr;

    integer k;
        //------------------------------------------------------------
    // Serial to Parallel Buffer
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            wr_ptr      <= '0;
            frame_valid <= 1'b0;

            for(k=0;k<FFT_SIZE;k=k+1)
            begin
                i_mem[k] <= '0;
                q_mem[k] <= '0;
            end

        end

        else
        begin

            //----------------------------------------------------
            // Default
            //----------------------------------------------------

            frame_valid <= 1'b0;

            //----------------------------------------------------
            // Store Incoming Symbol
            //----------------------------------------------------

            if(valid_in)
            begin

                i_mem[wr_ptr] <= i_in;
                q_mem[wr_ptr] <= q_in;

                //------------------------------------------------
                // Complete OFDM Symbol
                //------------------------------------------------

                if(wr_ptr == FFT_SIZE-1)
                begin

                    wr_ptr <= '0;

                    frame_valid <= 1'b1;

                end

                else
                begin

                    wr_ptr <= wr_ptr + 1'b1;

                end

            end

        end

    end

    //------------------------------------------------------------
    // Parallel Output
    //------------------------------------------------------------

    genvar g;

    generate

        for(g=0; g<FFT_SIZE; g=g+1)
        begin : OUTPUT_ASSIGN

            assign i_out[g] = i_mem[g];
            assign q_out[g] = q_mem[g];

        end

    endgenerate
        //------------------------------------------------------------
    // Simulation Assertions
    //------------------------------------------------------------

`ifdef SIMULATION

    always_ff @(posedge clk)
    begin

        if(valid_in)
        begin

            assert(wr_ptr < FFT_SIZE)
            else
                $error("LF_S2P : Write Pointer Overflow");

        end

    end

`endif

    //------------------------------------------------------------
    // Design Notes
    //------------------------------------------------------------
    //
    // Function:
    //   Converts serial complex symbols into one OFDM frame.
    //
    // Input:
    //   One complex symbol every valid clock.
    //
    // Output:
    //   FFT_SIZE complex symbols presented in parallel.
    //
    // frame_valid:
    //   Asserted for one clock when an OFDM symbol is complete.
    //
    //------------------------------------------------------------

endmodule

`endif