#!/usr/bin/env perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use lib 'perl';
use FSM::VIAL::Tool qw(execute_vial_tool_request);

# Optional, exact first-party baseline compiler for a controlled comparison.
# The caller creates it from the stated Git object on the repository volume.
my $baseline = shift @ARGV;
die "at most one repository-relative baseline include root is allowed\n" if @ARGV;
if (defined $baseline) {
    die "baseline must be a repository-relative directory\n"
        unless $baseline =~ m{\A\.artifacts/[A-Za-z0-9_./-]+\z}
            && $baseline !~ m{(?:\A|/)\.\.(?:/|\z)} && -d $baseline;
    die "LifecycleControl was loaded before the controlled include\n"
        if exists $INC{'FSM/VIAL/LifecycleControl.pm'};
    unshift @INC, $baseline;
}
sub read_bytes {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $bytes = <$fh>; close $fh or die $!; return $bytes;
}
sub envelope {
    my ($id, $text, $kind) = @_;
    return {source_id => $id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'repository', display_name => $id,
        canonical_id => undef, relative_path => $id, metadata => {}};
}
my $base = read_bytes('vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial');
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $hial = read_bytes($hial_id);
my @rows;
for my $selection (qw(base empty explicit_reset explicit_configured)) {
    my $text = $base;
    if ($selection ne 'base') {
        $text =~ s/\(services\s+\(service background\s+\(target fixture_background\)\)\)/(services)/ or die 'missing service';
        $text =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/ or die 'missing dependencies';
        my $requires = $selection eq 'explicit_reset' ? '(reset_inactive bus)'
            : $selection eq 'explicit_configured' ? '(configured)' : undef;
        $text =~ s/\(readiness ready\)/(readiness ready (requires $requires))/ if defined $requires;
    }
    my $id = 'empty_readiness.vial';
    for my $action (qw(check plan)) {
        my $r = execute_vial_tool_request({
            schema => 'fsmgen.vial_tool_request.v2', schema_version => 2, action => $action,
            vial_source => envelope($id, $text, 'vial'),
            hial_source => $action eq 'plan' ? envelope($hial_id, $hial, 'ppif') : undef,
            options => {source_style => 'auto', output_style => undef,
                fixture_id => $action eq 'plan' ? 'base_output_arbitration' : undef,
                scenario_ids => [], execution_profile => $action eq 'plan' ? 'core_directed_single_clock_execution_v2' : undef,
                backend_profile => undef, replay_manifest => undef, native_extension_catalogs => [],
                artifact_policy => $action eq 'plan' ? {mode => 'virtual', artifact_root => undef} : undef,
                quiet => JSON::PP::false},
        }, {source_catalog => {}, artifact_sink => []});
        my $cap = $r->{capability_evidence} // {};
        push @rows, {selection => $selection, action => $action,
            source_id => $id, source_sha256 => sha256_hex($text),
            complete_report_sha256 => sha256_hex(JSON::PP->new->canonical->utf8->encode($r)),
            semantic_projection_sha256 => $cap->{semantic_projection_sha256},
            compatibility_projection_sha256 => $cap->{compatibility_projection_sha256},
            plan_id => $r->{plan} ? $r->{plan}{plan_id} : undef,
            success => $r->{success}, diagnostics => $r->{diagnostics}};
    }
}
my $producer = $INC{'FSM/VIAL/LifecycleControl.pm'};
die "controlled baseline compiler was not loaded\n"
    if defined($baseline) && $producer ne "$baseline/FSM/VIAL/LifecycleControl.pm";
print JSON::PP->new->canonical->pretty->encode({
    producer_path => $producer, producer_sha256 => sha256_hex(read_bytes($producer)), rows => \@rows,
});
