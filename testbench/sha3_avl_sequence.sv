`include "avl_sequencer.sv"
class sha3_avl_sequence #(int DW , int AW) extends uvm_sequence #(avl_seq_item #(DW,AW));
   `uvm_component_utils(sha3_avl_sequence)
   avl_sequencer #(DW,AW) sequencer;
   sha3_seq_item sha3_item;

   function new(string name = "sha3_avl_sequence");
      super.new(name);
   endfunction // new
   
   virtual task body();
     
      begin
	 sequencer.sha3_get_port.get(sha3_item);
	 byte data[] = sha3_item.phrase;
	 output_size_enum size = sha3_item.out_size;
	 bit  last_block = 0;
	 int  rate = (1600-2*size)/8;
	 int  num_frames = (data.size() + rate)/rate;	
	 
	 for(int k=0; k!=num_frames; k++)
	   begin
              byte  arr_block [200];
	      for(int i=0; i!=rate ;i++)
		begin
		   if(k*rate + i < data.size())
		     arr_block[i] = data[rate * k+1];
		   else if (k*rate + i == data.size())
		     begin
			arr_block[i] = 16'h6;
			last_block = 1;
		     end
		   else
		     arr_block[i] = 16'h0;
		   
		   if(i==(rate-1) && last_block == 1)
		     arr_block[i] |= 16'h80;
		end  // for (int i=0; i!=rate ;i++)
	      
	      for(int i = 0 ; i!= (k==0 ? 50 : rate/4); i++)
		begin
		   int word = 0;
		   int word_helper;
		   for(int j=0;j!=4;j++)
		     begin
			$cast(word_helper , arr_block[i*4 + j] << (j*8));
			word = word + word_helper;
		     end
		   REQ data_req = REQ::type_id::create("req");
		   data_req.data = word;
		   data_req.addr = 512 + 4*i;
		   data_req.strb = 4'b1111;
		   data_req.typ = access_enum.WRITE;
		   start_item(data_req);
		   finish_item(data_req);
		end // for (int i = 0 ; i!= (k==0 ? 50 : rate/4); i++)
	      if(k==0)
		init_pulse();
	      else
		next_pulse();
	      
	      read_hash(rate);
	   end // for (int k=0; k!=num_frames; k++ )
      end
   endtask // body
   
   function void init_pulse();
      begin
         uvm_info("DEBUGSHA3", "At the start of init_pulse", UVM_DEBUG);
         REQ data_req = REQ::type_id::create("init_pulse_start");
         data_req.data = 1;
         data_req.addr = 8'h20;
         data_req.strb = 4'b1111;
         data_req.typ = access_enum.WRITE;

         start_item(data_req);
         finish_item(data_req);
	 
         data_req = REQ::type_id::create("init_pulse_end");
         data_req.data = 0;
         data_req.addr = 8'h20;
         data_req.strb = 1111;
         data_req.typ = access_enum.WRITE;

         start_item(data_req);
         finish_item(data_req);
      end
   endfunction // init_pulse
   
   function void next_pulse();
      begin
         REQ data_req = REQ::type_id::create("next_pulse_start");
         data_req.data = 2;
         data_req.addr = 8'h20;
         data_req.strb = 4'b1111;
         data_req.typ = access_enum.WRITE;

         start_item(data_req);
         finish_item(data_req);
	 
         data_req = REQ::type_id::create("next_pulse_end");
         data_req.data = 0;
         data_req.addr = 8'h20;
         data_req.strb = 1111;
         data_req.typ = access_enum.WRITE;

         start_item(data_req);
         finish_item(data_req);
      end
   endfunction // next_pulse

   function void read_hash(int rate);
      begin
	 output_size_enum out_size = (1600 - rate*8)/2;
	 int num_reads = out_size/32;
	 for(int i=0; i!=num_reads ; i++)
	   begin
	      REQ data_req = REQ.type_id.create("read_hash");
              data_req.addr = (256*3)+4*i;
              data_req.strb = 1111;
              data_req.typ = access_enum.READ;
	      
	      start_item(data_req);
	      finish_item(data_req);
	   end
      end
   endfunction // read_hash
endclass // sha3_avl_sequence


  
      
      
