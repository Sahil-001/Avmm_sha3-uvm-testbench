module avmm_sha3;

import esdl;
import uvm;
import std.stdio;
import std.string: format;

import core.sys.posix.sys.mman: mmap, munmap,
  PROT_READ, PROT_WRITE, MAP_SHARED, MAP_FAILED;
import core.sys.posix.fcntl: open, O_SYNC, O_RDWR;
import core.sys.posix.unistd: close;
import core.volatile: volatileLoad, volatileStore;
import std.conv;

extern(C) void* sha3(const void* str, size_t strlen, void* md, int mdlen);

enum output_size_enum {SHA3_224=224, SHA3_256=256,
		       SHA3_384=384, SHA3_512=512}

enum access_enum: bool {READ, WRITE}

class sha3_seq_item_empty: sha3_seq_item
{
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }

  Constraint! q{
    phrase.length == 0;
  } empty;
}

class sha3_seq_item_rem1: sha3_seq_item
{
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }

  @UVM_DEFAULT @UVM_DEC @rand uint rate;
  
  Constraint!q{
    rate == 200 - 2*out_size/8;
    phrase.length % rate ==  rate - 1;
  } rem0;
}

class sha3_seq_item_rem0: sha3_seq_item
{
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }

  @UVM_DEFAULT @UVM_DEC @rand uint rate;
  
  Constraint!q{
    rate == 200 - 2*out_size/8;
    phrase.length % rate ==  0;
  } rem0;
}


class sha3_seq_item: uvm_sequence_item
{
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }

  @UVM_DEFAULT {
    access_enum type;
    @rand ubyte[] phrase;
    @rand output_size_enum out_size;
    // @rand uint rate;
  }
  
  Constraint! q{
    phrase.length <= 1024;
    // rate == 200 - 2*out_size/8;
    // phrase.length % rate ==  rate - 1;
    foreach (c; phrase) {
      c < 80;
      c > 10;
    }
  } phrase_length;
}

class sha3_sequence(T): uvm_sequence!T if ( is(T: sha3_seq_item))

{
  mixin uvm_object_utils;
  sha3_sequencer sequencer;
  output_size_enum out_size;
  string phrase;

  void set_phrase(string ph) {
    phrase = ph;
  }

  void set_outputsize(output_size_enum os) {
    out_size = os;
  }
  
  this(string name = "sha3_sequence") {
    super(name);
    req = REQ.type_id.create("req");
  }

  override void body() {
    for (size_t i=0; i!=1; ++i) {
      // req.phrase = cast(ubyte[]) phrase;
      // req.out_size = cast(output_size_enum) out_size;
      req.randomize();
      // writeln("Seed was: ", req._esdl__getRandomSeed());
      // writeln("Proc Seed was: ", Process.self.getRandSeed());
      // writeln("Proc Name was: ", Process.self.getFullName());
      uvm_info("PRINTREQUEST", ":\n" ~ req.sprint(), UVM_DEBUG);
      req.type = access_enum.WRITE;
      REQ tr = cast(REQ) req.clone;
      start_item(tr);
      finish_item(tr);
    }
  }
}

class sha3_sequencer:  uvm_sequencer!sha3_seq_item
{
  mixin uvm_component_utils;

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }
}

class sha3_agent: uvm_agent
{
  mixin uvm_component_utils;

  @UVM_BUILD {
    sha3_sequencer  sequencer;
    sha3_driver     driver;
  }

  this(string name, uvm_component parent) {
    super(name, parent);
  }

  override void connect_phase(uvm_phase phase) {
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) {
      driver.seq_item_port.connect(sequencer.seq_item_export);
    }
  }
}

class sha3_driver: uvm_driver!sha3_seq_item
{
  mixin uvm_component_utils;
  this(string name, uvm_component parent) {
    super(name, parent);
  }

  @UVM_BUILD {
    uvm_analysis_port!sha3_seq_item sha3_req_port;
    uvm_analysis_port!sha3_seq_item sha3_rsp_port;
  }
  
  version(CYCLONE_V) {
    // axi registers specific

    // The start address and length of the Lightweight bridge
    enum uint HPS_TO_FPGA_LW_BASE = 0xFF200000;
    enum uint HPS_TO_FPGA_LW_SPAN = 0x0020000;
    
    @rand(false) uint* regs;
    int   fd;
    @rand(false) void* mem;
  }

