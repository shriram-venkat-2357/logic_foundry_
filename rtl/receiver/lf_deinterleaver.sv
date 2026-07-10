//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_deinterleaver
//------------------------------------------------------------------------------
// Description:
// Simple 4x4 Block Deinterleaver
//
// Industry Style:
// - Parameterized
// - Registered Outputs 
// - FSM Controlled
//==============================================================================

module lf_deinterleaver #(

    parameter int ROWS = 4,
    parameter int COLS = 4

)(

    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    input  logic lf_valid_i,
    input  logic lf_bit_i,

    output logic lf_valid_o,
    output logic lf_bit_o

);

    localparam int DEPTH = ROWS*COLS;

    //----------------------------------------------------------
    // Memory
    //----------------------------------------------------------

    logic mem [0:DEPTH-1];

    //----------------------------------------------------------
    // Counters
    //----------------------------------------------------------

    logic [$clog2(DEPTH):0] wr_cnt;
    logic [$clog2(DEPTH):0] rd_cnt;

    //----------------------------------------------------------
    // FSM
    //----------------------------------------------------------

    typedef enum logic [1:0] {

        IDLE,
        WRITE,
        READ

    } state_t;

    state_t state;

    integer row,col;

    //----------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            state      <= IDLE;
            wr_cnt     <= 0;
            rd_cnt     <= 0;
            lf_valid_o <= 0;
            lf_bit_o   <= 0;

        end

        else
        begin

            lf_valid_o <= 0;

            case(state)

            //--------------------------------------------
            // IDLE
            //--------------------------------------------

            IDLE:

                if(lf_valid_i)
                begin

                    mem[0] <= lf_bit_i;
                    wr_cnt <= 1;
                    state  <= WRITE;

                end

            //--------------------------------------------
            // WRITE
            //--------------------------------------------

            WRITE:

                if(lf_valid_i)
                begin

                    mem[wr_cnt] <= lf_bit_i;

                    if(wr_cnt == DEPTH-1)
                    begin

                        wr_cnt <= 0;
                        rd_cnt <= 0;
                        state  <= READ;

                    end

                    else

                        wr_cnt <= wr_cnt + 1;

                end

            //--------------------------------------------
            // READ
            //--------------------------------------------

            READ:

                begin

                    row = rd_cnt % ROWS;
                    col = rd_cnt / ROWS;

                    lf_bit_o   <= mem[row*COLS + col];
                    lf_valid_o <= 1;

                    if(rd_cnt == DEPTH-1)

                        state <= IDLE;

                    else

                        rd_cnt <= rd_cnt + 1;

                end

            endcase

        end

    end

endmodule
