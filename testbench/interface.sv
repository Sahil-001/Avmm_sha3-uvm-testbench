interface avmm_int(input logic clk,input logic rst);
   logic [7:0] avs_s0_address;
   logic       avs_s0_read;
   logic        avs_s0_write;
   logic [31:0] avs_s0_write_data;
   logic [31:0] avs_s0_read_data;
   logic 	avs_s0_wait_request;

   clocking cb_driver @(posedge clk);
      default input #5 output #2;
      input 	avs_s0_read_data,avs_s0_wait_request;
      output 	avs_s0_address,avs_s0_write_data,avs_s0_write,avs_s0_read;
      
   endclocking // cb_driver

   clocking cb_monitor @(posedge clk);
      default input #5 output #2;
      output 	avs_s0_read_data,avs_s0_wait_request;
      input 	avs_s0_address,avs_s0_write_data,avs_s0_write,avs_s0_read;
   endclocking // cb_monitor

   modport master (clocking cb_driver);
   modport slave (clocking cb_monitor);

endinterface // avmm_int

      
     
   
   
   
