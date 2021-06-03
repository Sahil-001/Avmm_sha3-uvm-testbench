`ifndef _RANDOM_TEST_PARAMETERIZED_REM0_
 `define  _RANDOM_TEST_PARAMETERIZED_REM0_

class random_test_parameterized_rem0 #(int DW,int AW) extends uvm_test;
    `uvm_component_utils(random_test_parameterized_rem0);
   
   function new(string name = "random_test_parameterized_rem0", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new

`include "sha3_env.sv"

   sha3_env #(DW,AW) env;
   virtual function void build_phase(uvm_phase phase);
      begin
	 super.build_phase(phase);
	 env = sha3_env #(DW,AW)::type_id::create("env",this);
      end
   endfunction // build_phase
`include "sha3_sequence"
`include "avl_sequence"
`include "sha3_seq_item_rem0.sv"   
   
   virtual task run_phase(uvm_phase phase);
      begin
	 sha3_sequence #(sha3_seq_item_rem0) sha3_seq;
	 sha3_avl_sequence #(DW,AW) wr_seq;
	 phase.raise_objection(this, "avl_test");
         phase.get_objection.set_drain_time(this, 1.usec);
	 sha3_seq = sha3_sequence #(sha3_seq_item)::type_id::create("sha3_seq");
	 
         for(int i=0; i!=4; i++)
	   begin
	      fork
		 fork
		    begin
		       sha3_seq.sequencer = env.phrase_agent.sequencer;
		       sha3_seq.randomize();
		       sha3_seq.start(env.phrase_agent.sequencer);
		    end
		 join

		 begin
		    wr_seq = sha3_avl_sequence #(DW,AW)::type_id::create("wr_seq");
		    wr_seq.sequencer = env.agent.sequencer;
		    assert(wr_seq.sequencer != null);
		    wr_seq.start(env.agent.sequencer);
		 end
	      join
	   end // for (int i=0; i!=100; i++)
	 

	 phase.drop_objection(this,"avl_test");
      end
   endtask // run_phase
endclass // random_test_parameterized_rem0
`endif //  `ifndef _RANDOM_TEST_PARAMETERIZED_REM0_



  
   
		 
		 
 
	 
