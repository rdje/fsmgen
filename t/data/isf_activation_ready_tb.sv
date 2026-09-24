`ifndef ACTIVATION_TOP
`define ACTIVATION_TOP activation_ready_top
`endif
module activation_ready_tb;
  reg clk = 0, bus_clk = 0;
  always #5 clk = !clk;
  always #7 bus_clk = !bus_clk;
  reg rst_n = 0, bus_rst_n = 0;
  reg start = 0, ready = 0;
  wire done, observed;
  integer completions = 0, observations = 0;
  `ACTIVATION_TOP dut(
    .clk(clk), .rst_n(rst_n), .bus_clk(bus_clk), .bus_rst_n(bus_rst_n),
    .start(start), .done(done), .observed(observed),
`ifdef USE_WORK_READY
    .work_ready(ready));
`else
    .ready(ready));
`endif
  always @(posedge clk) begin
    #1;
    if (done === 1'b1) completions = completions + 1;
    else if (done !== 1'b0) $fatal(1, "unknown completion");
  end
  always @(posedge bus_clk) begin
    #1;
    if (observed === 1'b1) observations = observations + 1;
    else if (observed !== 1'b0) $fatal(1, "unknown worker observation");
  end
  task settle(input integer expected);
    repeat (50) @(posedge clk);
    #2;
    if (completions != expected || observations != expected)
      $fatal(1, "expected %0d activations, done=%0d observed=%0d", expected, completions, observations);
  endtask
  task blocked_activation(input integer previous);
    @(negedge bus_clk); ready = 0;
    @(negedge clk); start = 1;
    @(negedge clk); start = 0;
    settle(previous);
    // Only this authored input may release the worker. The CDC ready signals
    // must not replace it merely because they share its name.
    @(negedge bus_clk); ready = 1;
    settle(previous + 1);
  endtask
  initial begin
    settle(0);
    @(negedge clk); rst_n = 1; bus_rst_n = 1;
    settle(0);
    blocked_activation(0);
    blocked_activation(1);
    @(negedge clk); rst_n = 0; bus_rst_n = 0;
    settle(2);
    @(negedge clk); rst_n = 1; bus_rst_n = 1;
    settle(2);
    blocked_activation(2);
    $display("ISF_ACTIVATION_READY_PASS");
    $finish;
  end
  initial begin
    #100000;
    $fatal(1, "activation ready oracle timeout");
  end
endmodule
