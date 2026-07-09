   `timescale 1ns/1ps

   module tb_awgn;

       logic lf_clk_i, lf_rst_n_i;
       logic [7:0] noise_level_i;
       logic [15:0] lf_data_i, lf_data_o;
       logic lf_valid_i, lf_valid_o, lf_ready_i, lf_ready_o;

       // Instantiate DUT
       lf_awgn #(.DATA_WIDTH(16)) u_dut (
           .lf_clk_i(lf_clk_i), .lf_rst_n_i(lf_rst_n_i), .noise_level_i(noise_level_i),
           .lf_data_i(lf_data_i), .lf_valid_i(lf_valid_i), .lf_ready_o(lf_ready_o),
           .lf_data_o(lf_data_o), .lf_valid_o(lf_valid_o), .lf_ready_i(lf_ready_i)
       );

       // Clock generation
       always #10 lf_clk_i = ~lf_clk_i;

       // Error counting variables
       int total_bits = 0;
       int error_bits = 0;
       real ber;

       initial begin
           $dumpfile("waves/tb_awgn.fst");
           $dumpvars(0, tb_awgn);
           
           lf_clk_i = 0; lf_rst_n_i = 0; 
           lf_data_i = 16'h0000; // Send all zeros to easily count flipped bits
           lf_valid_i = 0; lf_ready_i = 1;
           noise_level_i = 8'd0; // Start clean
           
           #50; lf_rst_n_i = 1; #20;
           
           $display("========================================");
           $display("  LF_AWGN NOISE MODULE TEST STARTED");
           $display("========================================");

           // TEST 1: Clean Channel (Noise = 0)
           $display("[TEST 1] Noise Level: 0 (Clean Channel)");
           run_noise_test(8'd0);

           // TEST 2: Low Noise (Noise = 50)
           $display("[TEST 2] Noise Level: 50 (Low Noise)");
           run_noise_test(8'd50);

           // TEST 3: High Noise (Noise = 200)
           $display("[TEST 3] Noise Level: 200 (High Noise)");
           run_noise_test(8'd200);

           $display("========================================");
           $display("  LF_AWGN MODULE TEST COMPLETE");
           $display("========================================");
           $finish;
       end

       // Task to run a specific noise level and calculate BER
       task run_noise_test(input logic [7:0] level);
           total_bits = 0;
           error_bits = 0;
           noise_level_i = level;
           lf_valid_i = 1;
           
           // Send 1000 packets of zeros
           repeat (1000) begin
               lf_data_i = 16'h0000;
               while (!lf_ready_o) @(posedge lf_clk_i);
               @(posedge lf_clk_i);
           end
           lf_valid_i = 0;
           repeat (5) @(posedge lf_clk_i);
           
           ber = (total_bits > 0) ? real'(error_bits) / real'(total_bits) : 0.0;
           $display("  -> Total Bits: %0d | Flipped Bits: %0d | Simulated BER: %f", total_bits, error_bits, ber);
       endtask

       // Monitor: Check output against expected (all zeros)
       always @(posedge lf_clk_i) begin
           if (lf_rst_n_i && lf_valid_o && lf_ready_i) begin
               total_bits += 16;
               // Count how many bits are 1 (since we sent all 0s, any 1 is an error)
               for (int i = 0; i < 16; i++) begin
                   if (lf_data_o[i] == 1'b1) error_bits++;
               end
           end
       end

   endmodule
