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
    open my $fh, '<:raw', $path or die $!;
    my $base = do { local $/; <$fh> }; close $fh or die $!;
    for my $selected (qw(base write alternate)) {
        my $text = $base;
        if ($selected ne 'base') {
            my $added = $text =~ s/\(transaction write "transaction\/ahb_write" ahb_write\)/(transaction write "transaction\/ahb_write" ahb_write)\n            (transaction alternate "transaction\/alternate_write" ahb_write)/;
            die 'expected one transaction binding expansion' unless $added == 1;
            my $changed = $text =~ s/\(target \(transaction write size\)\)/(target (transaction $selected size))/;
            die 'expected one fault target selection' unless $changed == 1;
        }
        my $id = 'fault_reference.vial';
        my $r = execute_vial_tool_request({
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
        die JSON::PP->new->encode($r->{diagnostics}) unless $r->{success};
        push @rows, {language_version => $version, selection => $selected,
            source_id => $id, source_sha256 => sha256_hex($text),
            semantic_projection_sha256 => $r->{capability_evidence}{semantic_projection_sha256},
            complete_report_sha256 => sha256_hex(JSON::PP->new->canonical->utf8->encode($r)),
            fault_summary => $r->{semantic_report}{packages}[0]{fixtures}[0]{faults}[0],
            success => $r->{success}, diagnostics => $r->{diagnostics}};
    }
}
my $producer = $INC{'FSM/VIAL/SemanticBuilder.pm'};
die "controlled baseline compiler was not loaded\n"
    if defined($baseline) && $producer ne "$baseline/FSM/VIAL/SemanticBuilder.pm";
print JSON::PP->new->canonical->pretty->encode({
    producer_path => $producer, producer_sha256 => sha256_hex(read_bytes($producer)), rows => \@rows,
});
