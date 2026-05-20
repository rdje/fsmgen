#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_schedule_report_reset_keys
    isf_public_interface_schedule_report_reset_shape
);

subtest 'direct ISF schedule-report reset-shape metadata is exact' => sub {
    assert_reset_shape_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report reset-shape metadata is exact' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_reset_shape_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'schedule reports follow advertised reset shape' => sub {
    my $with_reset = report_for_file('isf/apb_requester.isf');
    ok(ref($with_reset->{reset}) eq 'HASH', 'configured reset is a hash reference');
    is_deeply(
        sorted([keys %{$with_reset->{reset}}]),
        sorted(isf_public_interface_schedule_report_reset_keys()),
        'configured reset exposes exactly the advertised reset keys',
    );

    my $defaulted_reset = report_for_source(no_reset_source(), 'inline-no-reset.isf');
    is_deeply(
        $defaulted_reset->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'legacy single-clock omitted reset defaults to async active-low rst_n',
    );

    my $domain_without_reset = report_for_source(domain_no_reset_source(), 'inline-domain-no-reset.isf');
    ok(!defined($domain_without_reset->{reset}), 'domain-owned omitted reset is JSON null');
};

done_testing();

sub assert_reset_shape_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{schedule_report_reset_shape},
        isf_public_interface_schedule_report_reset_shape(),
        "$label schedule_report_reset_shape is exact",
    );
}

sub report_for_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub report_for_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $label);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub no_reset_source {
    return <<'ISF';
(actor no_reset_probe
  (clock clk_i)
  (interface
    (output done))
  (transaction main
    (complete done)))
ISF
}

sub domain_no_reset_source {
    return <<'ISF';
(actor domain_no_reset_probe
  (clock-domains
    (domain core (clock core_clk)))
  (interface
    (output done))
  (transaction main
    (complete done)))
ISF
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
