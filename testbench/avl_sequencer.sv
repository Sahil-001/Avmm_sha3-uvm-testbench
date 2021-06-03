`ifndef _AVL_SEQUENCER_
 `define _AVL_SEQUENCER_

`include "avl_seq_item.sv"
class avl_sequencer #(int DW, int AW) extends uvm_sequencer #(avl_seq_item #(DW,AW));
    `uvm_component_utils(avl_sequencer);
   function new(string name = "avl_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new

   uvm_seq_item_pull_port #(sha3_seq_item) sha3_get_port;

   virtual function void build_phase(uvm_phase phase);
      begin
	 super.build_phase(phase);
	 sha3_get_port = new("sha3_get_port",this);
      end
   endfunction // build_phase
endclass // avl_sequencer
`endif //  `ifndef _AVL_SEQUENCER_

   
