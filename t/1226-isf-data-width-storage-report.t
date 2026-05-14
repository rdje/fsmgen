#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_report {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'data-width-storage-report.isf');
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

sub entry_by_name {
    my ($items, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$items || []};
    return $entry;
}

sub assert_storage_width {
    my ($storage, $name, $kind, $width, $role, $label) = @_;
    my $entry = entry_by_name($storage, $name);
    ok($entry, "$label storage entry exists");
    is($entry->{kind}, $kind, "$label storage kind") if $entry;
    is($entry->{width}, $width, "$label storage width") if $entry;
    is($entry->{role}, $role, "$label storage role") if $entry;
}

subtest 'schedule report includes ordinary data-operation register widths' => sub {
    my $report = lower_report(<<'ISF');
(actor data_width_storage_report
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (input packet_in (width 12))
    (output packet_out (width 12))
    (output done))
  (transaction main
    (on start)
    (sample packet_in as packet_copy)
    (extract packet_copy as header payload (widths 4 8))
    (assemble header payload as packet_out)
    (shift_right shreg bit_in (width 8))
    (complete done)))
ISF

    my $storage = $report->{inferred_storage};

    assert_storage_width($storage, 'packet_copy', 'register', 12, 'sample_alias', 'sampled word');
    assert_storage_width($storage, 'header', 'register', 4, 'extract_field', 'extract header');
    assert_storage_width($storage, 'payload', 'register', 8, 'extract_field', 'extract payload');
    assert_storage_width($storage, 'packet_out', 'register', 12, 'data_register', 'assembled packet');
    assert_storage_width($storage, 'shreg', 'register', 8, 'data_register', 'explicit-width shift register');
    assert_storage_width($storage, 'done', 'register', 1, 'completion_pulse', 'completion pulse');
};

done_testing();
