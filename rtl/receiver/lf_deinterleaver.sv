//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_deinterleaver
//------------------------------------------------------------------------------
// Description:
// 4x4 Block Deinterleaver (ROW=4, COL=4, DEPTH=16)
//
// FIX: Replaced % and / with bit operations.
// COLS=4=2^2, so: row = idx >> 2, col = idx & 3
// Address = col * ROWS + row
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

    localparam int DEPTH = ROWS * COLS;

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
            // WRITE — row-major order (sequential)
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
            // READ — column-major order (deinterleaved)
            // FIX: No division or modulo — uses shifts & masks
            // COLS=4=2^2, so >>2 = /4, &3 = %4
            //--------------------------------------------
            READ:
            begin
                // Read address = col * ROWS + row
                // row = rd_cnt >> $clog2(COLS)
                // col = rd_cnt & (COLS - 1)
                lf_bit_o   <= mem[(rd_cnt & (COLS-1)) * ROWS + (rd_cnt >> $clog2(COLS))];
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