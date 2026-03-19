#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'empty child entries now say child structure is blocked' => sub {
    expect_failure(
        name => 'empty_child_entry_top',
        body => <<'FSM',
(?top:empty_child_entry_top
  ()
)
FSM
        pipeline_regex => qr/Composition top 'empty_child_entry_top' contains a child entry that is empty or missing its header, .*composition child structure is blocked because every child must start with a real string header/s,
        cli_regex => qr/composition child structure is blocked because every child must start with a real string header/s,
        cli_failure_name => 'empty child entries',
    );
};

subtest 'non-string child headers now say child header shape is blocked' => sub {
    expect_failure(
        name => 'nonstring_child_header_top',
        body => <<'FSM',
(?top:nonstring_child_header_top
  ((foo))
)
FSM
        pipeline_regex => qr/Composition top 'nonstring_child_header_top' contains a child entry that does not begin with a string header, .*composition child header shape is blocked because every child must start with a real string header/s,
        cli_regex => qr/composition child header shape is blocked because every child must start with a real string header/s,
        cli_failure_name => 'non-string child headers',
    );
};

subtest 'dotted-pair child payloads now say child item-list shape is blocked' => sub {
    expect_failure(
        name => 'dotted_pair_child_top',
        body => <<'FSM',
(?top:dotted_pair_child_top
  (?fsmc:child . foo)
)
FSM
        pipeline_regex => qr/Composition top 'dotted_pair_child_top' contains child '\?fsmc:child', .*composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_regex => qr/composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_failure_name => 'dotted-pair child payloads',
    );
};

subtest 'dotted-pair ?toplink payloads now say child item-list shape is blocked' => sub {
    expect_failure(
        name => 'dotted_pair_toplink_child_top',
        body => <<'FSM',
(?top:dotted_pair_toplink_child_top
  (?toplink:wiring . foo)
)
FSM
        pipeline_regex => qr/Composition top 'dotted_pair_toplink_child_top' contains child '\?toplink:wiring', .*composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_regex => qr/composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_failure_name => 'dotted-pair ?toplink payloads',
    );
};

subtest 'dotted-pair ?ports payloads now say child item-list shape is blocked' => sub {
    expect_failure(
        name => 'dotted_pair_ports_child_top',
        body => <<'FSM',
(?top:dotted_pair_ports_child_top
  (?ports . foo)
)
FSM
        pipeline_regex => qr/Composition top 'dotted_pair_ports_child_top' contains child '\?ports', .*composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_regex => qr/composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_failure_name => 'dotted-pair ?ports payloads',
    );
};

subtest 'dotted-pair ?dtc payloads now say child item-list shape is blocked' => sub {
    expect_failure(
        name => 'dotted_pair_dtc_child_top',
        body => <<'FSM',
(?top:dotted_pair_dtc_child_top
  (?dtc:child . foo)
)
FSM
        pipeline_regex => qr/Composition top 'dotted_pair_dtc_child_top' contains child '\?dtc:child', .*composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_regex => qr/composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract/s,
        cli_failure_name => 'dotted-pair ?dtc payloads',
    );
};

done_testing();

sub expect_failure {
    my (%args) = @_;
    my $composition_path = File::Spec->catfile($tempdir, "$args{name}.fsm");
    my $output_path = File::Spec->catfile($tempdir, "$args{name}.sv");

    write_file($composition_path, $args{body});

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like($exception, $args{pipeline_regex}, "pipeline now says $args{cli_failure_name} are blocked explicitly");
    like($exception, qr/docs\/COMPOSITION_SCOPE\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the scoped composition doc");
    like($exception, qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the legacy mapping note");

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, "CLI rejects $args{cli_failure_name}");
    ok(!-e $output_path, "CLI does not emit output for $args{cli_failure_name}");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, $args{cli_regex}, "CLI surfaces the blocked diagnostic for $args{cli_failure_name}");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
