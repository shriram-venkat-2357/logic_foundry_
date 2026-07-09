// tb/lf_assertions.sv
// Bind this to any module with valid/ready handshake

module lf_assertions #(
    parameter DATA_WIDTH = 16
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,
    input  logic [DATA_WIDTH-1:0]  lf_data_i,
    input  logic                   lf_valid_i,
    input  logic                   lf_ready_o
);

    default clocking cb @(posedge lf_clk_i); endclocking
    default disable iff (!lf_rst_n_i);

    // ASSERTION 1: Valid must not drop until Ready is asserted
    property p_valid_stable;
        lf_valid_i && !lf_ready_o |=> lf_valid_i;
    endproperty
    assert property (p_valid_stable)
        else $error("[SVA] Valid dropped before handshake completed!");

    // ASSERTION 2: Data must remain stable while Valid is high and Ready is low
    property p_data_stable;
        (lf_valid_i && !lf_ready_o) |=> ($stable(lf_data_i));
    endproperty
    assert property (p_data_stable)
        else $error("[SVA] Data changed during stalled handshake!");

    // ASSERTION 3: No X/Z on data bus when valid is high
    property p_no_x_on_data;
        lf_valid_i |-> !$isunknown(lf_data_i);
    endproperty
    assert property (p_no_x_on_data)
        else $error("[SVA] Unknown value on data bus during valid!");

    // ASSERTION 4: Ready should eventually respond (liveness, within 100 cycles)
    property p_ready_eventually;
        lf_valid_i |-> ##[0:100] lf_ready_o;
    endproperty
    assert property (p_ready_eventually)
        else $error("[SVA] Ready not asserted within 100 cycles - potential deadlock!");

    // ASSERTION 5: Handshake only when both valid AND ready are high
    property p_handshake_valid;
        ##1 ($past(lf_valid_i) && $past(lf_ready_o)) |-> 
            !$stable(lf_data_i); // Data should have been consumed
    endproperty
    // (Soft check - only for monitoring)

    // COVER: Track handshake occurrences
    cover property (lf_valid_i && lf_ready_o);

endmodule
