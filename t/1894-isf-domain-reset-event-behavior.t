#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP qw(decode_json);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

plan skip_all => 'Verilator runtime provider unavailable or not qualified'
    unless can_run('verilator') && darwin_verilator_runtime_qualified();
my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $original = read_file('isf/clock_domain_event_crossing.isf');
for my $kind (qw(sync async)) {
    for my $level (0, 1) {
        my $polarity = $level ? 'active_high' : 'active_low';
        my $source = $original;
        # The sync-low case is the exact checked-in source, without repair in
        # the test fixture. Other variants keep the same external pin names.
        if ($kind ne 'sync' || $level) {
            my $options = ($kind eq 'async' ? 'async ' : '') . $polarity;
            $source =~ s/\(reset (\w+_n)\)/(reset ($1 $options))/g;
        }
        my $path = "$work/${kind}_$level.isf";
        write_file($path, $source);
        subtest "$kind $polarity preserves domain/CDC policy and event behavior" => sub {
            my $actor = FSM::Adapter::ISF->new->parse_file($path);
            my $scheduler = FSM::Scheduler::ISF->new;
            my $report = decode_json($scheduler->report($actor));
            for my $domain (@{$report->{clock_domains}}) {
                is($domain->{reset}{kind}, $kind, "$domain->{name} report retains timing");
                is($domain->{reset}{polarity}, $polarity, "$domain->{name} report retains polarity");
            }
            my $lowered = $scheduler->lower($actor);
            my $top = $lowered->{files}{'clock_domain_event_crossing_top.fsm'};
            for my $side (qw(SOURCE DEST)) {
                like($top, qr/\($side\_RESET_ACTIVE_HIGH 0d$level\)/, "$side CDC level matches the domains");
                my $async = $kind eq 'async' ? 1 : 0;
                like($top, qr/\($side\_RESET_ASYNC 0d$async\)/, "$side CDC timing matches the domains");
            }
            for my $language (qw(systemverilog verilog)) {
                my $dir = "$work/${kind}_${level}_$language";
                mkdir $dir or die $!;
                my $hdl = "$dir/design." . ($language eq 'verilog' ? 'v' : 'sv');
                my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                    '--output', $hdl, $path], '');
                is($r->{exit_code}, 0, "$language real strict CLI emits the original topology") or diag($r->{stderr});
                next if $r->{exit_code};
                my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert',
                    '-Wno-fatal', '-j', '1', '-DRESET_ACTIVE_LEVEL='.$level, '--top-module', 'reset_event_tb',
                    '--Mdir', "$dir/obj", $hdl, 't/data/isf_reset_event_tb.sv']);
                ok($compile->{ok}, "$language independent event oracle builds")
                    or diag($compile->{diagnostic}, substr($compile->{stderr}, 0, 8192));
                next unless $compile->{ok};
                my $runtime = run_generated_binary(["$dir/obj/Vreset_event_tb"]);
                ok($runtime->{ok}, "$language reset/event behavior passes")
                    or diag($runtime->{diagnostic}, $runtime->{stdout}, substr($runtime->{stderr}, 0, 8192));
                like($runtime->{stdout}, qr/ISF_RESET_EVENT_PASS/, "$language oracle completes without lost or replayed events");
            }
        };
    }
}
done_testing();
sub read_file {
    open my $fh, '<', $_[0] or die $!;
    my $text = do { local $/; <$fh> }; close $fh or die $!; return $text;
}
sub write_file {
    open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!;
}
