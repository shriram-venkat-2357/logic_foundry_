`timescale 1ns/1ps
`ifndef LF_INTERLEAVER_SV
`define LF_INTERLEAVER_SV

import LF_pkg::*;

module LF_INTERLEAVER
#(
    parameter DATA_WIDTH = 16,
    parameter BLOCK_SIZE = 64
)
(
    input  logic                     clk,
    input  logic                     rst_n,

    //------------------------------------------------------------
    // Input Stream
    //------------------------------------------------------------

    input  logic [DATA_WIDTH-1:0]    data_in,
    input  logic                     valid_in,
    input  logic                     sop_in,
    input  logic                     eop_in,

    //------------------------------------------------------------
    // Output Stream
    //------------------------------------------------------------

    output logic [DATA_WIDTH-1:0]    data_out,
    output logic                     valid_out,
    output logic                     sop_out,
    output logic                     eop_out
);

    //------------------------------------------------------------
    // Memory
    //------------------------------------------------------------

    logic [DATA_WIDTH-1:0] mem [0:BLOCK_SIZE-1];

    //------------------------------------------------------------
    // Address Counters
    //------------------------------------------------------------

    logic [$clog2(BLOCK_SIZE)-1:0] wr_ptr;
    logic [$clog2(BLOCK_SIZE)-1:0] rd_ptr;

    logic write_done;
    logic read_enable;

    //------------------------------------------------------------
    // FSM
    //------------------------------------------------------------

    typedef enum logic [1:0]
    {
        IDLE,
        WRITE,
        READ
    } state_t;

    state_t state;
    state_t next_state;
    //------------------------------------------------------------
    // State Register
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    end

    //------------------------------------------------------------
    // Next State Logic
    //------------------------------------------------------------

    always_comb
    begin

        next_state = state;

        case(state)

            //----------------------------------------------------
            // Wait for packet
            //----------------------------------------------------

            IDLE:
            begin

                if(valid_in && sop_in)
                    next_state = WRITE;

            end

            //----------------------------------------------------
            // Store incoming symbols
            //----------------------------------------------------

            WRITE:
            begin

                if(write_done)
                    next_state = READ;

            end

            //----------------------------------------------------
            // Read interleaved symbols
            //----------------------------------------------------

            READ:
            begin

                if(rd_ptr == BLOCK_SIZE-1)
                    next_state = IDLE;

            end

            default:
                next_state = IDLE;

        endcase

    end

    //------------------------------------------------------------
    // Write Logic
    //------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            wr_ptr     <= '0;
            write_done <= 1'b0;

        end

        else
        begin

            write_done <= 1'b0;

            if(state == WRITE)
            begin

                if(valid_in)
                begin

                    //------------------------------------------------
                    // Store incoming word
                    //------------------------------------------------

                    mem[wr_ptr] <= data_in;

                    //------------------------------------------------
                    // End of Block
                    //------------------------------------------------

                    if(wr_ptr == BLOCK_SIZE-1)
                    begin

                        wr_ptr     <= '0;
                        write_done <= 1'b1;

                    end

                    else
                    begin

                        wr_ptr <= wr_ptr + 1'b1;

                    end

                end

            end

            else if(state == IDLE)
            begin

                wr_ptr <= '0;

            end

        end

    end