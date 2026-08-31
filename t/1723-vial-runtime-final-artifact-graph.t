#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::VerilatorLifecycle;

my $base = 'backends/sv_portable_verilator';
my $limits = build_vial_tooling_contract()->{limits};

subtest 'finalizer admits the exact completed backend graph' => sub {
    my ($called, $manifest_seen) = (0, 0);
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::_enforce_public_backend_artifact_graph =
        sub {
            my ($artifacts) = @_;
            $called++;
            $manifest_seen = scalar grep {
                $_->{relpath} eq "$base/backend-manifest.json"
                    && $_->{content} ne "stale\n"
            } @$artifacts;
            return 1;
        };
    my $public =
        FSM::VIAL::Backend::VerilatorLifecycle::_finalize_public_result(
            finalizer_session(), finalizer_assembly(),
        );
    ok($public->{ok}, 'canonical completed backend graph finalizes');
    is($called, 1, 'finalizer applies the terminal graph authority once');
    is($manifest_seen, 1, 'authority receives the final backend manifest');
};

my $at_byte_limit = graph_attempt([
    {content => 'x' x $limits->{artifact_bytes}},
]);
is($at_byte_limit, '', 'exact backend graph byte boundary is admitted');

my $over_byte_limit = graph_attempt([
    {content => 'x' x ($limits->{artifact_bytes} + 1)},
]);
is(
    ref($over_byte_limit),
    'FSM::VIAL::Backend::VerilatorLifecycle::Failure',
    'one excess backend byte rejects through lifecycle authority',
);
is(
    ref($over_byte_limit) ? $over_byte_limit->{code} : '',
    'VIAL_RUN_LIMIT_EXCEEDED',
    'byte excess uses the stable runtime limit diagnostic',
);
is(
    ref($over_byte_limit) ? $over_byte_limit->{path} : '',
    '/artifacts',
    'byte excess identifies the public artifact graph',
);

my @at_count_limit = map { {content => ''} } 1 .. $limits->{artifacts};
is(
    graph_attempt(\@at_count_limit), '',
    'exact backend graph artifact-count boundary is admitted',
);
my @over_count_limit = (
    @at_count_limit,
    {content => ''},
);
my $over_count = graph_attempt(\@over_count_limit);
is(
    ref($over_count),
    'FSM::VIAL::Backend::VerilatorLifecycle::Failure',
    'one excess backend artifact rejects through lifecycle authority',
);
is(
    ref($over_count) ? $over_count->{code} : '',
    'VIAL_RUN_LIMIT_EXCEEDED',
    'count excess uses the stable runtime limit diagnostic',
);
is(
    ref($over_count) ? $over_count->{path} : '',
    '/artifacts',
    'count excess identifies the public artifact graph',
);

done_testing();

sub graph_attempt {
    my ($artifacts) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_enforce_public_backend_artifact_graph(
            $artifacts,
        );
        1;
    };
    return '' if $ok;
    return $@;
}

sub finalizer_session {
    return {
        operation_id => 'op-' . ('1' x 64),
        stage_rel => '.artifacts/tmp/vial/op-' . ('1' x 64),
        compile => {command_digest => '2' x 64},
        run => {command_digest => '3' x 64},
        emission => {
            backend_manifest => {
                capability_evidence => {},
                commands => {},
            },
        },
    };
}

sub finalizer_assembly {
    my $result_rel = 'results/' . ('4' x 64)
        . '/verification-result-manifest.json';
    my %artifact = map {
        $_ => artifact($_, "{}\n")
    } (
        "$base/evidence/tool-profile.json",
        "$base/commands/compile-command.json",
        "$base/commands/run-command.json",
        $result_rel,
    );
    $artifact{"$base/backend-manifest.json"} =
        artifact("$base/backend-manifest.json", "stale\n");
    return {
        artifact => \%artifact,
        result => {
            status => 'passed',
            content => "{}\n",
            manifest => {result_id => 'result/' . ('4' x 64)},
        },
        result_rel => $result_rel,
    };
}

sub artifact {
    my ($relpath, $content) = @_;
    return {
        relpath => $relpath,
        kind => 'test_artifact',
        role => 'test_artifact',
        content => $content,
    };
}
