// tb/lf_driver.sv
// Drives packets into TX and controls channel configuration
//
// FIX: Removed combinational assign of lf_start_o (original line 32).
//      lf_start_o is now ONLY driven inside always_ff, avoiding
//      multi-driver conflict between continuous assign and procedural block.

module lf_driver #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_PACKETS  = 100,
    parameter PACKET_LEN   = 64
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,

    // TX Input
    output logic [DATA_WIDTH-1:0]  lf_data_o,
    output logic                   lf_valid_o,
    input  logic                   lf_ready_i,

    // Control
    output logic                   lf_start_o,
    output logic [7:0]             noise_level_o,
    output logic                   tx_done_o
);

    logic [31:0] packet_count;
    logic [31:0] word_count;
    logic [31:0] seed;
    logic [DATA_WIDTH-1:0] payload_data;

    logic [3:0] gap_counter;

    enum logic [2:0] {IDLE, START, SEND_PACKET, INTER_PACKET_GAP, DONE} state;

    // Pseudo-random payload generator (free-running LCG)
    always_ff @(posedge lf_clk_i) begin
        seed <= seed * 32'd1103515245 + 32'd12345;
    end
    assign payload_data = seed[DATA_WIDTH-1:0];

    // FIX: lf_start_o is ONLY driven inside always_ff (no concurrent assign)
    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i) begin
            state         <= IDLE;
            packet_count  <= 0;
            word_count    <= 0;
            lf_data_o     <= '0;
            lf_valid_o    <= 1'b0;
            lf_start_o    <= 1'b0;
            noise_level_o <= 8'd0;
            tx_done_o     <= 1'b0;
            seed          <= 32'd42;
            gap_counter   <= 0;
        end else begin
            // Default: deassert pulse signals each cycle
            lf_start_o <= 1'b0;

            case (state)
                IDLE: begin
                    state <= START;
                end

                START: begin
                    lf_start_o    <= 1'b1;  // Single-cycle pulse
                    noise_level_o <= 8'd20;
                    state <= SEND_PACKET;
                end

                SEND_PACKET: begin
                    lf_valid_o <= 1'b1;
                    if (lf_ready_i) begin
                        lf_data_o <= payload_data;
                        word_count <= word_count + 1;
                        if (word_count == PACKET_LEN - 1) begin
                            word_count <= 0;
                            packet_count <= packet_count + 1;
                            lf_valid_o <= 1'b0;
                            if (packet_count >= NUM_PACKETS - 1) begin
                                state <= DONE;
                            end else begin
                                state <= INTER_PACKET_GAP;
                            end
                        end
                    end
                end

                INTER_PACKET_GAP: begin
                    lf_valid_o <= 1'b0;
                    gap_counter <= gap_counter + 1'b1;
                    if (gap_counter >= 4'd9) begin
                        gap_counter <= 0;
                        state <= SEND_PACKET;
                    end
                end

                DONE: begin
                    lf_valid_o <= 1'b0;
                    tx_done_o  <= 1'b1;
                    $display("[DRIVER] All %0d packets sent.", NUM_PACKETS);
                end
            endcase
        end
    end

endmodule