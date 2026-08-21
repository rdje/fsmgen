#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $json = JSON::PP->new->canonical(1);

subtest 'the exact T=21 selected review shape remains byte-stable' => sub {
    my $built = build_plan(21);
    ok($built->{ok}, 'the checked reference reaches native-UVM negotiation');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    is($built->{execution_ir}->as_hashref->{operation_graph}{total_operation_count}, 21,
        'the reference plan carries exactly twenty-one operations');

    my $first = emit_backend($built, 'reference');
    ok($first->{ok}, 'the exact selected review shape is admitted');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is(scalar(@{$first->{artifacts}}), 16, 'the selected graph retains sixteen artifacts');
    is(scalar(grep { $_->{language} eq 'systemverilog' } @{$first->{artifacts}}), 10,
        'the selected graph retains ten SystemVerilog sources');
    is(source_bytes($first), 138_345, 'the selected source graph remains byte-exact');
    is(scalar(@{$first->{source_map}{entries}}), 75,
        'the selected source map retains seventy-five entries');
    is(scalar(@{$first->{static_validation}{checks}}), 14,
        'the selected static validator retains fourteen checks');
    cmp_ok(longest_systemverilog_identifier($first), '<=', 255,
        'every emitted SystemVerilog identifier remains inside the backend bound');

    my $rerun = emit_backend($built, 'reference');
    is($json->encode($rerun), $json->encode($first),
        'an independent selected-shape rerun is byte-identical');
    is($first->{backend_manifest}{capability_evidence}{runtime}, 'not_run',
        'selected emission does not acquire a native-UVM runtime claim');
    is($first->{backend_manifest}{capability_evidence}{result}, 'not_produced',
        'selected emission does not acquire a native-UVM result claim');
};

for my $total (22, 128) {
    subtest "T=$total is rejected before artifact construction" => sub {
        my $built = build_plan($total);
        ok($built->{ok}, "the genuine T=$total source reaches backend negotiation");
        diag($json->encode($built->{diagnostics})) unless $built->{ok};
        is($built->{execution_ir}->as_hashref->{operation_graph}{total_operation_count}, $total,
            "the plan carries exactly $total operations");

        my $result = emit_backend($built, "unsupported-$total");
        ok(!$result->{ok}, "T=$total fails closed");
        is(scalar(@{$result->{diagnostics}}), 1,
            "T=$total returns one stable diagnostic");
        is($result->{diagnostics}[0]{code} // '', 'VIAL_UVM_BACKEND_UNSUPPORTED',
            "T=$total has the selected negotiation diagnostic code");
        is($result->{diagnostics}[0]{message} // '',
            'native UVM foundation negotiation rejected one or more requirements',
            "T=$total has the selected negotiation diagnostic message");
        is($result->{diagnostics}[0]{path} // '', '/negotiation',
            "T=$total fails at the negotiation boundary");
        is_deeply($result->{negotiation}{unsatisfied} // [],
            ['native UVM selected review matrix requires the exact 21-operation reference shape'],
            "T=$total records the exact unsatisfied shape requirement");
        is_deeply($result->{artifacts}, [], "T=$total creates no artifact graph");
        is($result->{operation_id}, undef, "T=$total creates no operation identity");
        is($result->{backend_manifest}, undef, "T=$total creates no backend manifest");
        is($result->{source_map}, undef, "T=$total creates no source map");

        my $rerun = emit_backend($built, "unsupported-$total");
        is($json->encode($rerun), $json->encode($result),
            "T=$total rejection is deterministic");
        ok(!-e repo_path('.artifacts', 'test', 'vial-native-uvm-selected-shape', "unsupported-$total"),
            "T=$total leaves no staging residue");
    };
}

subtest 'a different twenty-one-operation shape is not mistaken for the selection' => sub {
    my $built = build_plan(21, 'rename_selected_expectation');
    ok($built->{ok}, 'the changed twenty-one-operation source reaches backend negotiation');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    is($built->{execution_ir}->as_hashref->{operation_graph}{total_operation_count}, 21,
        'the changed plan still carries exactly twenty-one operations');

    my $result = emit_backend($built, 'unsupported-different-shape');
    ok(!$result->{ok}, 'the changed twenty-one-operation shape fails closed');
    is(scalar(@{$result->{diagnostics}}), 1,
        'the changed shape returns one stable diagnostic');
    is($result->{diagnostics}[0]{code} // '', 'VIAL_UVM_BACKEND_UNSUPPORTED',
        'the changed shape has the selected negotiation diagnostic code');
    is($result->{diagnostics}[0]{message} // '',
        'native UVM foundation negotiation rejected one or more requirements',
        'the changed shape has the selected negotiation diagnostic message');
    is($result->{diagnostics}[0]{path} // '', '/negotiation',
        'the changed shape fails at the negotiation boundary');
    is_deeply($result->{negotiation}{unsatisfied} // [],
        ['native UVM selected review matrix requires the exact 21-operation reference shape'],
        'the changed shape records the same stable unsatisfied requirement');
    is_deeply($result->{artifacts}, [], 'the changed shape creates no artifact graph');
    is($result->{operation_id}, undef, 'the changed shape creates no operation identity');
    is($result->{backend_manifest}, undef, 'the changed shape creates no backend manifest');
    is($result->{source_map}, undef, 'the changed shape creates no source map');
    my $rerun = emit_backend($built, 'unsupported-different-shape');
    is($json->encode($rerun), $json->encode($result),
        'the changed-shape rejection is deterministic');
    ok(!-e repo_path('.artifacts', 'test', 'vial-native-uvm-selected-shape',
            'unsupported-different-shape'),
        'the changed shape leaves no staging residue');
};

done_testing;

sub build_plan {
    my ($total, $mutation) = @_;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => source_for_total($total, $mutation),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub source_for_total {
    my ($total, $mutation) = @_;
    die "operation total must be at least the 21-operation reference\n" if $total < 21;
    my $source = slurp_raw(repo_path(split m{/}, $vial_id));
    my $needle = '              (scoreboard_check writes)))';
    my $offset = index($source, $needle);
    die "cannot locate the selected scoreboard-check insertion point\n" if $offset < 0;
    my $extra = join '', map {
        sprintf "              (expect scale_response_%08d (same (sample response) #b0))\n", $_
    } 0 .. ($total - 22);
    substr($source, $offset, 0, $extra) if length($extra);
    if (defined($mutation) && $mutation eq 'rename_selected_expectation') {
        my $changed = ($source =~ s/\(expect response_ok /\(expect renamed_response_ok /);
        die "cannot rename the selected response expectation\n" unless $changed == 1;
    }
    elsif (defined $mutation) {
        die "unknown source mutation '$mutation'\n";
    }
    return $source;
}

sub emit_backend {
    my ($built, $leaf) = @_;
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => ".artifacts/test/vial-native-uvm-selected-shape/$leaf",
        backend_profile => $profile,
    });
}

sub source_bytes {
    my ($result) = @_;
    my $bytes = 0;
    $bytes += bytes::length($_->{content})
        for grep { $_->{language} eq 'systemverilog' } @{$result->{artifacts}};
    return $bytes;
}

sub longest_systemverilog_identifier {
    my ($result) = @_;
    my $longest = 0;
    for my $artifact (grep { $_->{language} eq 'systemverilog' } @{$result->{artifacts}}) {
        while ($artifact->{content} =~ /\b([A-Za-z_][A-Za-z0-9_\$]*)\b/g) {
            my $bytes = bytes::length($1);
            $longest = $bytes if $bytes > $longest;
        }
    }
    return $longest;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
