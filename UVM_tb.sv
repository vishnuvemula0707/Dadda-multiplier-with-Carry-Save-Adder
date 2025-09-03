

`include "uvm_macros.svh"
 import uvm_pkg::*;


class transaction extends uvm_sequence_item;
  rand bit [3:0] A_in;
  rand bit [3:0] B_in;
  bit [7:0] p_reg_out;
  
  function new(input string path="transaction");
    super.new(path);
  endfunction
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(A_in,UVM_DEFAULT)
  `uvm_field_int(B_in,UVM_DEFAULT)
  `uvm_field_int(p_reg_out,UVM_DEFAULT)
  `uvm_object_utils_end
  
endclass


/////////////////////////////////////////////


class generator extends uvm_sequence #(transaction);
`uvm_object_utils(generator)
 
transaction t;
 
 
function new(input string inst = "GEN");
super.new(inst);
endfunction
 
 
virtual task body();
  t = transaction::type_id::create("t");
    
  repeat(5)
    begin
    start_item(t);
    t.randomize();
    finish_item(t);
      `uvm_info("GEN",$sformatf("Data send to Driver a :%0d , b :%0d",t.A_in,t.B_in), UVM_NONE);  
    end
endtask
 
endclass
        
      
//////////////////////////////////////////////////////////

class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  transaction t;
  
  virtual dadda_if dif;
  
  task reset_dut();
    dif.reset<=1'b1;
    dif.A_in<=0;
    dif.B_in<=0;
    repeat(5)@(posedge dif.clk);
    dif.reset<=1'b0;
    `uvm_info("[DRV]","reset_done",UVM_LOW);
  endtask
  
  
  
  
  function new(input string path="driver",  uvm_component parent);
    super.new(path,parent);
  endfunction
  
  virtual function void  build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=transaction::type_id::create("t");
    
    if (!uvm_config_db#(virtual dadda_if)::get(this,"*","dif",dif))
      `uvm_error("DRV","uvm_config failed");
  endfunction
  
  
  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      seq_item_port.get_next_item(t);
      dif.A_in<=t.A_in;
      dif.B_in<=t.B_in;
      seq_item_port.item_done;
      `uvm_info("DRV",$sformatf("value of a:%0d,b:%0d",t.A_in,t.B_in),UVM_LOW);
      repeat(4) @(posedge dif.clk);
    end
  endtask
  
endclass
  
//////////////////////////////////////////////////////////


class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  uvm_analysis_port #(transaction) send;
  
  transaction t;
  virtual dadda_if dif;
  
  function new(input string path="monitor", uvm_component parent);
    super.new(path,parent);
    send=new("send",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=transaction::type_id::create("t");
   
    
    if(!uvm_config_db #(virtual dadda_if)::get(this,"*","dif",dif))
      `uvm_error("DRV","failed to access config");
  endfunction
  
  
  virtual task run_phase(uvm_phase phase);
    @(negedge dif.reset);
    forever begin
      repeat(4) @(posedge dif.clk);
      t.A_in=dif.A_in;
      t.B_in=dif.B_in;
      t.p_reg_out=dif.p_reg_out;
      `uvm_info("[MON]",$sformatf("values of the a:%0d,b:%0d,p_reg_out:%0d",t.A_in,t.B_in,t.p_reg_out),UVM_LOW);
      send.write(t);
    end
  endtask
  
endclass
     
////////////////////////////////////////////////////////////////

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  transaction t;
  
  uvm_analysis_imp #(transaction,scoreboard) recv;
  
  function new(input string path="scoreboard",uvm_component parent);
    super.new(path ,parent);
    recv=new("Read",this);
  endfunction
  
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=transaction::type_id::create("t");
  endfunction
  
  virtual function  void write(transaction t);
    `uvm_info("[SCO]",$sformatf("data rcvd from MON a:%0d,b:%0d,p_reg_out:%0d",t.A_in,t.B_in,t.p_reg_out),UVM_LOW);
    
    if(t.p_reg_out==t.A_in*t.B_in)
      `uvm_info("SCO","test passed",UVM_LOW)
    else
      `uvm_info("SCO","test passed",UVM_LOW);
    
  endfunction
  
endclass

///////////////////////////////////////////////////////////////




class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  driver d;
  monitor m;
  uvm_sequencer #(transaction) seqr;
  
  function new(input string path="agent", uvm_component parent);
    super.new(path,parent);
  endfunction 
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d=driver::type_id::create("d",this);
    m=monitor::type_id::create("m",this);
    seqr=uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction
 
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
endclass

///////////////////////////////////////////


class environment extends uvm_env;
  
  `uvm_component_utils(environment)
  agent a;
  scoreboard s;
  
  function new(input string path="environment", uvm_component parent);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    s=scoreboard::type_id::create("s",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
  
endclass


  
///////////////////////////////////////////////////////////


class test extends uvm_test;
  
  `uvm_component_utils(test)
  
  generator g;
  environment env;
  
  function new(input string path ="test", uvm_component parent);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    g=generator::type_id::create("g",this);
    env=environment::type_id::create("env",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    g.start(env.a.seqr);
    #60;
    phase.drop_objection(this);
  endtask
  
endclass

//////////////////////////////////////////

module mul_tb;
  
  dadda_if dif();
  
  dadda_multiplier_with_io_ff dut (.clk(dif.clk),.reset(dif.reset),.A_in(dif.A_in),.B_in(dif.B_in),.P_reg_out(dif.p_reg_out));
  
  
  initial begin
    dif.clk=0;
    dif.reset=0;
  end
  
  always #5 dif.clk = ~dif.clk;
  
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
  initial begin
    uvm_config_db #(virtual dadda_if)::set(null,"*","dif",dif);
    run_test("test");
  end
  
endmodule
