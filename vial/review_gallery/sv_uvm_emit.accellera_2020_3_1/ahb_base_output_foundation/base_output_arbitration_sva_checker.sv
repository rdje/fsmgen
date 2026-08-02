// Generated bound SVA review checker for selected public VIAL temporal intent.
module base_output_arbitration_sva_checker (
  input logic clock,
  input logic reset,
  input logic select,
  input logic ready_in,
  input logic [1:0] transfer,
  input logic ready_out
);
  timeunit 1ns;
  timeprecision 1ps;

  default clocking checker_cb @(posedge clock);
  endclocking
  default disable iff (reset !== 1'b1);

  property started_transfer_completes_within_256;
    (select && ready_in && transfer == 2'h2) |-> ##[1:256] ready_out;
  endproperty

  selected_completion_bound: assert property (started_transfer_completes_within_256)
    else $error("VIAL temporal completion bound failed");
endmodule

bind ahb_lite_subordinate base_output_arbitration_sva_checker base_output_arbitration_sva_checker_i (
  .clock(clk),
  .reset(rst_n),
  .select(HSEL),
  .ready_in(HREADY),
  .transfer(HTRANS),
  .ready_out(HREADYOUT)
);
