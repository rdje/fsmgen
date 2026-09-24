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
    die "SemanticBuilder was loaded before the controlled include\n"
        if exists $INC{'FSM/VIAL/SemanticBuilder.pm'};
    unshift @INC, $baseline;
}
sub read_bytes {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $bytes = <$fh>; close $fh or die $!; return $bytes;
}
my @rows;
for my $version (1, 2) {
    my $path = 'vial/ahb_subordinate_base_output_arbitration'
        . ($version == 2 ? '_v2' : '') . '.vial';
    my $base = read_bytes($path);
    for my $instance (qw(base accepts completions)) {
        my $text = $base;
        if ($instance ne 'base') {
            my $changed = $text =~ s/\(value_eq \(event_count success_write accepted\) 1\)/(value_eq (model $instance count) 1)/;
            die 'authored observation must replace one expression' unless $changed == 1;
        }
        my $id = 'model_reference.vial';
        my $result = execute_vial_tool_request({
            schema => "fsmgen.vial_tool_request.v$version", schema_version => $version,
            action => 'check',
            vial_source => {source_id => $id, source_kind_hint => 'vial', text => $text,
                encoding => 'utf-8', origin => 'repository', display_name => $id,
                canonical_id => undef, relative_path => $id, metadata => {}},
            hial_source => undef,
            options => {source_style => 'auto', output_style => undef, fixture_id => undef,
                scenario_ids => [], execution_profile => undef, backend_profile => undef,
                replay_manifest => undef, native_extension_catalogs => [],
                artifact_policy => undef, quiet => JSON::PP::false},
        }, {source_catalog => {}, artifact_sink => []});
        die JSON::PP->new->encode($result->{diagnostics}) unless $result->{success};
        push @rows, {language_version => $version, selected_instance => $instance,
            source_id => $id, source_sha256 => sha256_hex($text),
            semantic_projection_sha256 => $result->{capability_evidence}{semantic_projection_sha256},
            complete_report_sha256 => sha256_hex(JSON::PP->new->canonical->utf8->encode($result)),
            success => $result->{success}, diagnostics => $result->{diagnostics}};
    }
}
my $producer = $INC{'FSM/VIAL/SemanticBuilder.pm'};
die "controlled baseline compiler was not loaded\n"
    if defined($baseline) && $producer ne "$baseline/FSM/VIAL/SemanticBuilder.pm";
print JSON::PP->new->canonical->pretty->encode({
    producer_path => $producer, producer_sha256 => sha256_hex(read_bytes($producer)), rows => \@rows,
});
