// tb/lf_driver.sv
// Drives packets into TX and controls channel configuration

module lf_driver #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_PACKETS  = 100,
    parameter PACKET_LEN   = 64    // Words per packet
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

    enum logic [2:0] {IDLE, START, SEND_PACKET, INTER_PACKET_GAP, DONE} state;

    assign lf_start_o = (state == START);

    // Pseudo-random payload generator
    always_ff @(posedge lf_clk_i) begin
        seed <= seed * 32'd1103515245 + 32'd12345; // LCG
    end
    assign payload_data = seed[DATA_WIDTH-1:0];

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i) begin
            state         <= IDLE;
            packet_count  <= 0;
            word_count    <= 0;
            lf_data_o     <= '0;
            lf_valid_o    <= 0;
            noise_level_o <= 8'd0;
            tx_done_o     <= 0;
            seed          <= 32'd42;
        end else begin
            case (state)
                IDLE: begin
                    state <= START;
                end

                START: begin
                    lf_start_o <= 1;
                    noise_level_o <= 8'd20; // Start with low noise
                    state <= SEND_PACKET;
                end

                SEND_PACKET: begin
                    lf_valid_o <= 1;
                    if (lf_ready_i) begin
                        lf_data_o <= payload_data;
                        word_count <= word_count + 1;
                        if (word_count == PACKET_LEN - 1) begin
                            word_count <= 0;
                            packet_count <= packet_count + 1;
                            lf_valid_o <= 0;
                            if (packet_count >= NUM_PACKETS - 1) begin
                                state <= DONE;
                            end else begin
                                state <= INTER_PACKET_GAP;
                            end
                        end
                    end
                end

                INTER_PACKET_GAP: begin
                    lf_valid_o <= 0;
                    repeat (10) @(posedge lf_clk_i);
                    state <= SEND_PACKET;
                end

                DONE: begin
                    lf_valid_o <= 0;
                    tx_done_o  <= 1;
                    $display("[DRIVER] All %0d packets sent.", NUM_PACKETS);
                end
            endcase
        end
    end

endmodule
