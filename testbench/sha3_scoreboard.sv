`ifndef _SHA3_SCOREBOARD_
 `define  _SHA3_SCOREBOARD_

`include "sha3_seq_item.sv"
 class sha3_scoreboard #(int DW, int AW) extends uvm_scoreboard;
    `uvm_component_utils(sha3_scoreboard);

    sha3_seq_item write_seq;
    function new(string name = "sha3_scoreboard", uvm_component parent = null);
       super.new(name,parent);
    endfunction // new

    uvm_phase run_ph;
    virtual task run_phase(uvm_phase phase);
       begin
	  super.run_phase(phase);
	  run_ph = phase;
       end
    endtask // run_phase
    
     uvm_analysis_imp  sha3_analysis;

   virtual function void build_phase(uvm_phase phase);
     begin
      super.build_phase(phase);
      sha3_analysis = new("sha3_analysis",this);
     end
   endfunction // build_phase

     byte expected[];

    function void write(sha3_seq_item item);
	  if (item.typ ==  WRITE)
            begin
               `uvm_info("WRITE", item.sprint(), UVM_DEBUG);
	       write_seq = item;
	       run_ph.raise_objection(this);
	    end
	  else
	    begin
	       int unsigned  write_seq_length, expected_length;
	       `uvm_info("READ", item.sprint(), UVM_DEBUG);
	       expected_length = item.out_size/8;
	      
	       $cast(write_seq_length, write_seq.phrase.size());
	      
	       
	      // sha3(write_seq.phrase.ptr, write_seq_length, expected.ptr, expected_length);

	       if(expected == item.phrase)
		 `uvm_info("MATCHED", format("%s: expected \n %s: actual",
					     expected, item.phrase), UVM_MEDIUM);
	/*       else
		 `uvm_error("MISMATCHED", format("%s: expected \n %s: actual",
						 expected, item.phrase));
	  */     
	       run_ph.drop_objection(this);
	       
	    end // else: !if(item.type ==  access_enum.WRITE)
    endfunction // write
 endclass // sha3_scoreboard
`endif //  `ifndef _SHA3_SCOREBOARD_


       
	 
	 
