`ifndef _RANDOM_TEST_
 `define  _RANDOM_TEST_

class random_test extends random_test_parameterized #(32,32);
   `uvm_component_utils(random_test);
   
   function new(string name = "random_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction // new
endclass // random_test
`endif //  `ifndef _RANDOM_TEST_


