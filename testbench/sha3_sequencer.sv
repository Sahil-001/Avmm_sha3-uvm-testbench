`ifndef _SHA3_SEQUENCER_
 `define  _SHA3_SEQUENCER_

`include "sha3_seq_item.sv"
   
class sha3_sequencer extends uvm_sequencer #(sha3_seq_item);
   `uvm_component_utils(sha3_sequencer);
   function new(string name = "sha3_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new
endclass // sha3_sequencer
`endif //  `ifndef _SHA3_SEQUENCER_


   


   
	  
     
