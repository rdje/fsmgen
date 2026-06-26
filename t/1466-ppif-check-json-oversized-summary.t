#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my $fixture = File::Spec->catfile(
    $repo_root,
    qw(ppif axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif),
);
my $out_path = File::Spec->catfile($tempdir, 'oversized_depth3_check.sv');

my @command = (
    './bin/fsmgen',
    '--strict',
    '--check-json',
    '-o',
    $out_path,
    $fixture,
);

my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
    command => \@command,
);

ok($success, 'oversized PPIF manager-capacity fixture succeeds through strict check JSON');
is(join('', @{$stderr_buf || []}), '', 'oversized check JSON keeps stderr clean');
ok(!-e $out_path, 'oversized check JSON emits no HDL output file');

my $stdout = join('', @{$stdout_buf || []});
my $decoded = eval { decode_json($stdout) };
ok($decoded, 'oversized check JSON emits decodable JSON')
    or do {
        diag($stdout);
        done_testing();
        exit 0;
    };

ok($decoded->{success}, 'oversized check JSON reports success');
is($decoded->{check_schema_version}, 1, 'oversized check JSON keeps schema version');
is($decoded->{source}{resolved_path}, File::Spec->rel2abs($fixture),
    'oversized check JSON preserves PPIF source identity');
is($decoded->{support_accounting}{entry_id},
    'intent.ppif_axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue',
    'oversized check JSON preserves support-accounting entry');
is($decoded->{result}{module_name}, 'axi0_capacity_status',
    'oversized check JSON reports generated module identity');
is($decoded->{result}{state_count}, 0,
    'oversized check JSON reports source-level regular state count');
is($decoded->{result}{signal_count}, 34,
    'oversized check JSON reports source-level signal count without backend expansion');
ok(!$decoded->{generated_output}{emitted},
    'oversized check JSON records no generated output emission');

done_testing();
