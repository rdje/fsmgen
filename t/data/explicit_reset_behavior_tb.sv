module reset_tb;
  reg clk = 0;
  always #5 clk = !clk;
  reg rst_high = 1, rst_low = 0;
  reg [3:0] data_in = 9;
  wire [3:0] q_sync_high, q_sync_low, q_async_high, q_async_low;
  sync_high dut_sync_high(.clk(clk), .reset_pin(rst_high), .DATA(data_in), .Q(q_sync_high));
  sync_low dut_sync_low(.clk(clk), .reset_pin(rst_low), .DATA(data_in), .Q(q_sync_low));
  async_high dut_async_high(.clk(clk), .reset_pin(rst_high), .DATA(data_in), .Q(q_async_high));
  async_low dut_async_low(.clk(clk), .reset_pin(rst_low), .DATA(data_in), .Q(q_async_low));
  task expect_all(input [3:0] value);
    if (q_sync_high !== value || q_sync_low !== value || q_async_high !== value || q_async_low !== value)
      $fatal(1, "all reset modes expected %d, got %d %d %d %d", value, q_sync_high, q_sync_low, q_async_high, q_async_low);
  endtask
  task expect_split(input [3:0] sync_value, input [3:0] async_value);
    if (q_sync_high !== sync_value || q_sync_low !== sync_value || q_async_high !== async_value || q_async_low !== async_value)
      $fatal(1, "reset timing/polarity mismatch: %d %d %d %d", q_sync_high, q_sync_low, q_async_high, q_async_low);
  endtask
  initial begin
    #6; expect_all(3);
    #6; rst_high = 0; rst_low = 1;
    #4; expect_all(9);
    #1; rst_high = 1; rst_low = 0;
    #1; expect_split(9, 3);
    #8; expect_all(3);
    #1; rst_high = 0; rst_low = 1; data_in = 6;
    #9; expect_all(6);
    #1; rst_high = 1; rst_low = 0;
    #1; expect_split(6, 3);
    #1; rst_high = 0; rst_low = 1;
    #5; expect_split(6, 3);
    #2; expect_all(6);
    $display("RESET_BEHAVIOR_PASS");
    $finish;
  end
endmodule
