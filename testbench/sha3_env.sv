`ifndef _SHA3_ENV_
 `define  _SHA3_ENV_

`include "sha3_agent.sv"
`include "avl_agent.sv"
`include "sha3_scoreboard.sv"
`include "sha3_monitor2.sv"
class sha3_env #(int DW,int AW) extends uvm_env;
    `uvm_component_utils(sha3_env);
   
   function new(string name = "sha3_env", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new
   
   avl_agent #(DW,AW) agent;
   sha3_agent phrase_agent;
   sha3_scoreboard #(DW,AW) scoreboard;
   sha3_monitor #(DW,AW) monitor;

   virtual function void build_phase(uvm_phase phase);
      begin
         super.build_phase(phase);
         agent = avl_agent #(DW,AW)::type_id::create("agent",this);
	 phrase_agent = sha3_agent::type_id::create("phrase_agent",this);
	 scoreboard = sha3_scoreboard #(DW,AW)::type_id::create("scoreboard",this);
	 monitor = sha3_monitor #(DW,AW)::type_id::create("monitor",this);
      end
   endfunction // build_phase

   virtual function void connect_phase(uvm_phase phase);
      begin
	 super.connect_phase(phase);
	 monitor.sha3_port.connect(scoreboard.sha3_analysis);
	 agent.monitor.rsp_port.connect(monitor.avl_analysis);
	 agent.sequencer.sha3_get_port.connect(phrase_agent.sequencer.seq_item_export);
      end
   endfunction // connect_phase
endclass // sha3_env
`endif //  `ifndef _SHA3_ENV_

      
   
      
