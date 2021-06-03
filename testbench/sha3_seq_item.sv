`ifndef _SHA3_SEQ_ITEM_
 `define  _SHA3_SEQ_ITEM_

import uvm_pkg::*;
   
`include "uvm_macros.svh"
   

 typedef enum {SHA3_224 = 224, SHA_256 = 256, SHA_384 = 384, SHA_512 = 512}output_size_enum;

 typedef enum {READ , WRITE} access_enum;
 
class sha3_seq_item extends uvm_sequence_item;
   access_enum typ;
   rand byte phrase[];
   rand output_size_enum out_size;

  `uvm_object_utils_begin(sha3_seq_item)
     `uvm_field_enum (access_enum,typ, UVM_DEFAULT)
     `uvm_field_array_int (phrase, UVM_DEFAULT)
     `uvm_field_enum (output_size_enum, out_size, UVM_DEFAULT)
  `uvm_object_utils_end
   function new(string name = "sha3_seq_item");
      super.new(name);
   endfunction // new
  
   constraint phase_length{phrase.size() <= 1024;
			   foreach (phrase[i])
			   {
			    phrase[i]<80;
			    phrase[i]>10;
			    }
			   }
   
endclass // sha3_seq_item
`endif //  `ifndef _SHA3_SEQ_ITEM_

   

 

  


			   
     

  
     
     
