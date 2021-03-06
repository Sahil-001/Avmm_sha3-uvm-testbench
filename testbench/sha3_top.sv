module sha3_top;
   bit clk;
   bit reset;
   avmm_int d_intf(clk,reset);

    initial begin
      clk = 0;
      forever begin
	 #10;
	 clk = ~clk;
      end
    end

    initial begin
      reset = 0;
      #10;
      reset = 1;
      #100;
      reset = 0;
      // #1000000;
      // $finish;
   end

   initial 
    begin
      $dumpfile("avmm_sha3.vcd");
      $dumpvars(0, sha3_top);
   end // initial begin
   
   avalon_sha3_wrapper u_sha3(/*AUTOINST*/
			      // Outputs
			      .avs_s0_readdata	  (d_intf.avs_s0_read_data),
			      .avs_s0_waitrequest (d_intf.avs_s0_wait_request),
			      // Inputs
			      .clk		  (clk),
			      .reset		  (reset),
			      // .avs_s0_chipselect  (avs_s0_chipselect),
			      .avs_s0_address	  (d_intf.avs_s0_address),
			      .avs_s0_read	  (d_intf.avs_s0_read),
			      .avs_s0_write	  (d_intf.avs_s0_write),
			      .avs_s0_writedata	  (d_intf.avs_s0_write_data));
endmodule // sha3_top



   

  
