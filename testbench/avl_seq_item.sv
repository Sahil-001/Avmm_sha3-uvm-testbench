`ifndef _AVL_SEQ_ITEM_
 `define _AVL_SEQ_ITEM_

`include "sha3_seq_item.sv"
class avl_seq_item #(int DW = 32 ,int AW = 32) extends uvm_sequence_item;
   int BW ; 
   rand bit [AW-1:0] addr;
   rand bit [DW-1:0] data;
   rand access_enum typ;
   rand bit [(AW/8)-1:0] strb;


      
   `uvm_object_utils_begin(avl_seq_item)
      `uvm_field_sarray_int(addr,UVM_DEFAULT)
      `uvm_field_sarray_int(data,UVM_DEFAULT)
      `uvm_field_enum(access_enum,typ,UVM_DEFAULT)
      `uvm_field_sarray_int(strb,UVM_DEFAULT)
   `uvm_object_utils_end

      
   
   function new(string name = "avl_seq_item");
      super.new(name);
      BW = DW/8;
      
   endfunction // new

   constraint addrCst { 
			(addr >>2) < 4;
			addr % BW == 0;
			}

endclass // avl_seq_item
`endif //  `ifndef _AVL_SEQ_ITEM_

	
