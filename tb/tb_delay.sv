   `timescale 1ns/1ps

   module tb_delay;

       logic lf_clk_i, lf_rst_n_i;
       logic [3:0] delay_cfg_i;
       logic [15:0] lf_data_i, lf_data_o;
       logic lf_valid_i, lf_valid_o, lf_ready_i, lf_ready_o;

       // Instantiate DUT
       lf_delay #(.DATA_WIDTH(16)) u_dut (
           .lf_clk_i(lf_clk_i), .lf_rst_n_i(lf_rst_n_i), .delay_cfg_i(delay_cfg_i),
           .lf_data_i(lf_data_i), .lf_valid_i(lf_valid_i), .lf_ready_o(lf_ready_o),
           .lf_data_o(lf_data_o), .lf_valid_o(lf_valid_o), .lf_ready_i(lf_ready_i)
       );

       // Clock generation
       always #10 lf_clk_i = ~lf_clk_i;

       initial begin
           $dumpfile("waves/tb_delay.fst");
           $dumpvars(0, tb_delay);
           
           lf_clk_i = 0; lf_rst_n_i = 0; delay_cfg_i = 4'd2; // 2 cycles delay
           lf_data_i = 0; lf_valid_i = 0; lf_ready_i = 1;
           
           #50; lf_rst_n_i = 1; #20;
           
           $display("========================================");
           $display("  LF_DELAY MODULE TEST STARTED");
           $display("========================================");
           
           // Send 5 packets
           for (int i = 0; i < 5; i++) begin
               lf_data_i = i * 100; // 0, 100, 200, 300, 400
               lf_valid_i = 1;
               while (!lf_ready_o) @(posedge lf_clk_i);
               @(posedge lf_clk_i);
           end
           lf_valid_i = 0;
           
           // Wait for pipeline to drain
           repeat (10) @(posedge lf_clk_i);
           
           $display("========================================");
           $display("  LF_DELAY MODULE TEST COMPLETE");
           $display("========================================");
           $finish;
       end
       
       // Monitor to print received data
       always @(posedge lf_clk_i) begin
           if (lf_rst_n_i && lf_valid_o && lf_ready_i) begin
               $display("[%0t] RX Data: %0d", $time, lf_data_o);
           end
       end

   endmodule
