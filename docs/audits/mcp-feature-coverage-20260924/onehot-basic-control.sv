module onehot0_probe;
  reg a=0, b=0;
  wire [1:0] packed_value={a,b};
  integer row;
  reg expected;
  initial begin
    for (row=0; row<4; row=row+1) begin
      {a,b}=row[1:0];
      expected=(row != 3);
      #1;
      if ($onehot0({a,b}) !== expected || $onehot0(packed_value) !== expected)
        $fatal(1,"onehot0 qualification failed: input=%b%b concat=%b packed=%b expected=%b",
               a,b,$onehot0({a,b}),$onehot0(packed_value),expected);
    end
    $display("onehot0 concat/packed truth-table qualification PASS");
    $finish;
  end
endmodule
