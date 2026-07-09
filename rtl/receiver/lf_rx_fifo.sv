//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_rx_fifo
// Author  : Member-2
//------------------------------------------------------------------------------
// Description:
// Synchronous Receive FIFO
//
// Features:
// - Parameterized Data Width
// - Parameterized FIFO Depth
// - Single Clock
// - Active-Low Reset
// - Full & Empty Flags
// - Valid Output
// - Synthesizable
//==============================================================================

module lf_rx_fifo #(
    parameter int DATA_WIDTH = 16,
    parameter int FIFO_DEPTH = 16,
    parameter int ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  logic                     lf_clk_i,
    input  logic                     lf_rst_n_i,

    input  logic                     lf_wr_en_i,
    input  logic                     lf_rd_en_i,

    input  logic [DATA_WIDTH-1:0]    lf_data_i,

    output logic [DATA_WIDTH-1:0]    lf_data_o,
    output logic                     lf_valid_o,

    output logic                     lf_full_o,
    output logic                     lf_empty_o
);

    //--------------------------------------------------------------------------
    // Memory Array
    //--------------------------------------------------------------------------

    logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    //--------------------------------------------------------------------------
    // Pointers
    //--------------------------------------------------------------------------

    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;

    //--------------------------------------------------------------------------
    // FIFO Counter
    //--------------------------------------------------------------------------

    logic [ADDR_WIDTH:0] fifo_count;

    //--------------------------------------------------------------------------
    // Status Flags
    //--------------------------------------------------------------------------

    assign lf_empty_o = (fifo_count == 0);
    assign lf_full_o  = (fifo_count == FIFO_DEPTH);

    //--------------------------------------------------------------------------
    // FIFO Logic
    //--------------------------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            wr_ptr      <= '0;
            rd_ptr      <= '0;
            fifo_count  <= '0;

            lf_data_o   <= '0;
            lf_valid_o  <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------------------
            // Default
            //--------------------------------------------------------------

            lf_valid_o <= 1'b0;

            //--------------------------------------------------------------
            // WRITE
            //--------------------------------------------------------------

            if(lf_wr_en_i && !lf_full_o)
            begin

                fifo_mem[wr_ptr] <= lf_data_i;

                if(wr_ptr == FIFO_DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end

            //--------------------------------------------------------------
            // READ
            //--------------------------------------------------------------

            if(lf_rd_en_i && !lf_empty_o)
            begin

                lf_data_o  <= fifo_mem[rd_ptr];
                lf_valid_o <= 1'b1;

                if(rd_ptr == FIFO_DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end

            //--------------------------------------------------------------
            // COUNT UPDATE
            //--------------------------------------------------------------

            case({lf_wr_en_i && !lf_full_o,
                  lf_rd_en_i && !lf_empty_o})

                2'b10 :
                    fifo_count <= fifo_count + 1'b1;

                2'b01 :
                    fifo_count <= fifo_count - 1'b1;

                default :
                    fifo_count <= fifo_count;

            endcase

        end

    end

endmodule
