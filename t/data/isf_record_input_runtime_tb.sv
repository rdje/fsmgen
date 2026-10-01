module tb;
 logic clk=0, rst_n=1, start=0;
 logic [9:0] packet=0;
 wire [1:0] phase, copied_tag, piece;
 wire [4:0] live, captured, stored, reset_seen;
 wire flag, negative, done;
 packed_input_runtime dut(.*);
 always #5 clk=~clk;

 // Literal vectors are independent of the compiler's layout helpers:
 // tag[9:8], signed data[7:3], flag[2], piece[1:0].
 task automatic reset_and_check;
  @(negedge clk); rst_n=0; start=0;
  #1;
  if ({phase,live,captured,stored,copied_tag,flag,piece,negative,done,reset_seen} !== '0)
   $fatal(1,"PACKED_RESET_MISMATCH");
  repeat(2) @(negedge clk);
  rst_n=1;
  repeat(3) @(negedge clk);
  if ({phase,live,captured,stored,copied_tag,flag,piece,negative,done,reset_seen} !== '0)
   $fatal(1,"PACKED_RESET_HOLD_MISMATCH");
 endtask

 task automatic lap(input logic [9:0] entry_word, copy_word, live_word,
  input logic [4:0] entry_data, copy_data, live_data,
  input logic [1:0] copy_tag, live_piece,
  input logic live_flag, live_negative,
  input logic [4:0] prior_data);
  @(negedge clk); packet=entry_word; start=1;
  @(negedge clk); start=0;
  wait(phase===2'd1);
  @(negedge clk); packet=copy_word;
  wait(phase===2'd2);
  @(negedge clk); packet=live_word;
  wait(done===1'b1);
  #1;
  // Observe the held word before this request overwrites it. Reset 149 is
  // 00_10010_1_01; the later request must instead see the prior whole copy.
  if (reset_seen !== prior_data) $fatal(1,"PACKED_STORAGE_PRIOR_MISMATCH");
  if (captured !== entry_data) $fatal(1,"PACKED_ENTRY_SAMPLE_MISMATCH");
  if (stored !== copy_data || copied_tag !== copy_tag)
   $fatal(1,"PACKED_WHOLE_COPY_MISMATCH");
  if (live !== live_data || flag !== live_flag || piece !== live_piece)
   $fatal(1,"PACKED_LIVE_LAYOUT_MISMATCH");
  if (negative !== live_negative) $fatal(1,"PACKED_SIGNED_MISMATCH");
  @(negedge clk); packet=10'b00_00000_0_00;
  repeat(4) @(negedge clk);
  if (captured !== entry_data || stored !== copy_data || copied_tag !== copy_tag
   || live !== live_data || flag !== live_flag || piece !== live_piece
   || negative !== live_negative || reset_seen !== prior_data)
   $fatal(1,"PACKED_IDLE_HOLD_MISMATCH");
  $display("PACKED_LAP_PASS");
 endtask

 initial begin
  reset_and_check();
  lap(10'b01_00111_1_10,10'b10_10011_0_01,10'b11_11101_1_11,
   5'b00111,5'b10011,5'b11101,2'b10,2'b11,1'b1,1'b1,5'b10010);
  lap(10'b11_11110_0_01,10'b01_01001_1_10,10'b10_00101_0_01,
   5'b11110,5'b01001,5'b00101,2'b01,2'b01,1'b0,1'b0,5'b10011);
  $display("PACKED_REPEATED_REQUEST_PASS");

  // Abort after the whole-copy edge, then prove reset and a fresh request.
  @(negedge clk); packet=10'b11_10101_1_10; start=1;
  @(negedge clk); start=0;
  wait(phase===2'd1);
  wait(phase===2'd2);
  reset_and_check();
  lap(10'b10_00011_0_11,10'b11_11000_1_00,10'b01_10001_0_10,
   5'b00011,5'b11000,5'b10001,2'b11,2'b10,1'b0,1'b1,5'b10010);
  $display("PACKED_RESET_ABORT_PASS");
  $display("PACKED_INPUT_RUNTIME_PASS");
  $finish;
 end
 initial begin #20000; $fatal(1,"PACKED_RUNTIME_TIMEOUT"); end
endmodule
