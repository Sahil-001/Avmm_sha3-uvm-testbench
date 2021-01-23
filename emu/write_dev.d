import core.sys.posix.sys.mman: mmap, munmap,
  PROT_READ, PROT_WRITE, MAP_SHARED, MAP_FAILED;
import core.sys.posix.fcntl: open, O_SYNC, O_RDWR;
import core.sys.posix.unistd: close;
import core.volatile: volatileLoad, volatileStore;
import std.conv;

class Device
{
  uint* regs;
  int fd;
  void* mem;

  uint span;

  this(uint BASE, uint SPAN) {
    span = SPAN;
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
      assert(false, "Failed to open /dev/mem\n  Does it exists?\n" ~
	     "  Check permissions\n  Check devicetree\n");
    }

    mem = mmap(null, SPAN, PROT_READ | PROT_WRITE,
	       MAP_SHARED, fd, BASE);

    if (mem == MAP_FAILED) {
      close(fd);
      assert(false, "Can't map memory");
    }

    regs = cast(uint*) mem;
  }

  ~this() {
    munmap(mem, span);
    close(fd);
  }

  uint read(uint addr) {
    return volatileLoad(regs + addr/4);
  }

  void write(uint addr, uint data) {
    volatileStore(regs + addr/4, data);
  }
}


void main(string[] args)
{
  import std.stdio;
  if (args.length != 3) {
    import std.string;
    assert(false, format("Usage: %s addr data", args[0]));
  }
  
  uint addr = args[1].to!uint;
  uint data = args[2].to!uint;

  Device dev = new Device(0xFF200000, 0x0020000);

  dev.write(addr, data);
  writefln("address: %s, value: %x", addr, data);
  
}


