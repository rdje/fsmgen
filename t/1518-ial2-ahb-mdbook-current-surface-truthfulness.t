#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my @shipped_aliases = qw(
    ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
    ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
    ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
    ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
    ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
    ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
);

subtest 'current AHB documentation is anchored to six shipped aliases' => sub {
    for my $relative_path (@shipped_aliases) {
        ok(-f repo_file($relative_path), "$relative_path exists");
    }
};

subtest 'mdBook current navigation and mode surfaces include aggregate aliases' => sub {
    my $protocol_chapter = slurp('docs/book/src/16-ial2-protocol-platform-intent.md');
    my $navigation = section_between(
        $protocol_chapter,
        '## Protocol Navigation',
        '## Reviewing Generated Artifacts',
    );

    like(
        $navigation,
        qr/matching selected `\.ahb` profile aliases, including aggregate HBURST and aggregate BUSY-park surfaces/,
        'protocol navigation positively includes aggregate HBURST and BUSY-park aliases',
    );
    unlike(
        $navigation,
        qr/except the aggregate HBURST and aggregate BUSY-park aliases|matching aggregate HBURST `\.ahb` aliases.*future/s,
        'protocol navigation no longer defers shipped aggregate aliases',
    );

    my $ahb_chapter = slurp('docs/book/src/16c-ial2-ahb.md');
    my $mode_map = section_between($ahb_chapter, '## Mode Map', '## Guided PPIF Requester');
    like(
        $mode_map,
        qr/selected generic and matching `\.ahb` aggregate HBURST-aware byte-lane `SEQ` sources/,
        'AHB current mode map includes generic and alias aggregate HBURST surfaces',
    );
    unlike(
        $mode_map,
        qr/matching aggregate HBURST `\.ahb` aliases.*future/s,
        'AHB current mode map no longer calls shipped aggregate HBURST aliases future work',
    );

    my $requester_section = section_between(
        $ahb_chapter,
        '## Guided PPIF Requester',
        '## Guided PPIF Interconnect',
    );
    like(
        $requester_section,
        qr/matching aggregate HBURST `\.ahb` aliases\s+ship through their selected profile\s+surfaces/,
        'AHB requester guidance points forward to shipped aggregate HBURST aliases',
    );
    unlike(
        $requester_section,
        qr/matching aggregate HBURST `\.ahb` aliases remain deferred/,
        'AHB requester guidance no longer carries the stale aggregate alias deferral',
    );
};

subtest 'canonical current behavior records point to later alias owners' => sub {
    my @cases = (
        {
            behavior => 'docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md',
            fact => 'docs/knowledge/ial2-ahb-aggregate-hburst-seq-behavior.md',
            positive => qr/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR/,
            stale_behavior => qr/True remaining residue includes matching aggregate `\.ahb` aliases/,
            stale_fact => qr/Matching aggregate `\.ahb` aliases remain deferred after `\.770`/,
            label => 'aggregate HBURST',
        },
        {
            behavior => 'docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md',
            fact => 'docs/knowledge/ial2-ahb-aggregate-busy-park-propagation-behavior.md',
            positive => qr/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR/,
            stale_behavior => qr/True remaining residue includes the matching aggregate BUSY-park `\.ahb` aliases/,
            stale_fact => qr/matching aggregate BUSY-park `\.ahb` aliases remain deferred to a later slice/,
            label => 'aggregate BUSY-park',
        },
        {
            behavior => 'docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md',
            fact => 'docs/knowledge/ial2-ahb-paired-busy-composition-behavior.md',
            positive => qr/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR/,
            stale_behavior => qr/matching `\.ahb` alias remains later/,
            stale_fact => qr/two-subordinate `\.ahb` alias remain deferred/,
            label => 'paired BUSY',
        },
    );

    for my $case (@cases) {
        my $behavior = slurp($case->{behavior});
        my $fact = slurp($case->{fact});

        like($behavior, $case->{positive}, "$case->{label} behavior links the shipped alias owner");
        like($fact, $case->{positive}, "$case->{label} fact links the shipped alias owner");
        unlike($behavior, $case->{stale_behavior}, "$case->{label} behavior removes its stale current deferral");
        unlike($fact, $case->{stale_fact}, "$case->{label} fact removes its stale current deferral");
    }
};

