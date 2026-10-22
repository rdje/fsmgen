#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'perl';
use FSM::HDL::FlattenedDT::Backend::VHDL;

my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
my $comb = "always_comb begin\nY = 1'b0;\nif (A) begin\nY = A;\nend\nend\n";
my $ff_body = "if (!rst_n) begin\nQ <= 1'b0;\nend else begin\nQ <= A;\nend\nend\n";

subtest 'unsupported procedural entrypoints return no partial artifact' => sub {
    my @cases = (
        ['legacy wildcard', "always @* begin\nif (A) begin\nY = A;\nend\nend\n"],
        ['legacy parenthesized wildcard', "always @(*) begin\nY = A;\nend\n"],
        ['legacy explicit sensitivity', "always @(A) begin\nY = A;\nend\n"],
        ['legacy sequential', "always @(posedge clk) begin\nQ <= A;\nend\n"],
        ['latch', "always_latch begin\nY = A;\nend\n"],
        ['initial', "initial begin\nY = A;\nend\n"],
        ['final', "final begin\nY = A;\nend\n"],
        ['inline comb body', 'always_comb begin Y = A; end'],
        ['inline ff body', "always_ff @(posedge clk) begin Q <= A; end"],
        ['comb header after declaration', "wire spare; $comb"],
        ['ff header after declaration', "wire spare; always_ff @(posedge clk) begin\n$ff_body"],
        ['split comb header', "always_comb\nbegin\nY = A;\nend\n"],
        ['comb without begin', "always_comb Y = A;\n"],
        ['ff without begin', "always_ff @(posedge clk) Q <= A;\n"],
        ['labeled comb header', "always_comb begin : named\nY = A;\nend\n"],
    );
    for my $case (@cases) {
        my ($name, $process) = @$case;
        my $result = eval { $backend->convert_systemverilog_to_vhdl(module_source($process)) };
        my $error = $@;
        ok(!defined($result), "$name returns no artifact");
        like($error, qr/Unsupported generated SystemVerilog shape.*unsupported direct process header/s,
            "$name identifies the unsupported process header");
    }
};

subtest 'actual generated comb and resettable ff conversion stays intact' => sub {
    my $sync = "always_ff @(posedge clk) begin\n$ff_body";
    my $async = "always_ff @(posedge clk or negedge rst_n) begin\n$ff_body";
    for my $case ([sync => $sync], [async => $async]) {
        my ($name, $ff) = @$case;
        my $vhdl = $backend->convert_systemverilog_to_vhdl(module_source($comb . $ff));
        like($vhdl, qr/process\(all\) begin\s+Y <= '0';\s+if A = '1' then\s+Y <= A;/s,
            "$name retains default and conditional combinational assignments");
        like($vhdl, qr/rising_edge\(clk\)/, "$name retains clock edge");
        like($vhdl, qr/Q <= '0';/, "$name retains reset assignment");
        like($vhdl, qr/Q <= A;/, "$name retains clocked data assignment");
        my @processes = $vhdl =~ /^  process\(/mg;
        is(scalar @processes, 2, "$name retains both authored processes");
        like($vhdl, $name eq 'async' ? qr/process\(clk, rst_n\)/ : qr/process\(clk\)/,
            "$name retains its declared sensitivity");
    }
};

subtest 'comment and quoted metadata tokens cannot invent processes' => sub {
    my $plain = $backend->convert_systemverilog_to_vhdl(module_source($comb));
    my $decoys = <<'SV';
// always @* begin Y = A; end
/*
always_comb begin
Y = 1'b0;
end
initial begin Y = A; end
*/
(* note = "always always_comb always_ff always_latch initial final" *)
SV
    is($backend->convert_systemverilog_to_vhdl(module_source($decoys . $comb)), $plain,
        'comments and quoted annotation have no executable effect');
    my $commented = $comb;
    $commented =~ s/always_comb begin/always_comb \/* initial always @* *\/ begin \/\/ final/;
    is($backend->convert_systemverilog_to_vhdl(module_source($commented)), $plain,
        'comments in an otherwise generated header do not change its process');
    my $names = "wire initial_value;\nwire always_combined;\n";
    my $vhdl = $backend->convert_systemverilog_to_vhdl(module_source($names . $comb));
    like($vhdl, qr/Y <= A;/, 'keyword prefixes in identifiers do not reject a real process');
};

done_testing();

sub module_source {
    my ($body) = @_;
    return "module process_contract (\ninput wire clk,\ninput wire rst_n,\ninput wire A,\noutput wire Y,\noutput wire Q\n);\n$body\nendmodule\n";
}