  void map_registers() {
    version(CYCLONE_V) {
      // access AXI registers
      fd = open("/dev/mem", O_RDWR | O_SYNC);
      if (fd < 0) {
	assert(false, "Failed to open /dev/mem\n  Does it exists?\n" ~
	       "  Check permissions\n  Check devicetree\n");
      }

      mem = mmap(null, HPS_TO_FPGA_LW_SPAN, PROT_READ | PROT_WRITE,
		 MAP_SHARED, fd, HPS_TO_FPGA_LW_BASE);

      if (mem == MAP_FAILED) {
	close(fd);
	assert(false, "Can't map memory");
      }

      regs = cast(uint*) mem;
    }
  }

  version(CYCLONE_V) {
    override void final_phase(uvm_phase phase) {
      super.final_phase(phase);
      munmap(mem, HPS_TO_FPGA_LW_SPAN);
      close(fd);
    }
  }
  
  override void run_phase(uvm_phase phase) {
    uvm_info ("INFO" , "Called my_driver::run_phase", UVM_DEBUG);
    super.run_phase(phase);
    map_registers();
    get_and_drive(phase);
  }

  void get_and_drive(uvm_phase phase) {
    while(true) {
      seq_item_port.get_next_item(req);
      execReq(req);
      sha3_seq_item rsp = new sha3_seq_item("SHA3 RESPONSE");
      collateRsp(rsp, req.out_size);
      seq_item_port.item_done();
    }
  }

  void execReq(sha3_seq_item req) {
    sha3_req_port.write(req);
    version(CYCLONE_V) {
      auto data = req.phrase;
      auto size = req.out_size;
      
      bool last_block = false;
      uint rate = (1600-2*size)/8; // 144, 136, 104, 72
      uint data_length = cast(uint) (((data.length + rate))/(rate));
      for (size_t k=0; k!=data_length; ++k) {
	ubyte [200] arr_block;
	for (size_t i=0; i!=rate; ++i) {
	  if (k*rate + i < data.length) {
	    arr_block[i] = data[rate*k+i];
	  }
	  else if (k*rate + i == data.length) {
	    arr_block[i] = 0x06;
	    last_block = true;
	  }
	  else {
	    arr_block[i] = 0x00;
	  }
	  if ( i==(rate-1) && last_block == true) {
	    arr_block[i] |= 0x80;
	  }
	}

	for (size_t i=0; i != (k==0 ? 50 : rate/4); ++i) {
	  uint word = 0;
	  for (size_t j=0; j!=4; ++j) {
	    word += (cast(uint) arr_block[i*4+j]) << ((j) * 8);
	  }
	  volatileStore(regs + 0x200/4 + i, word);
	}
	if (k == 0) {
	  volatileStore(regs + 0x20/4, 1);
	  volatileStore(regs + 0x20/4, 0);
	}
	else {
	  volatileStore(regs + 0x20/4, 2);
	  volatileStore(regs + 0x20/4, 0);
	}
      }
    }
  }

  void collateRsp(sha3_seq_item rsp, output_size_enum out_size) {
    version(CYCLONE_V) {
      uint  num_reads = out_size/32;
      rsp.out_size = out_size;
      for (size_t j=0; j!=num_reads; ++j) {
	uint data;
	ubyte* data_bytes;
	data = volatileLoad(regs + 0x300/4 + j);
	data_bytes = cast(ubyte*) &data;
	for (size_t i=0; i!=4; ++i) {
	  rsp.phrase ~= data_bytes[i];
	}
      }
      sha3_rsp_port.write(rsp);
    }
  }
}

class avl_seq_item(int DW, int AW): uvm_sequence_item
{
  mixin uvm_object_utils;
  
  this(string name="") {
    super(name);
  }
  
  enum BW = DW/8;

  @UVM_DEFAULT {
    @rand UBit!AW addr;
    @rand Bit!DW  data;
    @rand access_enum type;
    @UVM_BIN			// print in binary format
      @rand UBit!BW strb;
  }

  Constraint! q{
    (addr >> 2) < 4;
    addr % BW == 0;
  } addrCst;

  override void do_vpi_put(uvm_vpi_iter iter) {
    iter.put_values(addr, strb, data, type);
  }

  override void do_vpi_get(uvm_vpi_iter iter) {
    iter.get_values(addr, strb, data, type);
  }
};

