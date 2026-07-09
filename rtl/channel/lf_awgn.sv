// channel/lf_awgn.sv
module lf_awgn #(
    parameter DATA_WIDTH = 16
)(
    input  logic                   lf_clk_i,
    input  logic                   lf_rst_n_i,
    input  logic                   lf_valid_i,
    input  logic [DATA_WIDTH-1:0]  lf_data_i,
    input  logic [7:0]             noise_level_i, // 0=clean, 255=max noise
    output logic                   lf_ready_o,

    output logic [DATA_WIDTH-1:0]  lf_data_o,
    output logic                   lf_valid_o,
    input  logic                   lf_ready_i
);

    // 32-bit LFSR for pseudo-random noise
    logic [31:0] lfsr;
    logic [31:0] lfsr_next;
    logic [DATA_WIDTH-1:0] noise_mask;

    // Galois LFSR (fast, good randomness)
    always_comb begin
        lfsr_next = lfsr;
        if (lfsr[0])
            lfsr_next = (lfsr >> 1) ^ 32'hD0000001; // Polynomial
        else
            lfsr_next = lfsr >> 1;
    end

    always_ff @(posedge lf_clk_i or negedge lf_rst_n_i) begin
        if (!lf_rst_n_i)
            lfsr <= 32'hACE1ACE1; // Seed
        else if (lf_valid_i && lf_ready_o)
            lfsr <= lfsr_next;
    end

    // Generate noise mask: compare each LFSR bit against noise_level
    always_comb begin
        for (int i = 0; i < DATA_WIDTH; i++) begin
            // Higher noise_level = more bits flipped
            noise_mask[i] = (lfsr[i*2 +: 8] < noise_level_i) ? 1'b1 : 1'b0;
        end
    end

    // Apply noise (XOR flips bits)
    assign lf_data_o  = lf_data_i ^ noise_mask;
    assign lf_valid_o = lf_valid_i;
    assign lf_ready_o = lf_ready_i; // Pass-through ready

endmodule
