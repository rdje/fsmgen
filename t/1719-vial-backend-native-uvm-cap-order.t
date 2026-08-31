#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMReviewClosure;
use FSM::VIAL::Backend::SVUVMStaticValidator;

my $scale_class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $backend_class = 'FSM::VIAL::Backend::SVUVMAccellera2020_3_1';
my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $construction = $scale_class->construct({
    backend_profile => $profile,
    level => 'reference_v1',
    reference_hial_text => slurp_raw(repo_path(
        'ppif', 'ahb_lite_subordinate.ppif')),
    reference_vial_text => slurp_raw(repo_path(
        'vial', 'ahb_subordinate_base_output_arbitration.vial')),
});
ok($construction->{ok}, 'native-UVM reference construction succeeds');
my $route = $scale_class->build({construction => $construction});
ok($route->{ok}, 'native-UVM reference route builds');

my $original_artifact_preflight =
    $backend_class->can('_preflight_artifact_count');
my $original_map_preflight =
    $backend_class->can('_preflight_source_map_entry_count');
my $original_artifact = $backend_class->can('_artifact');
my $original_entries = $backend_class->can('_source_map_entries');
my $original_validate =
    'FSM::VIAL::Backend::SVUVMStaticValidator'->can('validate');
my $original_review =
    'FSM::VIAL::Backend::SVUVMReviewClosure'->can('build');

my ($accepted_artifact_preflight, $accepted_map_preflight);
my ($accepted_entry_calls, $accepted_validation_calls) = (0, 0);
my $accepted_review_calls = 0;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_artifact_count = sub {
        $accepted_artifact_preflight = defined($original_artifact_preflight)
            ? $original_artifact_preflight->(@_)
            : 16;
        return $accepted_artifact_preflight;
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_source_map_entry_count = sub {
        $accepted_map_preflight = defined($original_map_preflight)
            ? $original_map_preflight->(@_)
            : scalar(@{$_[0]});
        return $accepted_map_preflight;
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_source_map_entries = sub {
        ++$accepted_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMStaticValidator::validate = sub {
        ++$accepted_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMReviewClosure::build = sub {
        ++$accepted_review_calls;
        return $original_review->(@_);
    };
    $accepted = emit_reference();
}
ok($accepted->{ok}, 'accepted native-UVM emission remains successful');
is($accepted_artifact_preflight, 16,
    'compact artifact preflight derives the exact accepted inventory');
is($accepted_map_preflight, 75,
    'compact source-map preflight derives the exact accepted cardinality');
is($accepted_entry_calls, 1,
    'accepted emission materializes source-map entries exactly once');
is($accepted_validation_calls, 1,
    'accepted emission performs structural validation exactly once');
is($accepted_review_calls, 1,
    'accepted emission constructs review closure exactly once');
is(scalar(@{$accepted->{source_map}{entries}}), $accepted_map_preflight,
    'materialized source map matches its compact preflight');
is(scalar(@{$accepted->{artifacts}}), $accepted_artifact_preflight,
    'materialized artifact graph matches its compact preflight');

my ($byte_artifact_preflights, $byte_map_preflights) = (0, 0);
my ($byte_entry_calls, $byte_validation_calls, $byte_review_calls) = (0, 0, 0);
my $byte_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_render_types_package = sub {
        return ('x' x 16_777_217, []);
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_artifact_count = sub {
        ++$byte_artifact_preflights;
        return defined($original_artifact_preflight)
            ? $original_artifact_preflight->(@_)
            : 16;
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_source_map_entry_count = sub {
        ++$byte_map_preflights;
        return defined($original_map_preflight)
            ? $original_map_preflight->(@_)
            : scalar(@{$_[0]});
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_source_map_entries = sub {
        ++$byte_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMStaticValidator::validate = sub {
        ++$byte_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMReviewClosure::build = sub {
        ++$byte_review_calls;
        return $original_review->(@_);
    };
    $byte_rejected = emit_reference();
}
backend_failure($byte_rejected,
    'generated native UVM source exceeds the 16 MiB backend cap');
is($byte_artifact_preflights, 0,
    'exact generated bytes retain precedence over artifact admission');
is($byte_map_preflights, 0,
    'exact generated bytes retain precedence over map admission');
is($byte_entry_calls, 0,
    'generated-source excess creates no source-map entries');
is($byte_validation_calls, 0,
    'generated-source excess performs no structural validation');
is($byte_review_calls, 0,
    'generated-source excess constructs no review closure');

my ($inventory_map_preflights, $inventory_entry_calls) = (0, 0);
my ($inventory_validation_calls, $inventory_review_calls) = (0, 0);
my $inventory_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_artifact = sub {
        return () if $_[3] eq 'uvm_types_package';
        return $original_artifact->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_source_map_entry_count = sub {
        ++$inventory_map_preflights;
        return defined($original_map_preflight)
            ? $original_map_preflight->(@_)
            : scalar(@{$_[0]});
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_source_map_entries = sub {
        ++$inventory_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMStaticValidator::validate = sub {
        ++$inventory_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMReviewClosure::build = sub {
        ++$inventory_review_calls;
        return $original_review->(@_);
    };
    $inventory_rejected = emit_reference();
}
backend_failure($inventory_rejected,
    'native UVM artifact graph does not match its sixteen-artifact matrix/review contract');
is($inventory_map_preflights, 0,
    'source-inventory contradiction precedes map admission');
is($inventory_entry_calls, 0,
    'source-inventory contradiction creates no source-map entries');
is($inventory_validation_calls, 0,
    'source-inventory contradiction precedes structural validation');
is($inventory_review_calls, 0,
    'source-inventory contradiction constructs no review closure');

my ($map_entry_calls, $map_validation_calls, $map_review_calls) = (0, 0, 0);
my $map_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_preflight_source_map_entry_count = sub {
        return 1_000_001;
    };
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_source_map_entries = sub {
        ++$map_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMStaticValidator::validate = sub {
        ++$map_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::SVUVMReviewClosure::build = sub {
        ++$map_review_calls;
        return $original_review->(@_);
    };
    $map_rejected = emit_reference();
}
backend_failure($map_rejected,
    'native UVM source map exceeds its record cap', '/source_map/entries');
is($map_entry_calls, 0,
    'known source-map excess is rejected before entry materialization');
is($map_validation_calls, 0,
    'known source-map excess is rejected before structural validation');
is($map_review_calls, 0,
    'known source-map excess constructs no review closure');

my $terminal_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVUVMAccellera2020_3_1::_artifact = sub {
        return () if $_[3] eq 'backend_source_map';
        return $original_artifact->(@_);
    };
    $terminal_rejected = emit_reference();
}
backend_failure($terminal_rejected,
    'native UVM artifact graph does not match its sixteen-artifact matrix/review contract');

done_testing();

sub emit_reference {
    return $backend_class->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => '.artifacts/tmp/vial/backend-cap-order',
        backend_profile => $profile,
    });
}

sub backend_failure {
    my ($result, $message, $path) = @_;
    $path //= '/artifacts';
    ok(!$result->{ok}, "$message is rejected");
    is_deeply($result->{diagnostics}, [{
        code => 'VIAL_UVM_BACKEND_LIMIT_EXCEEDED',
        severity => 'error',
        message => $message,
        path => $path,
    }], "$message retains its exact diagnostic");
    is($result->{source_map}, undef,
        "$message returns no partial source map");
    is_deeply($result->{artifacts}, [],
        "$message publishes no partial artifact graph");
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}
