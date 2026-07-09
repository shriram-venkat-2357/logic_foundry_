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

    //------------------------------------------------------------
    // Interleaving Parameters (row-major write, column-major read)
    //------------------------------------------------------------

    localparam ROWS = 8;
    localparam COLS = (BLOCK_SIZE / ROWS); // 8

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
            IDLE:
            begin
                if(valid_in && sop_in)
                    next_state = WRITE;
            end

            WRITE:
            begin
                if(write_done)
                    next_state = READ;
            end

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
    // Write Logic (row-major: sequential write)
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
                    mem[wr_ptr] <= data_in;

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

    //------------------------------------------------------------
    // Read Logic (column-major: interleaved read)
    // Row = rd_ptr / COLS, Col = rd_ptr % COLS
    // Use shift instead of division: COLS=8, >>3
    //------------------------------------------------------------

    logic [$clog2(BLOCK_SIZE)-1:0] read_row;
    logic [$clog2(BLOCK_SIZE)-1:0] read_col;
    logic [$clog2(BLOCK_SIZE)-1:0] read_addr;

    // COLS = 8 = 2^3, so divide by 8 = right-shift by 3
    assign read_row = rd_ptr >> $clog2(COLS);
    assign read_col = rd_ptr & (COLS - 1);  // modulo power-of-2 = bit mask
    assign read_addr = read_col * ROWS + read_row;

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            rd_ptr    <= '0;
            data_out  <= '0;
            valid_out <= 1'b0;
            sop_out   <= 1'b0;
            eop_out   <= 1'b0;
        end
        else
        begin
            valid_out <= 1'b0;
            sop_out   <= 1'b0;
            eop_out   <= 1'b0;

            if(state == READ)
            begin
                data_out  <= mem[read_addr];
                valid_out <= 1'b1;

                // SOP on first read word
                if(rd_ptr == '0)
                    sop_out <= 1'b1;

                // EOP on last read word
                if(rd_ptr == BLOCK_SIZE-1)
                    eop_out <= 1'b1;

                if(rd_ptr == BLOCK_SIZE-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule

`endif