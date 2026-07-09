//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_frame_detect
//------------------------------------------------------------------------------
// Description
//
// Detects the OFDM frame by comparing the incoming samples against
// a programmable synchronization word.
//
// Industry Coding Style
// - Sliding Window Register
// - Registered Outputs
// - Parameterized Preamble
//==============================================================================

module lf_frame_detect #(

    parameter int DATA_WIDTH = 16,

    parameter logic [DATA_WIDTH-1:0] PREAMBLE = 16'hA5C3

)(

    input logic lf_clk_i,
    input logic lf_rst_n_i,

    input logic [DATA_WIDTH-1:0] lf_data_i,
    input logic lf_valid_i,

    output logic lf_frame_detect_o,
    output logic [DATA_WIDTH-1:0] lf_data_o,
    output logic lf_valid_o

);

    //----------------------------------------------------------
    // Sliding Register
    //----------------------------------------------------------

    logic [DATA_WIDTH-1:0] shift_reg;
    logic [$clog2(8)-1:0] match_cnt;
    localparam int PREAMBLE_REPEAT = 3;

    //----------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------

    logic frame_match;

    //----------------------------------------------------------
    // Combinational Comparator
    //----------------------------------------------------------

    always_comb
    begin

        frame_match = (shift_reg == PREAMBLE);

    end

    //----------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin

        if(!lf_rst_n_i)
        begin

            shift_reg          <= '0;
            lf_data_o          <= '0;
            lf_valid_o         <= 1'b0;
            lf_frame_detect_o  <= 1'b0;
            match_cnt          <= '0;
        end

        else
        begin

            //--------------------------
            // Defaults
            //--------------------------

            lf_valid_o        <= 1'b0;
            lf_frame_detect_o <= 1'b0;

            if(lf_valid_i)
            begin

                //--------------------------------------
                // Shift Incoming Data
                //--------------------------------------

                shift_reg <= lf_data_i;

                //--------------------------------------
                // Forward Data
                //--------------------------------------

                lf_data_o  <= lf_data_i;
                lf_valid_o <= 1'b1;

                //--------------------------------------
                // Detect Frame
                //--------------------------------------

                if(frame_match) begin
                    if(match_cnt < PREAMBLE_REPEAT - 1)
                        match_cnt <= match_cnt + 1'b1;
                    if(match_cnt == PREAMBLE_REPEAT - 1)
                        lf_frame_detect_o <= 1'b1;
                end else begin
                    match_cnt <= '0;
                end

            end

        end

    end

endmodule
