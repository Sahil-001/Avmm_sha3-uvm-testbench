`ifndef _AVL_AGENT_
 `define _AVL_AGENT_

`include "avl_driver2.sv"
`include "avl_sequencer.sv"
`include "sha3_monitor2.sv"
class avl_agent #(int DW,int AW) extends uvm_agent;
    `uvm_component_utils(avl_agent);
   
   function new(string name = "avl_agent", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new

   avl_driver #(DW , AW) driver;
   avl_sequencer #(DW, AW)  sequencer;
   sha3_monitor #(DW,AW) monitor;

   virtual function void build_phase(uvm_phase phase);
      begin
	 super.build_phase(phase);
	 driver =  avl_driver #(DW , AW)::type_id::create("driver",this);
         sequencer =  avl_sequencer #(DW, AW)::type_id::create("sequencer",this);
         monitor = sha3_monitor #(DW,AW)::type_id::create("monitor",this);
      end
   endfunction // build_phase

   virtual function void connect_phase(uvm_phase phase);
      begin
	 super.connect_phase(phase);
	 if(get_is_active() == UVM_ACTIVE)
	   driver.seq_item_port.connect(sequencer.seq_item_export);
      end
   endfunction // connect_phase
endclass // avl_agent
`endif //  `ifndef _AVL_AGENT_

	 
