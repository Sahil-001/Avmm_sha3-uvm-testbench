`ifndef _SHA3_SEQ_ITEM_EMPTY_
 `define  _SHA3_SEQ_ITEM_EMPTY_

`include "sha3_seq_item.sv"
module top;
   
class sha3_seq_item_empty extends sha3_seq_item;
   `uvm_object_utils(sha3_seq_item_empty);
   function new (string name = "sha3_seq_item_empty");
      super.new(name);
   endfunction // new
   
   constraint empty {
      phrase.size() == 0;
   }
endclass // sha3_seq_item_empty

class sha3_seq_item_rem1 extends sha3_seq_item;
   rand int rate;
   `uvm_object_utils_begin(sha3_seq_item_rem1)
      `uvm_field_int(rate, UVM_DEFAULT | UVM_DEC)
   `uvm_object_utils_end
   function new(string name = "sha3_seq_item_rem1");
      super.new(name);
   endfunction // new
   
   constraint rem1 {
      rate == 200 - 2*out_size/8;
      phrase.size() % rate == rate - 1;
   }
endclass // sha3_seq_item_rem1

class sha3_seq_item_rem0 extends sha3_seq_item;
   rand int rate;
   `uvm_object_utils_begin(sha3_seq_item_rem1)
      `uvm_field_int(rate, UVM_DEFAULT | UVM_DEC)
   `uvm_object_utils_end
   function new(string name = "sha3_seq_item_rem1");
      super.new(name);
   endfunction // new
   
   constraint rem0 {
      rate == 200 - 2*out_size/8;
      phrase.size() % rate == 0;
   }
endclass // sha3_seq_item_rem0

   program test;
   sha3_seq_item_rem1 seq_item;
  initial  begin
      seq_item = sha3_seq_item_rem1::type_id::create("seq_item");
      seq_item.randomize();
      seq_item.print();
   end
endprogram // test

endmodule // top
`endif //  `ifndef _SHA3_SEQ_ITEM_EMPTY_