class sha3_avl_sequence(int DW, int AW): uvm_sequence!(avl_seq_item!(DW, AW))
{
  mixin uvm_object_utils;
  avl_sequencer!(DW,AW) sequencer;
  sha3_seq_item sha3_item;

  this(string name = "sha3_avl_sequence") {
    super(name);
  }

  override void body() {
    sequencer.sha3_get_port.get(sha3_item);
    auto data = sha3_item.phrase;
    auto size = sha3_item.out_size;
    bool last_block = false;
    uint rate = (1600-2*size)/8; // 144, 136, 104, 72
    uint num_frames = cast(uint) (((data.length + rate))/(rate));
    for (size_t k=0; k!=num_frames; ++k) {
      ubyte [200] arr_block;
      for (size_t i=0; i!=rate; ++i) {
	if (k*rate + i < data.length) {
	  arr_block[i] = data[rate*k+i];
	}
	else if (k*rate + i == data.length) {
	  arr_block[i] = 0x06;
	  last_block = true;
	}
	else {
	  arr_block[i] = 0x00;
	}
	if (i==(rate-1) && last_block == true) {
	  arr_block[i] |= 0x80;
	}
      }

      for (size_t i=0; i != (k==0 ? 50 : rate/4); ++i) {
	uint word = 0;
	for (size_t j=0; j!=4; ++j) {
	  word += (cast(uint) arr_block[i*4+j]) << ((j) * 8);
	}
	auto data_req = REQ.type_id.create("req");
	data_req.data = word;
	data_req.addr = cast(int) (0x200+4*i);
	data_req.strb = toBit!0xF;
	data_req.type = access_enum.WRITE;
      
	start_item(data_req);
	finish_item(data_req);
      }
      if (k == 0) {
	init_pulse();//data_req.data = 0x00000001;
      }
      else {
	next_pulse();//data_req.data = 0x00000002;
      }
    }
    read_hash(rate);
  }

  void init_pulse() {
    uvm_info("DEBUGSHA3", "At the start of init_pulse", UVM_DEBUG);
    auto data_req = REQ.type_id.create("init_pulse_start");
    data_req.data = 0x00000001;
    data_req.addr = 0x20;
    data_req.strb = toBit!0xF;
    data_req.type = access_enum.WRITE;

    start_item(data_req);
    finish_item(data_req);

    data_req = REQ.type_id.create("init_pulse_end");
    data_req.data = 0x00000000;
    data_req.addr = 0x20;
    data_req.strb = toBit!0xF;
    data_req.type = access_enum.WRITE;

    start_item(data_req);
    finish_item(data_req);
  }

  void  next_pulse() {
    auto data_req = REQ.type_id.create("next_pulse_start");
    data_req.data = 0x00000002;
    data_req.addr = 0x20;
    data_req.strb = toBit!0xF;
    data_req.type = access_enum.WRITE;

    start_item(data_req);
    finish_item(data_req);

    data_req = REQ.type_id.create("next_pulse_end");
    data_req.data = 0x00000000;
    data_req.addr = 0x20;
    data_req.strb = toBit!0xF;
    data_req.type = access_enum.WRITE;

    start_item(data_req);
    finish_item(data_req);
  }

  void read_hash(int rate) {
    auto out_size = (1600 - rate*8)/2;
    int  num_reads = out_size/32;
    for (uint i=0; i!= num_reads; i++) {
      auto data_req = REQ.type_id.create("read_hash");
      data_req.addr = 0x300+4*i;
      data_req.strb = toBit!0xF;
      data_req.type = access_enum.READ;
    
      start_item(data_req);
      finish_item(data_req);
    }
  }
}

class avl_sequencer(int DW, int AW):
  uvm_sequencer!(avl_seq_item!(DW, AW))
{
  mixin uvm_component_utils;
  @UVM_BUILD {
    uvm_seq_item_pull_port!sha3_seq_item sha3_get_port;
  }

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }
}

class avl_driver(int DW, int AW, string vpi_func):
  uvm_vpi_driver!(avl_seq_item!(DW, AW), vpi_func)
{
  enum BW = DW/8;
    
  alias REQ=avl_seq_item!(DW, AW);
  
  mixin uvm_component_utils;
  
  REQ tr;

  this(string name, uvm_component parent) {
    super(name,parent);
  }
  
  override void run_phase(uvm_phase phase) {
    super.run_phase(phase);
    get_and_drive(phase);
  }
	    
  void get_and_drive(uvm_phase phase) {
    while(true) {
      seq_item_port.get_next_item(req);
      uvm_info("AVL TRANSACTION", req.sprint(), UVM_DEBUG);
      drive_vpi_port.put(req);
      item_done_event.wait();
      seq_item_port.item_done();
    }
  }
}

