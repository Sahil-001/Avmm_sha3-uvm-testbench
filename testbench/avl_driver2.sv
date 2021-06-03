`ifndef _AVL_DRIVER_
`define _AVL_DRIVER_
`include "avl_seq_item.sv"
class avl_driver #(int DW = 32, int AW = 32) extends uvm_driver #(avl_seq_item);
   int BW ;
   avl_seq_item #(DW,AW) tr,req ;
   virtual avmm_int vif;
   `uvm_component_utils(avl_driver);
   
   function new(string name = "avl_driver", uvm_component parent = null);
      super.new(name,parent);
      BW = DW/8;
   endfunction // new


   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      vif = sha3_top.d_int;
   endfunction // build_phase
   
   

   virtual task run_phase(uvm_phase phase);
      begin
	 super.run_phase(phase);
	 while(1)
	   begin
	      seq_item_port.get_next_item(req);
	      `uvm_info("AVL TRANSACTION", req.sprint(), UVM_DEBUG);
	      write(req.addr,req.data);
	      seq_item_port.item_done();
	   end
      end
      
   endtask // run_phase

   task write(input [7:0]  addr,
	      input [31:0] data);
      begin
	 @(vif.cb_driver);
	 begin
	    vif.avs_s0_address = addr;
	    vif.avs_s0_writedata = data;
	    vif.avs_s0_write = 1;
	    vif.avs_s0_read = 0;
	    // avs_s0_chipselect = 0;
	 end
      end
   endtask // write


  
endclass // avl_driver
`endif //  `ifndef _AVL_DRIVER_
