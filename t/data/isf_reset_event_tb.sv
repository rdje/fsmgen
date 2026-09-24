`ifndef RESET_ACTIVE_LEVEL
`define RESET_ACTIVE_LEVEL 0
`endif
module reset_event_tb;
  localparam bit ACTIVE = `RESET_ACTIVE_LEVEL;
  reg bus_clk = 0, core_clk = 0;
  always #5 bus_clk = !bus_clk;
  always #7 core_clk = !core_clk;
  reg bus_rst_n = ACTIVE, core_rst_n = ACTIVE;
  reg bus_start = 0;
  wire core_seen;
  integer observed = 0;
  clock_domain_event_crossing_top dut(
    .bus_clk(bus_clk), .bus_rst_n(bus_rst_n),
    .core_clk(core_clk), .core_rst_n(core_rst_n),
    .bus_start(bus_start), .core_seen(core_seen));

  always @(posedge core_clk) begin
    #1;
    if (core_seen === 1'b1) observed = observed + 1;
    else if (core_seen !== 1'b0) $fatal(1, "unknown completion output");
  end
  task settle(input integer expected);
    repeat (40) @(posedge core_clk);
    #2;
    if (observed != expected)
      $fatal(1, "event count expected %0d, observed %0d", expected, observed);
  endtask
  task send_one(input integer expected);
    @(negedge bus_clk); bus_start = 1;
    @(negedge bus_clk); bus_start = 0;
    settle(expected);
  endtask

  initial begin
    settle(0);
    @(negedge bus_clk); bus_rst_n = !ACTIVE; core_rst_n = !ACTIVE;
    settle(0);
    send_one(1);
    send_one(2);

    // A source trigger held during reset must not become a new request.
    @(negedge bus_clk); bus_rst_n = ACTIVE; bus_start = 1;
    settle(2);
    @(negedge bus_clk); bus_start = 0;
    repeat (2) @(negedge bus_clk);
    bus_rst_n = !ACTIVE;
    settle(2);
    send_one(3);

    // Resetting only the destination must not replay an old event.
    @(negedge core_clk); core_rst_n = ACTIVE;
    settle(3);
    @(negedge core_clk); core_rst_n = !ACTIVE;
    settle(3);
    send_one(4);

    @(negedge bus_clk); bus_rst_n = ACTIVE; core_rst_n = ACTIVE;
    settle(4);
    @(negedge bus_clk); bus_rst_n = !ACTIVE; core_rst_n = !ACTIVE;
    settle(4);
    send_one(5);
    $display("ISF_RESET_EVENT_PASS");
    $finish;
  end
  initial begin
    #100000;
    $fatal(1, "reset/event oracle timeout");
  end
endmodule
