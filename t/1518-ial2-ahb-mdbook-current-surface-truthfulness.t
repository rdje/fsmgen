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
    ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
    ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
    ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
);

subtest 'current AHB documentation is anchored to eight shipped aliases' => sub {
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
        qr/matching selected `\.ahb` profile aliases through exact-three, the generic plus matching `\.ahb` one- and two-subordinate exact-two paired sources, aggregate HBURST and aggregate BUSY-park surfaces/,
        'protocol navigation positively includes exact-three aliases, both exact-two pairings, and aggregate aliases',
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

subtest 'current AHB surfaces include exact-two and exact-three requester aliases' => sub {
    ok(
        -f repo_file('ppif/ahb_requester_busy_insert_two.ppif'),
        'generic exact-two requester source exists',
    );
    ok(
        -f repo_file('ppif/ahb_requester_busy_insert_two.ahb'),
        'exact-two requester profile alias exists',
    );
    ok(
        -f repo_file('ppif/ahb_requester_busy_insert_three.ppif'),
        'generic exact-three requester source exists',
    );
    ok(
        -f repo_file('ppif/ahb_requester_busy_insert_three.ahb'),
        'exact-three requester profile alias exists',
    );

    my $protocol_chapter = slurp('docs/book/src/16-ial2-protocol-platform-intent.md');
    my $navigation = section_between(
        $protocol_chapter,
        '## Protocol Navigation',
        '## Reviewing Generated Artifacts',
    );
    like(
        $navigation,
        qr/exact-one, exact-two, and exact-three BUSY insertion across generic `\.ppif` and matching `\.ahb` requester surfaces/,
        'protocol navigation includes exact-two and exact-three aliases',
    );
    unlike(
        $navigation,
        qr/policy\/runtime or multiple BUSY insertion/,
        'protocol navigation no longer defers every multiple-BUSY source',
    );

    my $ahb_chapter = slurp('docs/book/src/16c-ial2-ahb.md');
    like($ahb_chapter, qr/FSMGen ships forty-six public bounded AHB IAL2 entrypoints today/, 'AHB chapter records the 46-path inventory');
    like($ahb_chapter, qr/ppif\/ahb_requester_busy_insert_two\.ppif/, 'AHB chapter lists the exact-two source');
    like($ahb_chapter, qr/ppif\/ahb_requester_busy_insert_two\.ahb/, 'AHB chapter lists the exact-two profile alias');
    like($ahb_chapter, qr/ppif\/ahb_requester_busy_insert_three\.ppif/, 'AHB chapter lists the exact-three generic source');
    like($ahb_chapter, qr/ppif\/ahb_requester_busy_insert_three\.ahb/, 'AHB chapter lists the exact-three profile alias');
    like(
        $ahb_chapter,
        qr/ppif\/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park\.ppif/,
        'AHB chapter lists the generic exact-two paired composition',
    );
    like(
        $ahb_chapter,
        qr/ppif\/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park\.ahb/,
        'AHB chapter lists the exact-two paired profile alias',
    );
    like(
        $ahb_chapter,
        qr/ppif\/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park\.ppif/,
        'AHB chapter lists the generic two-subordinate exact-two paired composition',
    );
    like(
        $ahb_chapter,
        qr/ppif\/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park\.ahb/,
        'AHB chapter lists the two-subordinate exact-two paired profile alias',
    );
    like($ahb_chapter, qr/The additive exact-two extension now ships as the generic source/, 'AHB requester guide marks exact-two as shipped');
    like($ahb_chapter, qr/The additive generic exact-three source now ships/, 'AHB requester guide marks exact-three as shipped');
    like(
        $ahb_chapter,
        qr/\.3` shipped that source at 317 protocol \/ 358\s+supported\+strict \/ 41 AHB paths/s,
        'AHB chapter preserves the shipped generic exact-two paired checkpoint',
    );
    like($ahb_chapter, qr/Current support accounting is 322 protocol fixtures, 363 supported-smoke plus\s+strict fixtures, and 46 AHB paths split 23 `\.ppif` \/ 23 `\.ahb`/s, 'AHB chapter records current exact-three accounting');
    unlike($ahb_chapter, qr/The next extension is selected but \*\*not yet shipped\*\*/, 'AHB requester guide removes stale pre-implementation wording');
    unlike(
        $ahb_chapter,
        qr/matching aggregate `\.ahb` alias remain(?:s)? future work|exact-two paired `\.ahb` alias.*future/s,
        'AHB chapter no longer defers the shipped exact-two paired alias',
    );

    my $behavior = slurp('docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md');
    like($behavior, qr/Focused `t\/1521.*?keeps generated selector\s+assertions enabled/s, 'canonical behavior records the exact-two runtime proof');
    like($behavior, qr/current accounting to 322\/363 and 46 AHB\s+paths/s, 'canonical exact-two behavior points at current accounting');
    like($behavior, qr/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR/, 'canonical behavior links the shipped exact-two alias owner');

    my $exact_one_behavior = slurp('docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md');
    like($exact_one_behavior, qr/additive\s+exact-two and exact-three generic sources/s, 'canonical exact-one behavior points at both additive bounded-count sources');
    unlike($exact_one_behavior, qr/[Cc]ounts beyond two/, 'canonical exact-one behavior does not retain the stale exact-two ceiling');
    my $exact_one_fact = slurp('docs/knowledge/ial2-ahb-requester-busy-insertion-behavior.md');
    like($exact_one_fact, qr/generic exact-three requester now also ships/s, 'canonical exact-one fact points at shipped exact-three behavior');
    unlike($exact_one_fact, qr/[Cc]ounts beyond exact two/, 'canonical exact-one fact does not retain the stale exact-two ceiling');

    my $exact_two_alias_behavior = slurp('docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md');
    like($exact_two_alias_behavior, qr/matching exact-three alias\s+now moves current totals to 322\/363 and 46 AHB paths/s, 'canonical exact-two alias behavior points at current accounting');
    unlike($exact_two_alias_behavior, qr/counts beyond one\/two/, 'canonical exact-two alias behavior does not retain the stale exact-two ceiling');

    my $two_subordinate_behavior = slurp('docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md');
    like($two_subordinate_behavior, qr/Focused `t\/1525.*?real MCP call/s, 'two-subordinate behavior records focused semantic/MCP and runtime proof');
    like($two_subordinate_behavior, qr/exact-three requester alias\s+moves\s+current accounting to\s+322\/363\/46/s, 'two-subordinate behavior points at current accounting');
    like($two_subordinate_behavior, qr/t\/1526.*?read-only.*?MCP/s, 'two-subordinate behavior records focused alias semantic/MCP parity');

    my $exact_three_behavior = slurp('docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md');
    like($exact_three_behavior, qr/width-two.*?`3 -> 2 -> 1 -> 0`/s, 'exact-three behavior records unchanged lowering and direct counter proof');
    like($exact_three_behavior, qr/322 protocol fixtures, 363 supported-smoke\s+plus strict fixtures, and 46 AHB IAL2 paths/s, 'exact-three behavior records current accounting');
    like($exact_three_behavior, qr/read_only\s*=\s*true.*?shell_access\s*=\s*false/s, 'exact-three behavior records read-only MCP parity');
    like($exact_three_behavior, qr/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR/, 'exact-three generic behavior links the shipped alias owner');
    my $exact_three_alias_behavior = slurp('docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md');
    like($exact_three_alias_behavior, qr/Focused t\/1529.*?real read-only MCP/s, 'exact-three alias behavior records focused semantic/MCP parity');
    like($exact_three_alias_behavior, qr/322 protocol fixtures.*?46 AHB IAL2 paths/s, 'exact-three alias behavior records current accounting');
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
        qr/Before `\.8`.*?returned to `IDLE` without sampling.*?historical runtime evidence/s,
        'AHB direct-seed section preserves the distinct historical phase-retention evidence',
    );
    like(
        $direct_section,
        qr/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT/,
        'AHB direct-seed section links the canonical runtime audit',
    );
    like(
        $direct_section,
        qr/\.5.*?originally selected.*?selected NONSEQ.*?ACCESS.*?selected SEQ.*?UNSUPPORTED/s,
        'AHB direct-seed section preserves the historical completion-edge dispatch selection',
    );
    like(
        $direct_section,
        qr/register-input\s+mux.*?suppressed the\s+write.*?IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT/s,
        'AHB direct-seed section records and links the current lowering-substrate finding',
    );
    like(
        $direct_section,
        qr/Q-named.*?<\-.*?four states.*?no\s+pending bank.*?relaunch.*?\.8.*?ships.*?t\/1520.*?proves/s,
        'AHB direct-seed section records the shipped register-output completion repair',
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
            qr/(?=.*(?:Current phase boundary|Current completion boundary))(?=.*t\/1520)(?=.*Q-named `<-`)(?=.*(?:exactly once|one capture\/completion per\s+acceptance))/s,
            "$relative_path records the repaired direct-seed completion boundary",
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
