`ifndef _SHA3_AGENT_
 `define  _SHA3_AGENT_

`include "sha3_sequencer.sv"
class sha3_agent extends uvm_agent;
   `uvm_component_utils(sha3_agent)
      
      function new(string name = "sha3_agent", uvm_component parent = null);
	 super.new(name,parent);
      endfunction // new
      
       sha3_sequencer sequencer;
      
      virtual function void  build_phase(uvm_phase phase);
	 begin
	    super.build_phase(phase);
	    sequencer = sha3_sequencer::type_id::create("sequencer",this);
	 end
      endfunction // build_phase
      	 
endclass // sha3_agent
`endif //  `ifndef _SHA3_AGENT_

   
