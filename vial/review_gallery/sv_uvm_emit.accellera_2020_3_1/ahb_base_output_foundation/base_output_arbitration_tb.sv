// Generated native VIAL UVM top foundation; emission is not compile qualification.
module base_output_arbitration_tb;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  import base_output_arbitration_pkg::*;

  base_output_arbitration_if vial_if();

  ahb_lite_subordinate dut (
    .HADDR(vial_if.HADDR),
    .HRDATA(vial_if.HRDATA),
    .HREADY(vial_if.HREADY),
    .HREADYOUT(vial_if.HREADYOUT),
    .HRESP(vial_if.HRESP),
    .HSEL(vial_if.HSEL),
    .HSIZE(vial_if.HSIZE),
    .HTRANS(vial_if.HTRANS),
    .HWDATA(vial_if.HWDATA),
    .HWRITE(vial_if.HWRITE),
    .clk(vial_if.clk),
    .rst_n(vial_if.rst_n),
    .wait_cycles(vial_if.wait_cycles)
  );

  initial begin
    vial_if.clk = 1'b0;
    forever #5ns vial_if.clk = ~vial_if.clk;
  end

  initial begin
    vial_if.rst_n = 1'b0;
    repeat (2) @(posedge vial_if.clk);
    vial_if.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual base_output_arbitration_if)::set(null, "uvm_test_top", "vif", vial_if);
    run_test("base_output_arbitration_test");
  end
endmodule
