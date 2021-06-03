`ifndef _AVL_MONITOR_
 `define _AVL_MONITOR_
`include "avl_seq_item.sv"
class avl_monitor #(int DW, int AW ) extends uvm_monitor #(avl_seq_item);
    `uvm_component_utils(avl_monitor);
   
   function new(string name = "avl_monitor", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new
endclass // avl_monitor
`endif //  `ifndef _AVL_MONITOR_

