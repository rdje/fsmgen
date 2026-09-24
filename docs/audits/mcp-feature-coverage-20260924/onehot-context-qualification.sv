module tb;
  reg a=0,b=0;
  wire [1:0] packed_value={a,b};
  initial begin
    #1;
    $display("a=%b b=%b concat=%b vector=%b literal=%b",a,b,$onehot0({a,b}),$onehot0(packed_value),$onehot0(2'b00));
    b=1; #1;
    $display("a=%b b=%b concat=%b vector=%b literal=%b",a,b,$onehot0({a,b}),$onehot0(packed_value),$onehot0(2'b01));
    a=1; #1;
    $display("a=%b b=%b concat=%b vector=%b literal=%b",a,b,$onehot0({a,b}),$onehot0(packed_value),$onehot0(2'b11));
    b=0; #1;
    $display("a=%b b=%b concat=%b vector=%b literal=%b",a,b,$onehot0({a,b}),$onehot0(packed_value),$onehot0(2'b10));
    $finish;
  end
endmodule
