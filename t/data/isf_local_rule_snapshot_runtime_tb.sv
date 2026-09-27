module tb;
 logic clk=0, rst_n=1, request_a=0, request_b=0, allow=1, proceed=1;
 logic [3:0] data_a=0, data_b=0;
 wire [3:0] early, observed; wire done;
 integer completions=0, before_count;
 always #5 clk=~clk;
 always @(posedge clk) begin #1; if(rst_n && done) completions++; end
 snapshot_runtime dut(.*);
 task tick; @(posedge clk); #2; endtask
 task reset_design;
  @(negedge clk); rst_n=0; request_a=0; request_b=0;
  repeat(3) tick();
  @(negedge clk); rst_n=1; allow=1; proceed=1;
 endtask
 task pulse(input bit a, input bit b, input logic [3:0] va, input logic [3:0] vb);
  @(negedge clk); request_a=a; request_b=b; data_a=va; data_b=vb;
  @(negedge clk); request_a=0; request_b=0;
 endtask
 task accepted(input logic [3:0] expected);
  tick();
  if(early!==expected) $fatal(1,"entry payload got=%0d expected=%0d",early,expected);
 endtask
 task finished(input logic [3:0] expected, input integer prior_count);
  wait(completions>prior_count); #1;
  // A held request may sample the next invocation on this delayed done edge.
  if(done!==1 || observed!==expected || completions!=prior_count+1)
   $fatal(1,"snapshot completion early=%0d observed=%0d expected=%0d count=%0d prior=%0d",
          early,observed,expected,completions,prior_count);
 endtask
 task quiet(input integer expected_count);
  repeat(15) tick();
  if(completions!=expected_count) $fatal(1,"rejected/busy request queued or completion replayed");
 endtask
 initial begin
  reset_design();
  // A one-cycle request exposes the entry payload and retains it after changes.
  before_count=completions; pulse(1,0,7,0); data_a=13; accepted(7);
  finished(7,before_count); quiet(before_count+1);
  $display("SNAPSHOT_CHANGED_INPUT_PASS");
  before_count=completions; pulse(0,1,0,9); accepted(9);
  finished(9,before_count); quiet(before_count+1);
  $display("SNAPSHOT_REPEATED_SOURCE_PASS");
  // Neither a false authored admission guard nor a zero payload queues work.
  before_count=completions; allow=0; pulse(1,0,11,0); quiet(before_count);
  allow=1; quiet(before_count);
  pulse(1,0,0,0); quiet(before_count);
  $display("SNAPSHOT_REJECTED_ENTRY_PASS");
  // Later 'on proceed' is busy work, not another payload acceptance boundary.
  proceed=0; before_count=completions; pulse(1,0,5,0); accepted(5);
  repeat(8) tick(); pulse(0,1,0,12); repeat(8) tick();
  if(early!==5 || completions!=before_count) $fatal(1,"busy request altered accepted entry");
  proceed=1; finished(5,before_count); quiet(before_count+1);
  $display("SNAPSHOT_BUSY_LATER_ENTRY_PASS");
  // Reset aborts this invocation; a new request owns fresh payload afterward.
  proceed=0; before_count=completions; pulse(1,0,3,0); accepted(3);
  repeat(8) tick(); reset_design(); quiet(before_count);
  pulse(0,1,0,10); accepted(10); finished(10,before_count); quiet(before_count+1);
  $display("SNAPSHOT_RESET_ABORT_PASS");
  // A held rule condition keeps requesting; each return to entry accepts anew.
  before_count=completions;
  @(negedge clk); request_a=1; data_a=6;
  tick(); tick(); if(early!==6) $fatal(1,"held first entry missing");
  @(negedge clk); data_a=8;
  finished(6,before_count);
  wait(early===8); #2;
  @(negedge clk); request_a=0;
  finished(8,before_count+1); quiet(before_count+2);
  $display("SNAPSHOT_HELD_LEVEL_PASS");
  // Reset makes the round-robin grant order independent of earlier requests.
  reset_design(); before_count=completions;
  pulse(1,1,4,14); accepted(4); finished(4,before_count); quiet(before_count+1);
  before_count=completions; pulse(1,1,4,14);
  if($test$plusargs("ROUND_ROBIN")) begin accepted(14); finished(14,before_count); end
  else begin accepted(4); finished(4,before_count); end
  quiet(before_count+1);
  $display("SNAPSHOT_GRANTED_SOURCES_PASS");
  $display("LOCAL_RULE_SNAPSHOT_RUNTIME_PASS"); $finish;
 end
 initial begin #50000; $fatal(1,"snapshot qualification timeout"); end
endmodule
