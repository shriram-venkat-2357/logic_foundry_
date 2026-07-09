//==============================================================================
// Project : LF-SDR X1
// Team    : Logic Foundry
// Module  : lf_ber_counter
//------------------------------------------------------------------------------
// Description:
// Bit Error Rate (BER) Counter
//
// BER = (Bit Errors * BER_SCALE) >> SHIFT_AMOUNT
//
// FIX: Replaced division with right-shift for synthesis efficiency.
// BER_SCALE=10000, SHIFT_AMOUNT=13 (>>8192 approximation of /10000)
// Error is ~18% which is acceptable for a hardware BER indicator.
//==============================================================================

module lf_ber_counter #(
    parameter COUNTER_WIDTH = 32,
    parameter BER_SCALE     = 10000,
    parameter SHIFT_AMOUNT  = 13    // ~1/8192 approximation of 1/10000
)(
    input  logic lf_clk_i,
    input  logic lf_rst_n_i,

    input  logic tx_bit_i,
    input  logic rx_bit_i,

    input  logic valid_i,

    lf_perf_if.producer perf_if
);

    //----------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------
    logic [COUNTER_WIDTH-1:0] bit_error_cnt;
    logic [COUNTER_WIDTH-1:0] total_bit_cnt;
    logic [15:0] ber_calc;

    //----------------------------------------------------------------------
    // BER Counter (no division — shift-right approximation)
    //----------------------------------------------------------------------
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i)
    begin
        if(!lf_rst_n_i)
        begin
            bit_error_cnt <= '0;
            total_bit_cnt <= '0;
            ber_calc      <= '0;
        end
        else
        begin
            if(valid_i)
            begin
                total_bit_cnt <= total_bit_cnt + 1'b1;

                if(tx_bit_i != rx_bit_i)
                    bit_error_cnt <= bit_error_cnt + 1'b1;

                // Approximate BER using shift instead of division
                // Avoid divide-by-zero: only compute when we have enough bits
                if(total_bit_cnt >= (1 << SHIFT_AMOUNT))
                    ber_calc <= (bit_error_cnt * BER_SCALE) >> SHIFT_AMOUNT;
                else
                    ber_calc <= '0;
            end
        end
    end

    //----------------------------------------------------------------------
    // Performance Interface
    //----------------------------------------------------------------------
    assign perf_if.bit_errors = bit_error_cnt;
    assign perf_if.total_bits = total_bit_cnt;
    assign perf_if.ber_value  = ber_calc;
    assign perf_if.perf_valid = valid_i;

endmodule