class sha3_monitor(int DW, int AW): uvm_monitor
{
  sha3_seq_item sha3_item;
  
  @UVM_BUILD {
    uvm_analysis_imp!(write) avl_analysis;
    uvm_analysis_port!sha3_seq_item sha3_port;
  }

  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name,parent);
  }

  union {
    uint[50] word_block;
    ubyte[200] byte_block;
  }

  ubyte[] out_buffer;

  ubyte[] sha3_buffer;

  ubyte[] sha3_str;
  
  enum sha3_state: byte {INIT_BLOCK, NEXT_BLOCK, OUT_BLOCK}

  sha3_state state;
  
  void process_transactions() {
    import std.stdio;
    uint out_size = cast(uint) (out_buffer.length * 8);
    uint blk_size = (1600 - 2*out_size)/8;
    if (out_size != output_size_enum.SHA3_224 &&
	out_size != output_size_enum.SHA3_256 &&
	out_size != output_size_enum.SHA3_384 &&
	out_size != output_size_enum.SHA3_512) {
      uvm_error("SHA3_ILLEGAL_SIZE",
		format("ILLEGAL output size %x",
		       out_size));
    }
    output_size_enum sha3_size = cast(output_size_enum) (out_size);

    for (size_t i=0; i != sha3_buffer.length/200; ++i) {
      sha3_str ~= sha3_buffer[i*200..i*200+blk_size];
      for (size_t j=i*200+blk_size; j!=(i+1)*200; ++j) {
	if (sha3_buffer[j] != 0) {
	  uvm_error("SHA3_ILLEGAL_CAPACITY_BYTE",
		    format("ILLEGAL non-zero byte in capacity region %x at position %d",
			   sha3_buffer[j], j));
	}
      }
    }

    if (sha3_str[$-1] == 0x86) {
      sha3_str.length -= 1;
    }
    else if (sha3_str[$-1] == 0x80) {
      uint i = 2;
      while (sha3_str[$-i] == 0x00) i += 1;
      if (sha3_str[$-i] != 0x06) {
	uvm_error("SHA3_ILLEGAL_PAD_START",
		  format("ILLEGAL Pas Start %x",
			 sha3_str[$-i]));
      }
      sha3_str.length -= i;
    }
    else {
      uvm_error("SHA3_ILLEGAL_LAST_BYTE",
		format("ILLEGAL Last Byte in Input %x",
		       sha3_str[$-1]));
    }
    // send transactions to scoreboard
    sha3_seq_item sha3_in_trans =
      sha3_seq_item.type_id.create("SHA3 MONITORED INPUT");
    sha3_in_trans.phrase = sha3_str;
    sha3_in_trans.out_size = sha3_size;
    sha3_in_trans.type = access_enum.WRITE;
    sha3_port.write(sha3_in_trans);
    
    sha3_seq_item sha3_out_trans =
      sha3_seq_item.type_id.create("SHA3 MONITORED OUTPUT");
    sha3_out_trans.phrase = out_buffer;
    sha3_out_trans.out_size = sha3_size;
    sha3_out_trans.type = access_enum.READ;
    sha3_port.write(sha3_out_trans);
    
    sha3_str.length = 0;
    out_buffer.length = 0;
    sha3_buffer.length = 0;
  }

  void write(avl_seq_item!(DW, AW) item) {
    if (item.type is access_enum.WRITE) { // writes on registers
      if (state is sha3_state.OUT_BLOCK) { // we have just started writing next transaction
	state = sha3_state.INIT_BLOCK;
	// process sha3_buffer and out_buffer and create input and output transactions
	this.process_transactions();
      }
      if (! (item.addr == 0x20 || (item.addr >= 0x200 && item.addr < 0x200 + 200))) {
	uvm_error("AVL_ILLEGAL_ADDR",
		  format("ILLEGAL address (%x) for AVL WRITE transaction",
			 item.addr));
      }

      if (item.addr >= 0x200) {	// register data writes
	word_block[(item.addr - 0x200)/4] = item.data;
      }

      if (item.addr == 0x20) {	// for detecting init and next
	switch (item.data) {
	case 0x00000001:
	  assert (state is sha3_state.INIT_BLOCK);
	  state = sha3_state.NEXT_BLOCK;
	  sha3_buffer ~= byte_block;
	  break;
	case 0x00000002:
	  sha3_buffer ~= byte_block;
	  break;
	case 0x00000000:
	  break;
	default:
	  uvm_error("AVL_ILLEGAL_DATA",
		    format("ILLEGAL data value (%x) observed on addr (%x)",
			   item.data, item.addr));
	  break;
	}
      }
    }
    else {			// READ in register
      state = sha3_state.OUT_BLOCK;
      if (! (item.addr >= 0x300 && item.addr < 0x300 + 16*4)) {
	uvm_error("AVL_ILLEGAL_ADDR",
		  format("ILLEGAL address (%x) for AVL READ transaction",
			 item.addr));
      }
      auto addr_offset = item.addr - 0x300;

      if (addr_offset != out_buffer.length) {
	uvm_error("AVL_ILLEGAL_ADDR",
		  format("Not in sequence address (%x) for AVL READ transaction",
			 item.addr));
      }

      uint read_data = item.data;
      ubyte* read_ptr = cast (ubyte*) &read_data;
      for (size_t i=0; i!=4; ++i) {
	out_buffer ~= read_ptr[i];
      }
    }
  }
}


