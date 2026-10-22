module tb;
  logic clk = 0, rst_n = 1, valid = 0;
  logic [7:0] data = 0, other = 0;
  logic scalar = 0, external_label = 0;
  wire out_xor, out_and, out_or, out_odd;
  wire out_scalar_xor, out_scalar_and, out_scalar_or, out_bit, out_slice;
  wire [3:0] out_nested;
  wire [7:0] out_binary_xor, out_binary_and, out_binary_or;
  wire out_unrolled, out_label;
  wire [38:0] observed = {out_xor, out_and, out_or, out_odd,
    out_scalar_xor, out_scalar_and, out_scalar_or, out_bit, out_slice,
    out_nested, out_binary_xor, out_binary_and, out_binary_or,
    out_unrolled, out_label};
  logic [56:0] vectors [0:255];
  logic [38:0] expected;
  integer checked = 0;
  always #5 clk = ~clk;

  unary_reduction_runtime dut (
    .clk(clk), .rst_n(rst_n), .valid(valid), .data(data), .other(other),
    .scalar(scalar), .intermediate_xor_data_other_1(external_label),
    .out_xor(out_xor), .out_and(out_and), .out_or(out_or), .out_odd(out_odd),
    .out_scalar_xor(out_scalar_xor), .out_scalar_and(out_scalar_and),
    .out_scalar_or(out_scalar_or), .out_bit(out_bit), .out_slice(out_slice),
    .out_nested(out_nested), .out_binary_xor(out_binary_xor),
    .out_binary_and(out_binary_and), .out_binary_or(out_binary_or),
    .out_unrolled(out_unrolled), .out_label(out_label));

  task automatic check_value(input integer row_number);
    if (observed !== expected) begin
      $display("UNARY_RUNTIME_MISMATCH row=%0d expected=%010h actual=%010h",
        row_number, expected, observed);
      // Process completion and the independent semantic result are separate.
      // The Perl driver requires PASS for positives and this exact rejection
      // for the deliberately wrong source; exit zero alone never passes it.
      $finish;
    end
  endtask

  task automatic sweep;
    for (integer row_number = 0; row_number < 256; row_number = row_number + 1) begin
      @(negedge clk);
      {data, other, scalar, external_label} = vectors[row_number][56:39];
      expected = vectors[row_number][38:0];
      valid = 1;
      @(negedge clk); #1;
      check_value(row_number);
      checked = checked + 1;
    end
  endtask

  initial begin
    $readmemh("t/data/unary_reduction_runtime_vectors.hex", vectors);
    #1; rst_n = 0;
    repeat (2) @(negedge clk); #1;
    expected = 0; check_value(-1);
    rst_n = 1;
    sweep();
    @(negedge clk); valid = 0;
    data = ~data; other = ~other; scalar = ~scalar; external_label = ~external_label;
    repeat (3) @(negedge clk); #1;
    check_value(-2);
    $display("UNARY_RUNTIME_HOLD_PASS");
    @(negedge clk); rst_n = 0; valid = 1; data = 8'ha5;
    repeat (2) @(negedge clk); #1;
    expected = 0; check_value(-3);
    valid = 0; rst_n = 1;
    repeat (2) @(negedge clk); #1;
    check_value(-4);
    $display("UNARY_RUNTIME_RESET_PASS");
    sweep();
    if (checked != 512) begin
      $display("UNARY_RUNTIME_COUNT_MISMATCH checked=%0d", checked);
      $finish;
    end
    $display("UNARY_RUNTIME_PASS checked=%0d", checked);
    $finish;
  end
  initial begin
    #40000;
    $display("UNARY_RUNTIME_DEADLINE");
    $finish;
  end
endmodule
