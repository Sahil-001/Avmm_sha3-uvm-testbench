`ifndef _AVL_DRIVER_
`define _AVL_DRIVER_
`include "avl_seq_item.sv"
`include "sha3_top.sv"
class avl_driver #(int DW, int AW) extends uvm_driver #(avl_seq_item #(DW,AW));
   int BW;
   
   virtual avmm_int  vif;

    avl_seq_item #(DW,AW) req,rsp;

   `uvm_component_utils(avl_driver);
   
   function new(string name = "avl_driver", uvm_component parent = null);
      super.new(name,parent);
      BW = DW/8;
   endfunction // new

   
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      vif = sha3_top.d_intf;
   endfunction // build_phase
   
 
   virtual task run_phase(uvm_phase phase);
      begin
	 super.run_phase(phase);
	 get_and_drive(phase);
      end
   endtask // run_phase

    task write(input [7:0]  addr,
	      input [31:0] data);
      begin
	 @(vif.cb_driver);
	vif.avs_s0_address = addr;
	vif.avs_s0_writedata = data;
	vif.avs_s0_write = 1;
	vif.avs_s0_read = 0;
	 // avs_s0_chipselect = 0;
	 @(vif.cb_driver);
      end
   endtask // write

    task read(input [7:0] addr);
      begin
	 @(vif.cb_driver);
	 vif.avs_s0_address = addr;
	 vif.avs_s0_read = 1;
	 vif.avs_s0_write = 0;
      end
   endtask


   virtual protected task get_and_drive(uvm_phase phase);
      forever begin
         phase.drop_objection(this);
	 seq_item_port.get_next_item(req);
         phase.raise_objection(this);
	 $cast(rsp, req.clone());
	 rsp.set_id_info(req);
	 drive_transfer(rsp);
	 seq_item_port.item_done();
      end // forever begin
      
   endtask // get_and_drive
   
    virtual protected task drive_transfer (avl_seq_item req );
       fork
	  begin
	     
	  @(vif.cb_driver);
	  forever begin
	     while (vif.reset == 1'b1) begin
		@(vif.cb_driver);
	     end // while (reset == 1'b1)
	     
	     if (req.typ == 1) begin	// write
		write (req.addr, req.data);
	     end // if (flag == 1)
	     else begin
		read (req.addr);
	     end
	     while (vif.avs_s0_waitrequest) begin
		@(vif.cb_driver);
	     end
	     @(vif.cb_driver);
	     if (req.typ == 0) req.data =vif.avs_s0_readdata;
	     vif. avs_s0_address = 'bX;
	     vif. avs_s0_read = 0;
	     vif. avs_s0_writedata = 'bX;
	     vif. avs_s0_write = 0;
	     // avs_s0_chipselect = 0;
	  end // forever begin
	  end // fork begin
       join
    endtask // drive_transfer
   

endclass // avl_driver
`endif //  `ifndef _AVL_DRIVER_

