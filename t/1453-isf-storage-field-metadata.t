#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'scalar storage fields parse, report, and leave scheduled fsm unchanged' => sub {
    my $with_fields = storage_fields_source(1);
    my $without_fields = storage_fields_source(0);

    my $actor = parse_source($with_fields, 'storage-fields.isf');
    my ($control) = grep { ($_->{name} // '') eq 'control' } @{$actor->{storage} || []};
    ok($control, 'parser keeps the control storage entry');
    is(scalar @{$control->{fields} || []}, 3, 'parser records three field metadata entries');
    is_deeply(
        [map { $_->{name} } @{$control->{fields}}],
        [qw(mode prio enable)],
        'field declaration order is preserved',
    );

    my $report = report_source($with_fields, 'storage-fields.isf');
    my $entry = storage_entry($report, 'control');
    ok($entry, 'schedule report includes the control storage entry');
    is($entry->{kind}, 'register', 'field-structured storage remains register storage') if $entry;
    is($entry->{role}, 'actor_storage', 'field-structured storage keeps actor_storage role') if $entry;
    is($entry->{width}, 8, 'field-structured storage reports the parent width') if $entry;
    is_deeply(
        $entry->{fields},
        expected_control_fields(),
        'schedule report exposes checked field metadata',
    );

    my $fsm_with_fields = lower_fsm($with_fields, 'storage-fields.isf');
    my $fsm_without_fields = lower_fsm($without_fields, 'storage-fields-opaque.isf');
    is($fsm_with_fields, $fsm_without_fields, 'field metadata does not change scheduled .fsm output');

    my $opaque_report = report_source($without_fields, 'storage-fields-opaque.isf');
    my $opaque_entry = storage_entry($opaque_report, 'control');
    ok(!exists $opaque_entry->{fields}, 'opaque storage omits fields metadata');
};

subtest 'public storage fields fixture exposes schedule metadata' => sub {
    my $source = slurp_repo_file('isf/storage_fields.isf');
    my $report = report_source($source, 'isf/storage_fields.isf');
    my $entry = storage_entry($report, 'control');

    ok($entry, 'public fixture schedule report includes control storage');
    is_deeply(
        $entry->{fields},
        expected_control_fields(),
        'public fixture schedule report exposes field metadata',
    );
};

subtest 'malformed scalar storage fields fail closed' => sub {
    assert_parse_rejected(
        bad_source('(field mode (bits 8 7))'),
        qr/field 'mode' bits \[8:7\] exceed parent width 8/,
        'out-of-range bit range is rejected after width resolution',
    );

    assert_parse_rejected(
        bad_source('(field mode (bits 7 4)) (field prio (bits 5 2))'),
        qr/field 'prio' overlaps field 'mode' at bit 4/,
        'overlapping ranges are rejected',
    );

    assert_parse_rejected(
        bad_source('(field mode (bits 7 5) (access clear_on_read))'),
        qr/access requires '\(access ro\|rw\|wo\|w1c\|w0c\|rc\|rs\|warl\|wpri\|reserved\)'/,
        'unsupported access vocabulary is rejected',
    );

    assert_parse_rejected(
        bad_source('(field mode (bits 7 5) (reset 6))'),
        qr/reset value 6 does not match parent reset slice 5/,
        'field reset must match the parent reset slice',
    );

    assert_parse_rejected(
        no_parent_reset_source('(field mode (bits 7 5) (reset 5))'),
        qr/reset metadata requires parent storage '\(reset V\)'/,
        'field reset requires an explicit parent reset in this slice',
    );

    assert_parse_rejected(
        bad_source('(field enable (bits 0 0) (enum (OFF 0) (TWO 2)))'),
        qr/enum member 'TWO' value 2 does not fit in 1 bit/,
        'enum values must fit the field width',
    );

    assert_parse_rejected(
        bad_source('(field mode (bits 7 5) (enum (IDLE 0) (IDLE 1)))'),
        qr/has duplicate member name 'IDLE'/,
        'duplicate inline enum names are rejected',
    );
};

subtest 'fields are limited to scalar width-based storage variables' => sub {
    assert_parse_rejected(<<'ISF', qr/storage bank 'data' does not accept '\(fields \.\.\.\)'/, 'banks reject fields metadata');
(actor bad_bank_fields
  (clock clk)
  (interface (input start) (output done))
  (storage
    (bank data (width 8) (depth 2)
      (fields (field byte (bits 7 0)))))
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', qr/fields require scalar '\(var \.\.\.\)' storage with '\(width N\)'/, 'typed storage rejects fields metadata');
(actor bad_typed_fields
  (types
    (type byte_t (bits 8)))
  (clock clk)
  (interface (input start) (output done))
  (storage
    (var control (type byte_t)
      (fields (field byte (bits 7 0)))))
  (transaction main
    (on start)
    (complete done)))
ISF
};

done_testing();

sub storage_fields_source {
    my ($include_fields) = @_;
    my $fields = $include_fields ? <<'FIELDS' : '';
      (fields
        (field mode (bits 7 5) (access rw) (reset 5)
          (enum (IDLE 0) (RUN 5)))
        (field prio (bits 4 2) (access rw))
        (field enable (bits 0 0) (access rw) (reset 1)
          (enum (OFF 0) (ON 1))))
FIELDS

    return <<"ISF";
(actor storage_fields
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input wdata (width 8))
    (output done)
    (output control_out (width 8)))
  (storage
    (var control (width 8) (reset 161)
$fields    ))
  (transaction main
    (on start)
    (set control wdata)
    (update control_out control)
    (complete done)))
ISF
}

sub expected_control_fields {
    return [
        {
            name   => 'mode',
            msb    => 7,
            lsb    => 5,
            width  => 3,
            access => 'rw',
            reset  => 5,
            enum   => [
                { name => 'IDLE', value => 0 },
                { name => 'RUN',  value => 5 },
            ],
        },
        {
            name   => 'prio',
            msb    => 4,
            lsb    => 2,
            width  => 3,
            access => 'rw',
        },
        {
            name   => 'enable',
            msb    => 0,
            lsb    => 0,
            width  => 1,
            access => 'rw',
            reset  => 1,
            enum   => [
                { name => 'OFF', value => 0 },
                { name => 'ON',  value => 1 },
            ],
        },
    ];
}

sub slurp_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "Cannot close $path after read: $!";
    return $contents;
}

sub bad_source {
    my ($field_forms) = @_;
    return <<"ISF";
(actor bad_storage_fields
  (clock clk)
  (interface (input start) (output done))
  (storage
    (var control (width 8) (reset 161)
      (fields $field_forms)))
  (transaction main
    (on start)
    (complete done)))
ISF
}

sub no_parent_reset_source {
    my ($field_forms) = @_;
    return <<"ISF";
(actor bad_storage_fields
  (clock clk)
  (interface (input start) (output done))
  (storage
    (var control (width 8)
      (fields $field_forms)))
  (transaction main
    (on start)
    (complete done)))
ISF
}

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub lower_fsm {
    my ($source, $label) = @_;
    my $actor = parse_source($source, $label);
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{'storage_fields.fsm'};
}

sub report_source {
    my ($source, $label) = @_;
    my $actor = parse_source($source, $label);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub storage_entry {
    my ($report, $name) = @_;
    my ($entry) = grep { ($_->{name} // '') eq $name } @{$report->{inferred_storage} || []};
    return $entry;
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, $label);
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}
