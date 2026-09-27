#!/usr/bin/env perl
# Read-only production re-verification; results classify the current compiler,
# not a claim that the recorded local-payload defect is repaired.
use strict;
use warnings;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(run_verilator_compile run_generated_binary);
use JSON::PP;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
my $root = abs_path('.');
make_path('.artifacts/local-rule-payload');
my $dir = abs_path('.artifacts/local-rule-payload');
open my $fh, '<', 'docs/audits/direct-controller-binding-timing-20260927.json' or die $!;
my $audit = JSON::PP->new->decode(do {local $/; <$fh>});close $fh;
my @results;
for my $case (grep {$_->{case_id} eq 'local_trigger_request_entry' || $_->{case_id} eq 'generated_live'} @{$audit->{cases}}) {
 my $work = "$dir/$case->{case_id}";make_path($work);
 for my $field (qw(source testbench)) {
  die "canonical $field hash mismatch\n" unless sha256_hex($case->{$field}) eq $case->{"${field}_sha256"};
 }
 for my $pair (['source.isf','source'],['tb.sv','testbench']) {
  open my $out, '>', "$work/$pair->[0]" or die $!;print {$out} $case->{$pair->[1]};close $out or die $!;
 }
 my $emit = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--quiet','--language','systemverilog','--output',"$work/design.sv","$work/source.isf"], '');
 die "generation failed: $emit->{stderr}" if $emit->{exit_code};
 my $compile = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','tb','--Mdir',"$work/obj","$work/design.sv","$work/tb.sv"]);
 die "compile failed: $compile->{diagnostic} $compile->{stderr}" unless $compile->{ok};
 for my $change (0,1) {
  my $run = run_generated_binary(["$work/obj/Vtb", $change ? '+CHANGE' : ()]);
  for my $field (qw(stdout stderr diagnostic)) {
   $run->{$field} =~ s/\Q$root\E/./g if defined $run->{$field};
  }
  push @results, {case_id=>$case->{case_id},change=>$change,ok=>$run->{ok},stdout=>$run->{stdout},stderr=>$run->{stderr},diagnostic=>$run->{diagnostic}};
  print "$case->{case_id} change=$change ok=".($run->{ok}//0)."\n$run->{stdout}\n";
 }
}
open my $out, '>', "$dir/current-baseline.json" or die $!; print {$out} JSON::PP->new->canonical->pretty->encode(\@results);close $out;
