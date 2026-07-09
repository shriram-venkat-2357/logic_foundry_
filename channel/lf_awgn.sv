// channel/lf_awgn.sv
// Fixed: Replace dynamic bit-slice with static slicing for better synthesis

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

    // Generate noise mask: use static bit slices for synthesis optimization
    always_comb begin
        // Extract 8-bit slices from LFSR and compare against noise_level
        logic [7:0] lfsr_slice_0, lfsr_slice_1, lfsr_slice_2, lfsr_slice_3;
        
        lfsr_slice_0 = lfsr[7:0];
        lfsr_slice_1 = lfsr[15:8];
        lfsr_slice_2 = lfsr[23:16];
        lfsr_slice_3 = lfsr[31:24];
        
        // Apply noise threshold comparisons
        for (int i = 0; i < DATA_WIDTH; i++) begin
            // Select which LFSR slice based on bit position
            logic [7:0] selected_slice;
            case (i >> 2)  // Divide by 4 to select slice
                2'b00: selected_slice = lfsr_slice_0;
                2'b01: selected_slice = lfsr_slice_1;
                2'b10: selected_slice = lfsr_slice_2;
                default: selected_slice = lfsr_slice_3;
            endcase
            
            // Higher noise_level = more bits flipped
            noise_mask[i] = (selected_slice < noise_level_i) ? 1'b1 : 1'b0;
        end
    end

    // Apply noise (XOR flips bits)
    assign lf_data_o  = lf_data_i ^ noise_mask;
    assign lf_valid_o = lf_valid_i;
    assign lf_ready_o = lf_ready_i; // Pass-through ready

endmodule
