#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_presence_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'symbol-rich direct semantic payload keeps bounded child-owner contracts at runtime' => sub {
    my $decoded = run_semantic_json('t/corpus/direct_size_expression_widths.fsm');
    my $semantic = $decoded->{semantic};

    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_presence_keys(),
        'symbol-rich direct semantic.module keeps bounded core keys',
    );
    assert_keys_absent(
        $semantic->{module},
        [grep { /^composition_/ } @{normalized_semantic_module_optional_metric_keys() || []}],
        'symbol-rich direct semantic.module omits composition-specific metric keys',
    );
    assert_keys_present(
        $semantic->{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'symbol-rich direct semantic.system_contract keeps bounded keys',
    );

    ok(
        ref($semantic->{explicit_system_contract}) eq 'HASH',
        'symbol-rich direct semantic.explicit_system_contract is present as a hash',
    );
    assert_keys_present(
        $semantic->{explicit_system_contract},
        normalized_semantic_explicit_system_contract_presence_keys(),
        'symbol-rich direct semantic.explicit_system_contract keeps bounded keys',
    );

    assert_signal_analysis_contract(
        $semantic->{signal_analysis},
        'symbol-rich direct semantic.signal_analysis keeps bounded buckets and entry keys',
    );

    assert_keys_present(
        $semantic->{forward_ir},
        normalized_semantic_forward_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.intent_hir keeps bounded keys',
    );
    assert_keys_absent(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_optional_composition_keys(),
        'symbol-rich direct semantic.forward_ir.intent_hir omits composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.lowered_rtl_ir keeps bounded keys',
    );
    assert_keys_absent(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'symbol-rich direct semantic.forward_ir.lowered_rtl_ir omits composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{structural_rtl_ir},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.structural_rtl_ir keeps bounded keys',
    );

    ok(
        ref($semantic->{symbol_contract}) eq 'HASH',
        'symbol-rich direct semantic.symbol_contract is present as a hash',
    );
    assert_keys_present(
        $semantic->{symbol_contract},
        normalized_semantic_symbol_contract_presence_keys(),
        'symbol-rich direct semantic.symbol_contract keeps bounded keys',
    );
    ok(
        !exists $semantic->{composition},
        'symbol-rich direct semantic payload omits the optional composition branch',
    );
};

subtest 'composition semantic payload keeps bounded child-owner contracts at runtime' => sub {
    my $decoded = run_semantic_json('fsm/apb_tb.fsm');
    my $semantic = $decoded->{semantic};

    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_presence_keys(),
        'composition semantic.module keeps bounded core keys',
    );
    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_optional_metric_keys(),
        'composition semantic.module keeps composition-only metric keys',
    );
    assert_keys_present(
        $semantic->{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition semantic.system_contract keeps bounded keys',
    );
    ok(
        exists $semantic->{explicit_system_contract}
            && !defined $semantic->{explicit_system_contract},
        'composition semantic.explicit_system_contract stays null when the top did not author +system',
    );

    assert_signal_analysis_contract(
        $semantic->{signal_analysis},
        'composition semantic.signal_analysis keeps bounded buckets and entry keys',
    );

    assert_keys_present(
        $semantic->{forward_ir},
        normalized_semantic_forward_ir_presence_keys(),
        'composition semantic.forward_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_presence_keys(),
        'composition semantic.forward_ir.intent_hir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_optional_composition_keys(),
        'composition semantic.forward_ir.intent_hir keeps composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{structural_rtl_ir},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'composition semantic.forward_ir.structural_rtl_ir keeps bounded keys',
    );

    ok(
        !exists $semantic->{symbol_contract},
        'composition semantic payload omits the optional symbol_contract branch for symbol-free tops',
    );
    ok(
        ref($semantic->{composition}) eq 'HASH',
        'composition semantic.composition is present as a hash',
    );
    assert_keys_present(
        $semantic->{composition},
        normalized_semantic_composition_presence_keys(),
        'composition semantic.composition keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{composition}{provenance_report},
        composition_report_public_top_level_keys(),
        'composition semantic.composition.provenance_report keeps bounded public keys',
    );
};

done_testing();

sub run_semantic_json {
    my ($relpath) = @_;
    my $path = repo_file($relpath);
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );

    ok($success, "semantic JSON export succeeds for $relpath");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $relpath");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub assert_signal_analysis_contract {
    my ($signal_analysis, $label) = @_;

    assert_keys_present(
        $signal_analysis,
        normalized_semantic_signal_analysis_presence_keys(),
        "$label: signal-analysis buckets stay bounded",
    );

    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$signal_analysis->{$bucket} || []};
        assert_keys_present(
            $signal_analysis->{$bucket}[0],
            normalized_semantic_signal_analysis_entry_presence_keys(),
            "$label: bucket $bucket entries stay bounded",
        );
    }
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_keys_absent {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(!exists $payload->{$key}, "$label: omits key $key");
    }
}
