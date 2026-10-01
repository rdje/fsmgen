module tb;
 localparam bit COPY_RESULT_HOLDS = __COPY_RESULT_HOLDS__;
 logic clk=0, idle_clk=0, rst_n=1, start=0;
 logic run_idle=1;
 logic [9:0] packet=0, unused=0;
 wire [1:0] phase, copied_tag, stored_piece;
 wire [4:0] seen, again, copy_seen, stored, captured, reset_seen;
 wire negative_seen, negative_again, stored_flag, done;
 __DUT__ dut(__IDLE_CLOCK__.clk(clk), .rst_n(rst_n), .start(start),
  .packet(packet), .unused(unused), .phase(phase), .copied_tag(copied_tag),
  .seen(seen), .again(again), .copy_seen(copy_seen), .stored(stored), .captured(captured),
  .reset_seen(reset_seen), .negative_seen(negative_seen),
  .negative_again(negative_again), .stored_flag(stored_flag),
  .stored_piece(stored_piece), .done(done));
 always #5 clk=~clk;
 always #7 if(run_idle) idle_clk=~idle_clk;
 // The unused sibling's input changes independently during all io operations.
 always #11 unused=unused+10'b01_00011_1_01;

 task automatic reset_and_check;
  @(negedge clk); rst_n=0; start=0;
  #1;
  if ({phase,seen,again,copy_seen,stored,captured,reset_seen,copied_tag,
    negative_seen,negative_again,stored_flag,stored_piece,done} !== '0)
   $fatal(1,"GENERATED_RESET_MISMATCH");
  repeat(2) @(negedge clk);
  rst_n=1;
  repeat(3) @(negedge clk);
  if ({phase,seen,again,copy_seen,stored,captured,reset_seen,copied_tag,
    negative_seen,negative_again,stored_flag,stored_piece,done} !== '0)
   $fatal(1,"GENERATED_RESET_HOLD_MISMATCH");
 endtask

 task automatic lap(input logic [9:0] entry_word, copy_word, live_word,
  input logic [4:0] entry_data, copy_data, live_data, prior_data,
  input logic [1:0] copy_tag, copy_piece, input logic copy_flag, live_negative);
  bit copy_result_observed;
  logic [4:0] late_copy_result;
  copy_result_observed=0;
  late_copy_result=COPY_RESULT_HOLDS ? copy_data : 5'b00000;
  @(negedge clk); packet=entry_word; start=1;
  @(negedge clk); start=0;
  wait(phase===2'd1);
  @(negedge clk); packet=copy_word;
  // The blocking binding is valid at child completion, before phase 2.
  // Sample public pins between active edges without changing input timing.
  while (phase !== 2'd2) begin
   if (phase===2'd1 && copy_seen===copy_data) copy_result_observed=1;
   @(negedge clk);
  end
  if (!copy_result_observed) $fatal(1,"GENERATED_BOUND_RESULT_WINDOW_MISMATCH");
  $display("GENERATED_COPY_WINDOW_PASS");
  packet=live_word;
  wait(done===1'b1);
  #1;
  if (reset_seen !== prior_data || captured !== entry_data)
   $fatal(1,"GENERATED_PRIOR_OR_ENTRY_MISMATCH");
  if (copy_seen !== late_copy_result)
   $fatal(1,"GENERATED_BOUND_RESULT_RETENTION_MISMATCH");
  if (stored !== copy_data || copied_tag !== copy_tag
   || stored_flag !== copy_flag || stored_piece !== copy_piece)
   $fatal(1,"GENERATED_WHOLE_COPY_MISMATCH");
  if (seen !== live_data || again !== live_data)
   $fatal(1,"GENERATED_REUSED_LIVE_MISMATCH");
  if (negative_seen !== live_negative || negative_again !== live_negative)
   $fatal(1,"GENERATED_SIGNED_MISMATCH");
  @(negedge clk); packet=0;
  run_idle=0;
  repeat(3) @(negedge clk);
  run_idle=1;
  repeat(3) @(negedge clk);
  if (copy_seen !== late_copy_result)
   $fatal(1,"GENERATED_BOUND_RESULT_IDLE_MISMATCH");
  if (seen !== live_data || again !== live_data || stored !== copy_data
   || copied_tag !== copy_tag || stored_flag !== copy_flag || stored_piece !== copy_piece || captured !== entry_data || reset_seen !== prior_data
   || negative_seen !== live_negative || negative_again !== live_negative)
   $fatal(1,"GENERATED_HOLD_OR_ISOLATION_MISMATCH");
  $display("GENERATED_LAP_PASS");
 endtask

 initial begin
  reset_and_check();
  lap(10'b01_00111_1_10,10'b10_10011_0_01,10'b11_11101_1_11,
   5'b00111,5'b10011,5'b11101,5'b10010,2'b10,2'b01,1'b0,1'b1);
  lap(10'b11_11110_0_01,10'b01_01001_1_10,10'b10_00101_0_01,
   5'b11110,5'b01001,5'b00101,5'b10011,2'b01,2'b10,1'b1,1'b0);
  $display("GENERATED_REPEATED_REQUEST_PASS");
  @(negedge clk); packet=10'b11_10101_1_10; start=1;
  @(negedge clk); start=0;
  wait(phase===2'd1); wait(phase===2'd2);
  reset_and_check();
  lap(10'b10_00011_0_11,10'b11_11000_1_00,10'b01_10001_0_10,
   5'b00011,5'b11000,5'b10001,5'b10010,2'b11,2'b00,1'b1,1'b1);
  $display("GENERATED_RESET_ABORT_PASS");
  $display("GENERATED_INPUT_RUNTIME_PASS");
  $finish;
 end
 initial begin #30000; $fatal(1,"GENERATED_RUNTIME_TIMEOUT"); end
endmodule
