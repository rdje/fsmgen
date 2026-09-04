#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
);
use FSM::Support::VIALToolingContract qw(
    build_vial_tooling_contract_v2
);
use FSM::Support::VIALUsabilityArtifactQuality qw(
    build_vial_usability_artifact_quality_contract
);
use FSM::VIAL::Parser;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $spec_rel = 'docs/vial-spec/lifecycle-control-v2.md';
my $landing_rel = 'docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md';
my $book_rel = 'docs/book/src/16dg-vial-public-lifecycle-reference.md';
my $fixture_rel = 'vial/ahb_subordinate_base_output_arbitration_v2.vial';

my $spec = slurp(repo_path($spec_rel));
my $landing = slurp(repo_path($landing_rel));
my $book = slurp(repo_path($book_rel));
my $fixture = slurp(repo_path($fixture_rel));

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub marked_vial {
    my ($text, $name) = @_;
    my ($body) = $text =~ m{
        <!--\ lifecycle-\Q$name\E-example:start\ -->\s*
        ```vial\s*\n(.*?)\n```\s*
        <!--\ lifecycle-\Q$name\E-example:end\ -->
    }xs;
    die "missing $name lifecycle example\n" unless defined $body;
    return $body;
}

subtest 'the bounded maintained reference and mdBook route one selection' => sub {
    like(
        $landing,
        qr{\[Selected lifecycle-control revision-1 source and semantic contract\]\(vial-spec/lifecycle-control-v2[.]md\)},
        'the mandatory v2 landing routes the lifecycle part',
    );
    like(
        $book,
        qr{\[lifecycle-control family contract\]\(../../vial-spec/lifecycle-control-v2[.]md\)},
        'the task-oriented book routes the normative part',
    );
    like($book, qr{not implemented}i,
        'the book labels selection separately from implementation');
    like($book, qr{VIAL_FAMILY_UNSUPPORTED},
        'the book states the current pre-implementation diagnostic');
};

subtest 'normal and terse forms retain one target-free family spelling' => sub {
    my $normal = marked_vial($spec, 'normal');
    my $terse = marked_vial($spec, 'terse');
    my $family = $normal;
    $family =~ s/\A\(intents\n//
        or die "normal example lacks intents wrapper\n";
    $family =~ s/\)\z//
        or die "normal example lacks intents close\n";
    $family =~ s/^  //mg;
    is($family, $terse,
        'terse removes only the normal intents wrapper from this family');

    my $quality = build_vial_usability_artifact_quality_contract();
    for my $rule (@{$quality->{forbidden_vocabulary}}) {
        my $expression = qr/$rule->{expression}/i;
        unlike($normal, $expression,
            "normal example rejects $rule->{rule_id}");
        unlike($terse, $expression,
            "terse example rejects $rule->{rule_id}");
    }

    for my $head (qw(
        lifecycle fixture domain dependencies dependency when configured
        reset_inactive readiness services service target
        stimulus_start completion drain shutdown finalize deadlines deadline
        lifecycle_entered lifecycle_point within failure
    )) {
        like($terse, qr{\(\Q$head\E(?:\s|\))},
            "selected source demonstrates $head");
    }
    like($terse, qr{\(target fixture_background\)},
        'selected service uses the target-neutral background aggregate');
};

subtest 'grammar, defaults, records, timing, and failure policy are exact' => sub {
    for my $grammar (qw(
        LIFECYCLE DEPENDENCY READINESS SERVICE STIMULUS_START COMPLETION DRAIN
        SHUTDOWN FINALIZE CONDITION MILESTONE DEADLINE FAILURE
    )) {
        like($spec, qr{^\Q$grammar\E\s*:=}m,
            "grammar defines $grammar");
    }

    for my $default (
        'service cancellation | `cooperative`',
        'failure disposition | `fail`',
        'failure cleanup | `finalize`',
        'failure cleanup bound | 256 coordination-domain cycles',
        'failure diagnostics | `all`, in semantic-rank order',
    ) {
        like($spec, qr{\Q$default\E}, "default is selected: $default");
    }

    for my $kind (qw(
        dependency readiness service stimulus_start completion drain shutdown
        finalize deadline failure
    )) {
        like($spec, qr{\| `\Q$kind\E` \|},
            "semantic expansion defines $kind");
    }
    for my $effect (qw(
        complete deadline drain failure finalize ready service_start
        service_stop shutdown stimulus_start
    )) {
        like($spec, qr{`\Q$effect\E`},
            "reserved effect $effect remains explicit");
    }

    like($spec, qr{fsmgen[.]vial_lifecycle_control[.]v1},
        'semantic payload schema is selected');
    like($spec, qr{fsmgen[.]vial_lifecycle_result[.]v1},
        'normalized lifecycle result schema is selected');
    like($spec, qr{C \+ N - 1},
        'deadline inclusivity uses an exact logical-cycle formula');
    like($spec, qr{terminal status cannot return\s+to pass},
        'failure cannot become success');
};