class sha3_scoreboard(int DW, int AW): uvm_scoreboard
{
  mixin uvm_component_utils;

  sha3_seq_item write_seq;

  this(string name, uvm_component parent = null) {
    synchronized(this) {
      super(name, parent);
    }
  }

  uvm_phase run_ph;
  override void run_phase(uvm_phase phase) {
    run_ph = phase;
  }
  
  @UVM_BUILD {
    uvm_analysis_imp!(write_req) sha3_req_analysis;
    uvm_analysis_imp!(write_rsp) sha3_rsp_analysis;
  }

  sha3_seq_item sha3_req;
  void write_req(sha3_seq_item item) {
    // item.print();
    sha3_req = item;
  }

  void write_rsp(sha3_seq_item item) {
    ubyte[] expected;
    expected.length = item.out_size/8;
    sha3(sha3_req.phrase.ptr,
	 cast(uint) sha3_req.phrase.length, expected.ptr, cast(uint) expected.length);
    if (expected == item.phrase) {
      uvm_info("MATCHED", format("%s: expected \n %s: actual",
				 expected, item.phrase), UVM_MEDIUM);
    }
    else {
      uvm_error("MISMATCHED", format("%s: expected \n %s: actual",
				     expected, item.phrase));
    }
    
  }
}

class sha3_env(int DW, int AW): uvm_env
{
  mixin uvm_component_utils;
  @UVM_BUILD {
    sha3_agent phrase_agent;
    sha3_scoreboard!(DW, AW) scoreboard;
  }

  this(string name , uvm_component parent) {
    super(name, parent);
  }

  override void connect_phase(uvm_phase phase) {
    super.connect_phase(phase);
    phrase_agent.driver.sha3_req_port.connect(scoreboard.sha3_req_analysis);
    phrase_agent.driver.sha3_rsp_port.connect(scoreboard.sha3_rsp_analysis);
  }
}
      

class random_test_parameterized(int DW, int AW): uvm_test
{
  mixin uvm_component_utils;

  this(string name, uvm_component parent) {
    super(name, parent);
  }

  @UVM_BUILD {
    sha3_env!(DW, AW) env;
  }

  override void run_phase(uvm_phase  phase) {
    sha3_sequence!sha3_seq_item sha3_seq;
    phase.raise_objection(this, "avl_test");
    uvm_factory.get().print();
    sha3_seq = sha3_sequence!(sha3_seq_item).type_id.create("sha3_seq");
    for (size_t i=0; i != 1000; ++i) {
      sha3_seq.sequencer = env.phrase_agent.sequencer;
      sha3_seq.randomize();
      //sha3_seq.print();
      sha3_seq.start(env.phrase_agent.sequencer);
    }
    phase.drop_objection(this, "avl_test");
  }
}

class random_test: random_test_parameterized!(32, 32)
{
  mixin uvm_component_utils;
  this(string name, uvm_component parent) {
    super(name, parent);
  }
}

int main(string[] args) {
  auto tb = new uvm_tb;
  tb.multicore(0, 1);
  tb.elaborate("test", args);
  tb.set_seed(1);
  tb.setAsyncMode();

  return tb.start();
}

