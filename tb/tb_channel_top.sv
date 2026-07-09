   `timescale 1ns/1ps

   module tb_channel_top;

       logic lf_clk_i, lf_rst_n_i;
       logic [3:0] delay_cfg_i;
       logic [7:0] noise_level_i, freq_offset_cfg_i, drift_cfg_i;
       logic [15:0] lf_tx_data_i, lf_rx_data_o;
       logic lf_tx_valid_i, lf_tx_ready_o, lf_rx_valid_o, lf_rx_ready_i;

       // Instantiate the Master Channel
       lf_channel_top #(.DATA_WIDTH(16)) u_dut (
           .lf_clk_i, .lf_rst_n_i,
           .delay_cfg_i, .noise_level_i, .freq_offset_cfg_i, .drift_cfg_i,
           .lf_tx_data_i, .lf_tx_valid_i, .lf_tx_ready_o,
           .lf_rx_data_o, .lf_rx_valid_o, .lf_rx_ready_i
       );

       always #10 lf_clk_i = ~lf_clk_i;

       initial begin
           $dumpfile("waves/tb_channel_top.fst");
           $dumpvars(0, tb_channel_top);
           
           lf_clk_i = 0; lf_rst_n_i = 0; 
           lf_tx_data_i = 0; lf_tx_valid_i = 0; lf_rx_ready_i = 1;
           
           // Configure a "Hostile" Channel
           delay_cfg_i       = 4'd3;  // 3 cycles delay
           noise_level_i     = 8'd50; // Medium noise
           freq_offset_cfg_i = 8'd10; // Medium freq offset
           drift_cfg_i       = 8'd0;  // No drift for this quick test
           
           #50; lf_rst_n_i = 1; #20;
           
           $display("========================================");
           $display("  HOSTILE CHANNEL TOP TEST STARTED");
           $display("  Config: Delay=3, Noise=50, Freq=10");
           $display("========================================");
           
           // Send 10 packets
           for (int i = 0; i < 10; i++) begin
               lf_tx_data_i = 16'hAAAA ^ i; // Alternating bits with variation
               lf_tx_valid_i = 1;
               while (!lf_tx_ready_o) @(posedge lf_clk_i);
               @(posedge lf_clk_i);
           end
           lf_tx_valid_i = 0;
           
           repeat (20) @(posedge lf_clk_i);
           
           $display("========================================");
           $display("  HOSTILE CHANNEL TEST COMPLETE");
           $display("========================================");
           $finish;
       end
       
       // Monitor RX output
       always @(posedge lf_clk_i) begin
           if (lf_rst_n_i && lf_rx_valid_o && lf_rx_ready_i) begin
               $display("[%0t] RX Data (Corrupted): %h", $time, lf_rx_data_o);
           end
       end

   endmodule
