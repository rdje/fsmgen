// Generated VIAL timed-interface foundation; simulator-neutral IEEE SystemVerilog.
interface base_output_arbitration_if;
  timeunit 1ns;
  timeprecision 1ps;

  logic [31:0] HADDR;
  logic [31:0] HRDATA;
  logic HREADY;
  logic HREADYOUT;
  logic HRESP;
  logic HSEL;
  logic [2:0] HSIZE;
  logic [1:0] HTRANS;
  logic [31:0] HWDATA;
  logic HWRITE;
  logic clk;
  logic rst_n;
  logic [3:0] wait_cycles;

  clocking driver_cb @(negedge clk);
    default input #1step output #0;
    output HADDR, HREADY, HSEL, HSIZE, HTRANS, HWDATA, HWRITE, rst_n, wait_cycles;
    input HRDATA, HREADYOUT, HRESP;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #1step;
    input HADDR, HRDATA, HREADY, HREADYOUT, HRESP, HSEL, HSIZE, HTRANS, HWDATA, HWRITE, rst_n, wait_cycles;
  endclocking

  modport driver_mp(clocking driver_cb, input clk);
  modport monitor_mp(clocking monitor_cb, input clk);
endinterface