subtest 'current AHB surfaces describe the shipped depth-one phase pipeline' => sub {
    my $protocol_chapter = slurp('docs/book/src/16-ial2-protocol-platform-intent.md');
    my $navigation = section_between(
        $protocol_chapter,
        '## Protocol Navigation',
        '## Reviewing Generated Artifacts',
    );
    like(
        $navigation,
        qr/one accepted active-phase bank.*retained one-hot data-phase ownership/s,
        'protocol navigation describes subordinate and interconnect phase ownership',
    );
    unlike(
        $navigation,
        qr/boundary-free active-transfer pipelining.*future task-tree-owned work/s,
        'protocol navigation no longer defers the shipped depth-one phase pipeline',
    );

    my $ahb_chapter = slurp('docs/book/src/16c-ial2-ahb.md');
    my $phase_section = section_between(
        $ahb_chapter,
        '## Boundary-Free Active Address Phases',
        '## Validation Used For This Chapter',
    );
    like(
        $phase_section,
        qr/phase_pipeline\.mode =\s+one_accepted_next_address_control/s,
        'AHB chapter names the shipped phase-pipeline report mode',
    );
    like(
        $phase_section,
        qr/two acceptances, captures, and completions.*32'h00002211/s,
        'AHB chapter records the exact repaired runtime outcome',
    );
    unlike(
        $phase_section,
        qr/pending implementation|Until `\.3` ships|known-broken/,
        'AHB chapter contains no pre-repair current-status wording',
    );

    my $direct_section = section_between(
        $ahb_chapter,
        '## Direct FSM Seeds',
        '## Residue',
    );
    like(
        $direct_section,
        qr/t\/1520.*?bus accepts 2, seed captures\/completes 1/s,
        'AHB direct-seed section records the distinct current phase-retention defect',
    );
    like(
        $direct_section,
        qr/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT/,
        'AHB direct-seed section links the canonical runtime audit',
    );
    like(
        $direct_section,
        qr/selected direct contract.*?selected NONSEQ.*?ACCESS.*?selected SEQ.*?UNSUPPORTED/s,
        'AHB direct-seed section records the selected completion-edge dispatch contract',
    );
    unlike(
        $direct_section,
        qr/direct subordinate.*shares? the generated.*phase bank/is,
        'AHB chapter does not conflate direct and generated subordinate phase behavior',
    );

    for my $relative_path (
        'docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md',
        'docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md',
        'docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md',
        'docs/knowledge/ial2-ahb-subordinate-ppif-behavior.md',
        'docs/knowledge/ial2-ahb-paired-busy-composition-behavior.md',
        'docs/knowledge/ial2-ahb-subordinate-busy-park-behavior.md',
    ) {
        my $text = slurp($relative_path);
        unlike(
            $text,
            qr/true boundary-free active-transfer pipelining.*remain(?:s)? deferred/s,
            "$relative_path no longer defers the shipped depth-one pipeline",
        );
    }

    for my $relative_path (
        'docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md',
        'docs/knowledge/ial2-ahb-subordinate-seed-behavior.md',
    ) {
        my $text = slurp($relative_path);
        like(
            $text,
            qr/t\/1520.*?two bus acceptances.*?one\s+internal\s+capture\/completion/s,
            "$relative_path records the direct-seed completion-edge loss",
        );
    }
};

done_testing();

sub repo_file {
    my ($relative_path) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative_path);
}

sub slurp {
    my ($relative_path) = @_;
    my $path = repo_file($relative_path);
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

sub section_between {
    my ($text, $start, $end) = @_;
    $text =~ /\Q$start\E(.*?)\Q$end\E/s
        or die "could not locate section from '$start' to '$end'";
    return $1;
}