subtest 'family-specific bounds and diagnostic ownership are finite' => sub {
    for my $row (
        ['lifecycle programs per package',
            '1,024 and no more than fixture count'],
        ['lifecycle programs per fixture', '1'],
        ['dependency records per lifecycle', '64'],
        ['service records per lifecycle', '1 in revision 1'],
        ['deadline records per lifecycle', '64'],
        ['expanded records per lifecycle', '256'],
        ['expanded lifecycle records per connected catalog', '65,536'],
        ['condition terms per lifecycle', '256'],
        ['condition nesting depth', '16'],
        ['references in one `all` condition', '64'],
        ['logical cycles in a deadline or cleanup bound', '2,147,483,647'],
        ['identifier component', 'inherited 128-byte lexical limit'],
    ) {
        like($spec, qr{\| \Q$row->[0]\E \| \Q$row->[1]\E \|},
            "$row->[0] has its exact bound");
    }

    for my $code (qw(
        VIAL_PARSE_ERROR VIAL_SEMANTIC_ERROR VIAL_LIMIT_ERROR
        VIAL_BIND_REFERENCE_ERROR VIAL_LIFECYCLE_DEADLINE_EXPIRED
        VIAL_LIFECYCLE_SERVICE_ERROR VIAL_LIFECYCLE_DRAIN_INCOMPLETE
        VIAL_LIFECYCLE_CLEANUP_TIMEOUT
    )) {
        like($spec, qr{`\Q$code\E`}, "diagnostic $code is selected");
    }
};

subtest 'registry reservation agrees while all functional maturity stays unavailable' => sub {
    my $registry = build_vial_semantic_family_registry();
    my ($family) = grep {
        $_->{family_id} eq 'lifecycle_control' && $_->{revision} == 1
    } @{$registry->{families}};
    ok($family, 'lifecycle_control revision 1 remains registered');
    is($family->{capability_id}, 'vial.family.lifecycle_control.v1',
        'family capability identity agrees with the selection');
    is_deeply($family->{effect_kinds}, [qw(
        complete deadline drain failure finalize ready service_start
        service_stop shutdown stimulus_start
    )], 'registry and selected effect vocabularies agree exactly');
    is($family->{maturity}{selection}, 'selected',
        'selection maturity remains selected');
    is_deeply(
        [grep {
            $_ ne 'selection' && $family->{maturity}{$_} ne 'unavailable'
        } @{$registry->{maturity_keys}}],
        [],
        'no functional family maturity is promoted by selection',
    );
    for my $backend (@{$family->{backend_profiles}}) {
        is_deeply(
            [grep { $backend->{maturity}{$_} ne 'unavailable' }
                qw(emission compile runtime result parity)],
            [],
            "$backend->{profile_id} remains unavailable for lifecycle control",
        );
    }
};

subtest 'current public tooling rejects before semantic output or promotion' => sub {
    my $selected_source = $fixture;
    my $normal = marked_vial($spec, 'normal');
    $selected_source =~ s/\(intents\)/$normal/
        or die "v2 fixture has no empty intents section\n";
    my $checked = FSM::VIAL::Parser->check_source({
        text => $selected_source,
        source_name => $fixture_rel,
        source_catalog => {},
    });
    ok(!$checked->{ok}, 'selected source is not accepted before implementation');
    is($checked->{diagnostics}[0]{code}, 'VIAL_FAMILY_UNSUPPORTED',
        'current rejection retains the common family diagnostic');
    is($checked->{semantic_report}, undef,
        'rejection returns no partial semantic report');

    my $tooling = build_vial_tooling_contract_v2();
    my %capability = map { $_ => 1 } @{$tooling->{capabilities}};
    ok(!$capability{'vial.family.lifecycle_control.v1'}
        && !$capability{'vial.family.lifecycle_control.deadline.v1'},
        'public discovery advertises no lifecycle capability');
    is_deeply($tooling->{unavailable_actions}, ['run'],
        'v2 run remains unavailable');
};

done_testing;
