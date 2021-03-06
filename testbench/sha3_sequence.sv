`ifndef _SHA3_SEQUENCE_
 `define  _SHA3_SEQUENCE_

`include "sha3_sequencer.sv"
   
class sha3_sequence extends uvm_sequence #(sha3_seq_item);
   `uvm_object_utils(sha3_sequence)
   sha3_sequencer sequencer;
   output_size_enum out_size;
   string phrase;

   function void set_phrase(string ph);
      phrase = ph;
   endfunction // set_phrase

   function void set_outputsize(output_size_enum os);
      out_size = os;
   endfunction // set_outputsize
   

   function new(string name = "sha3_sequence");
      super.new(name);
      req = REQ::type_id::create("req");
   endfunction // new

  virtual task body();
      for(int i=0; i!=1;i++)
	begin
	   REQ tr;
	   req.randomize();
	   `uvm_info("PRINTREQUEST", req.sprint(), UVM_DEBUG)
	   $cast(tr , req.clone());
	   start_item(tr);
	   finish_item(tr);
	end
   endtask // body
endclass // sha3_sequence

`endif //  `ifndef _SHA3_SEQUENCE_



      
 
