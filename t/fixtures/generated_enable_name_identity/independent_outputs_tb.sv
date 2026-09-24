module tb;
  reg clk=0, reset=1, UP=0, DOWN=0;
  wire OUT, out;
  enable_case dut(.*);
  always #5 clk=~clk;
  task tick(input bit rst, input bit u, input bit d,
            input bit expected_upper, input bit expected_lower);
    @(negedge clk); reset=rst; UP=u; DOWN=d;
    @(posedge clk); #1;
    if (OUT !== expected_upper || out !== expected_lower)
      $fatal(1, "independent write failed reset=%b UP=%b DOWN=%b OUT=%b out=%b expected=%b%b",
             rst,u,d,OUT,out,expected_upper,expected_lower);
  endtask
  initial begin
    tick(1,0,0,0,0);
    tick(0,1,0,1,0);
    tick(0,0,0,1,0);
    tick(1,0,0,0,0);
    tick(0,0,1,0,1);
    tick(0,0,0,0,1);
    tick(1,0,0,0,0);
    tick(0,1,1,1,1);
    tick(0,0,0,1,1);
    $display("independent case-distinct output behavior PASS");
    $finish;
  end
endmodule
