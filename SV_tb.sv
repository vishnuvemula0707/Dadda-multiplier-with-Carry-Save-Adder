// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples

//system verilog verification environment for 4 bit dadda multiplier

class transaction;
  bit clk;
  bit reset;
  rand bit [3:0] A_in;
  rand bit [3:0] B_in;
  bit [7:0] p_reg_out;
 
  constraint c1{A_in inside {[4:7]};}
  constraint cd1{B_in inside {[4:7]};}
  
  
  function transaction copy();
    copy=new();
    copy.A_in=this.A_in;
    copy.B_in=this.B_in;
    //copy.p_reg_out=this.p_reg_out;
    //return copy;
  endfunction
  
endclass

//////////////////////////////////////////////////////////////////////////////

class generator;
  transaction t;
  
  event sconext;
  event done;
  
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxgs;
  
  function new( mailbox #(transaction) mbxgd, mailbox #(transaction) mbxgs);
    this.mbxgd=mbxgd;
    this.mbxgs=mbxgs;
    
    t=new();
    
  endfunction
  
  
  task run();
    repeat(5) begin
      assert(t.randomize) else $display("randomization failed");
      mbxgd.put(t.copy());
      mbxgs.put(t.copy());
      $display("[GEN] value of a:%0d ,b:%0d",t.A_in,t.B_in);
      @(sconext);
    end
    ->done;
  endtask
    
endclass

//////////////////////////////////////////////////////////////////////////////


class driver;
  
  virtual dadda_if dif;
  transaction t;
  //t=new();
  mailbox #(transaction) mbxgd;
  
  function new(mailbox #(transaction) mbxgd);
    this.mbxgd=mbxgd;
  endfunction
  
  
  task reset();
    @(posedge dif.clk);
    dif.reset<=1;
    repeat(5) @(posedge dif.clk);
    dif.reset<=0;
    @(posedge dif.clk);
    $display("[DRV] reset done");
  endtask
 
  
  task run();
    forever begin
      mbxgd.get(t);
      dif.A_in<=t.A_in;
      dif.B_in<=t.B_in;
      @(posedge dif.clk);
      $display("[DRV] value of a:%0d ,b:%0d",t.A_in,t.B_in);
    end
  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////////


class monitor;
  
  transaction t;
  
  virtual dadda_if dif;
  
  mailbox #(transaction) mbxms;
  
  function new( mailbox #(transaction) mbxms);
    this.mbxms=mbxms;
  endfunction
  
  task run();
    t=new();
    forever begin
      repeat(3)@(posedge dif.clk);
      t.p_reg_out=dif.p_reg_out;
      mbxms.put(t);
      $display("[MON] p_out_reg:%0d",t.p_reg_out);
    end  
  endtask

endclass

/////////////////////////////////////////////////////////////////////////

class scoreboard;
  transaction t;
  transaction tref;
  
  
  bit [7:0] expected;
  event sconext;
  
  mailbox #(transaction) mbxgs;
  mailbox #(transaction) mbxms;
  
  function new( mailbox #(transaction) mbxgs, mailbox #(transaction) mbxms);
    this.mbxgs=mbxgs;
    this.mbxms=mbxms;
  endfunction
  
  task run();
    forever begin
      mbxgs.get(tref);
      mbxms.get(t);
    
      expected =tref.A_in*tref.B_in;
    
     
      
      if(expected==t.p_reg_out) begin
      $display("[SCO] data matched");
      end
      else begin
      $display("[SCO] data unmatched ");
      end
      $display("[SCO] value of a:%0d ,b:%0d ,p_reg_out:%0d,expected:%0d",tref.A_in,tref.B_in,t.p_reg_out,expected);
      $display("---------------------------------------");
      
      
     ->sconext;
    end
    
  endtask
  
endclass

//////////////////////////////////////////////////////////////////////////

class environment;
  
  virtual dadda_if dif;
  
  event sconext;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxgs;
  mailbox #(transaction) mbxms;
  
  function new(virtual dadda_if dif);
    
    mbxgd=new();
    mbxgs=new();
    mbxms=new();
    
    
    gen=new(mbxgd,mbxgs);
    drv=new(mbxgd);
    mon=new(mbxms);
    sco=new(mbxgs,mbxms);
    
    drv.dif=dif;
    mon.dif=dif;
    
    gen.sconext=sconext;
    sco.sconext=sconext;
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_none
  endtask
  
  task post_test();
    wait(gen.done.triggered);
    #50; // Optional delay to let last monitor/sco finish
    $display("Simulation completed.");
    $finish;
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
  
  
endclass


//////////////////////////////////////////////////////////////////////////
    
module tb;
  environment env;
  dadda_if dif();
  
  dadda_multiplier_with_io_ff dut (dif.clk,dif.reset,dif.A_in,dif.B_in,dif.p_reg_out);
  
  initial dif.clk=0;
  
  always #5 dif.clk=~dif.clk;
  
  initial begin
    env=new(dif);
    env.run();
  end
  
endmodule
