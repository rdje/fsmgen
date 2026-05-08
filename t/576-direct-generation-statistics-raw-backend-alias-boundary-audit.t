#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'direct generation statistics raw backend maps are caller-owned snapshots' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_statistics_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_statistics_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 0))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);

    my %backend_key_for = (
        raw_intermediate_signals => 'intermediate_signals',
        raw_global_expressions   => 'global_expressions',
        raw_expression_usage     => 'expression_usage',
    );

    for my $stats_key (sort keys %backend_key_for) {
        my $backend_key = $backend_key_for{$stats_key};
        is(
            ref($result->{statistics}{$stats_key}),
            'HASH',
            "$stats_key is exposed as a hash snapshot",
        );
        isnt(
            refaddr($result->{statistics}{$stats_key}),
            refaddr($pipeline->{hdl_generator}{$backend_key}),
            "$stats_key does not reuse the backend generator hash",
        );

        $result->{statistics}{$stats_key}{__caller_mutation} = 'result branch mutation';
        ok(
            !exists $pipeline->{hdl_generator}{$backend_key}{__caller_mutation},
            "mutating $stats_key does not contaminate the backend generator",
        );

        $pipeline->{hdl_generator}{$backend_key}{__backend_mutation} = 'backend branch mutation';
        ok(
            !exists $result->{statistics}{$stats_key}{__backend_mutation},
            "mutating backend $backend_key does not contaminate returned $stats_key",
        );
    }
};

done_testing();

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
