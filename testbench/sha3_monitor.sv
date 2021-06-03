`include "sha3_seq_item.sv"
class sha3_monitor #(int DW , int AW) extends uvm_monitor;
   `uvm_component_utils(sha3_monitor);
    sha3_seq_item sha3_item;
   function new(string name = "sha3_monitor", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new

   uvm_analysis_port #(sha3_seq_item) sha3_port;
   uvm_analysis_imp  avl_analysis;

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sha3_port = new("sha3_port",this);
      avl_analysis = new("avl_analysis",this);
   endfunction // build_phase

   typedef union {
      int word_block[50];
      byte byte_block[200];
   } block_union;

   byte out_buffer[];
   byte sha3_buffer[];
   byte sha3_str[];

   typedef enum  byte {INIT_BLOCK, NEXT_BLOCK, OUT_BLOCK} sha3_state;

   sha3_state state;

   function void process_transaction();
      begin
	 int out_size;
	 int blk_size = (1600 - 2*out_size)/8;
	 out_size =  out_buffer.size()*8;
	
	 if (out_size != output_size_enum.SHA3_224 &&out_size != output_size_enum.SHA3_256 && out_size != output_size_enum.SHA3_384 && out_size != output_size_enum.SHA3_512)
	   `uvm_error("SHA3_ILLEGAL_SIZE",format("ILLEGAL output size %x",out_size));
	 output_size_enum sha3_size;
	 
	 
	 $cast(sha3_size, out_size);
	 for(int i=0; i!=sha3_buffer.length/200;i++)
	   begin
	      sha3_str ~= sha3_buffer[i*200+blk_size:i*200];
	      for(int j=i*200+blk_size; j!=(i+1)*200;j++)
		begin
		   if(sha3_buffer[j]!=0)
		      `uvm_error("SHA3_ILLEGAL_CAPACITY_BYTE", format("ILLEGAL non-zero byte in capacity region %x at position %d", sha3_buffer[j], j));
		end
	   end
	 if(sha3_str[sha3_str.size()-1]==8'h86)
	   sha3_str = sha3_str[sh3_str.size()-2:0];
	 else if(sha3_str[sha3_str.size()-1]==8'h80)
	   begin
	      unsigned int i=2;
	      while (sha3_str[sha3_str.size()-1]==8'h00)
		i+=1;
	      if(sha3_str[sha3_str.size()-1]!=8'h06)
		`uvm_error("SHA3_ILLEGAL_PAD_START",
		  format("ILLEGAL Pas Start %x",
			 sha3_str[$-i]));
	       sha3_str = sha3_str[sh3_str.size()-i:0];
	   end // if (sha3_str[sha3_str.size()-1]==8'h80)
	 else
	     `uvm_error("SHA3_ILLEGAL_LAST_BYTE",
		format("ILLEGAL Last Byte in Input %x",
		       sha3_str[$-1]));

	 sha3_seq_item sha3_in_trans = sha3_seq_item::type_id::create("SHA3 MONITORED INPUT");
	  sha3_in_trans.phrase = sha3_str;
          sha3_in_trans.out_size = sha3_size;
          sha3_in_trans.typ = access_enum.WRITE;
          sha3_port.write(sha3_in_trans);

	  sha3_seq_item sha3_out_trans = sha3_seq_item::type_id::create("SHA3 MONITORED OUTPUT");
	  sha3_out_trans.phrase = out_buffer;
          sha3_out_trans.out_size = sha3_size;
          sha3_out_trans.typ = access_enum.READ;
          sha3_port.write(sha3_out_trans);

	 sha3_str.size() = 0;
	 out_buffer.size() = 0;
	 sha3_buffer.size() = 0;
      end
   endfunction // process_transaction

   function void write(avl_seq_item #(DW,AW) item);
      begin
	 if(item.typ == access_enum.write)
	   begin
	      if(state == sha3_state.OUT_BLOCK)
		begin
		   state = sha3_state.INIT_BLOCK;
		   this.process_transactions();
		end
	      if(!(item.addr == 8'h20 || (item.addr >= 12'h200 && item.addr < 12'h200 + 200)))
		`uvm_error("AVL_ILLEGAL_ADDR",
		  format("ILLEGAL address (%x) for AVL WRITE transaction",
			 item.addr));
	      if(item.addr == 12'h200)
		word_block[(item.addr - 12'h200)/4] = item.data;
	      if(item.addr == 12'h20)
		begin
		   case(item.data)
		     'h1:
		       begin
		        assert (state is sha3_state.INIT_BLOCK);
	                state = sha3_state.NEXT_BLOCK;
	                sha3_buffer ~= byte_block;
	                break;
		       end
		     'h2:
		       begin
			  sha3_buffer ~= byte_block;
			  break;
		       end
		     'h0:
		       break;
		     default:
		       begin
			   `uvm_error("AVL_ILLEGAL_DATA",
		           format("ILLEGAL data value (%x) observed on addr (%x)",
			   item.data, item.addr));
	                   break;
		       end
		   endcase // case (item.data)
		end // if (item.addr == 12'h20)
	   end // if (item.typ == access_enum.write)
	 else
	   begin
	      state = sha3_state.OUT_BLOCK;
	      if(!(item.addr >= 'h300 && item.addr < 'h300 + 16*4))
		`uvm_error("AVL_ILLEGAL_ADDR",
		  format("ILLEGAL address (%x) for AVL READ transaction",
			 item.addr));
	      unsigned bit  addr_offset = item.addr - 'h300;
	      
	      if(addr_offset != outbuffer.size())
		`uvm_error("AVL_ILLEGAL_ADDR",
		  format("Not in sequence address (%x) for AVL READ transaction",
			 item.addr));
	      unsigned int read_data = item.data;
	      for()
		end // else: !if(item.typ == access_enum.write)
      endfunction // write
   endclass // sha3_monitor

     
              
   
   
   
	   
	      

	 
     
      

	 
      	 
    
   
   
   