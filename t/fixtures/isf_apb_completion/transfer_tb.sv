module tb;
  reg clk=0, rst_n=0, start=0, req_write=0;
  reg [31:0] req_addr=0, req_wdata=0, PRDATA=0;
  reg PREADY=0, PSLVERR=0;
  wire [31:0] PADDR, PWDATA, last_read_data;
  wire PWRITE, PSEL, PENABLE, done, last_error;
  apb_requester dut(.*);
  always #5 clk=~clk;
  task tick;
    @(posedge clk); #1;
  endtask
  task transfer(input bit write_request, input [31:0] address,
                input [31:0] write_data, input [31:0] response,
                input bit error_response, input integer wait_cycles);
    integer n;
    @(negedge clk);
    req_write=write_request; req_addr=address; req_wdata=write_data;
    PREADY=0; PRDATA=response; PSLVERR=error_response; start=1;
    @(negedge clk); start=0;
    n=0;
    while (PSEL !== 1 && n<16) begin tick(); n=n+1; end
    if (PSEL !== 1 || PENABLE !== 0) $fatal(1,"missing APB setup phase");
    n=0;
    while (PENABLE !== 1 && n<16) begin tick(); n=n+1; end
    if (PSEL !== 1 || PENABLE !== 1) $fatal(1,"missing APB access phase");
    repeat (wait_cycles) begin
      tick();
      if (PSEL !== 1 || PENABLE !== 1 || PADDR !== address ||
          PWRITE !== write_request || PWDATA !== write_data)
        $fatal(1,"request changed while waiting for PREADY");
      if (done !== 0) $fatal(1,"completion before PREADY");
    end
    @(negedge clk); PREADY=1;
    n=0;
    while (done !== 1 && n<16) begin tick(); n=n+1; end
    if (done !== 1) $fatal(1,"missing completion");
    if (PSEL !== 0 || PENABLE !== 0) $fatal(1,"completion left bus selected/enabled");
    if (last_read_data !== response || last_error !== error_response)
      $fatal(1,"wrong response: data=%h error=%b expected=%h/%b",
             last_read_data,last_error,response,error_response);
    @(negedge clk); PREADY=0;
    tick();
    if (done !== 0) $fatal(1,"completion pulse did not clear");
    if (PSEL !== 0 || PENABLE !== 0) $fatal(1,"idle bus did not remain clear");
  endtask
  initial begin
    repeat (2) tick();
    @(negedge clk); rst_n=1;
    tick();
    transfer(1,32'h100,32'h12345678,32'habcd0123,1,3);
    transfer(0,32'h204,32'h87654321,32'hc0ffee55,0,1);
    $display("APB completion, wait and repeated-transfer behavior PASS");
    $finish;
  end
  initial begin #5000; $fatal(1,"testbench timeout"); end
endmodule
