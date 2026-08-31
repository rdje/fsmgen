#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Backend::VHDLPortableReviewClosure;
use FSM::VIAL::Backend::VHDLPortableStaticValidator;

my $scale_class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $backend_class = 'FSM::VIAL::Backend::VHDLPortableGHDL';
my $construction = $scale_class->construct({
    backend_profile => 'vhdl_portable_ghdl',
    level => 'reference_v1',
    reference_hial_text => slurp_raw(repo_path(
        'ppif', 'ahb_lite_subordinate.ppif')),
    reference_vial_text => slurp_raw(repo_path(
        'vial', 'ahb_subordinate_base_output_arbitration.vial')),
});
ok($construction->{ok}, 'portable-VHDL reference construction succeeds');
my $route = $scale_class->build({construction => $construction});
ok($route->{ok}, 'portable-VHDL reference route builds');

my $original_artifact_preflight =
    $backend_class->can('_preflight_artifact_count');
my $original_map_preflight =
    $backend_class->can('_preflight_source_map_entry_count');
my $original_artifact = $backend_class->can('_artifact');
my $original_entries = $backend_class->can('_source_map_entries');
my $original_command = $backend_class->can('_command_record');
my $original_validate =
    'FSM::VIAL::Backend::VHDLPortableStaticValidator'->can('validate');
my $original_review =
    'FSM::VIAL::Backend::VHDLPortableReviewClosure'->can('build');

my ($accepted_artifact_preflight, $accepted_map_preflight);
my ($accepted_entry_calls, $accepted_validation_calls) = (0, 0);
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_preflight_artifact_count = sub {
        $accepted_artifact_preflight = $original_artifact_preflight->(@_);
        return $accepted_artifact_preflight;
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_preflight_source_map_entry_count = sub {
        $accepted_map_preflight = $original_map_preflight->(@_);
        return $accepted_map_preflight;
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_source_map_entries = sub {
        ++$accepted_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableStaticValidator::validate = sub {
        ++$accepted_validation_calls;
        return $original_validate->(@_);
    };
    $accepted = emit_reference();
}
ok($accepted->{ok}, 'accepted portable-VHDL emission remains successful');
is($accepted_artifact_preflight, 17,
    'compact artifact preflight derives the exact accepted inventory');
is($accepted_map_preflight, 59,
    'compact source-map preflight derives the exact accepted cardinality');
is($accepted_entry_calls, 1,
    'accepted emission materializes source-map entries exactly once');
is($accepted_validation_calls, 1,
    'accepted emission performs structural validation exactly once');
is(scalar(@{$accepted->{source_map}{entries}}), $accepted_map_preflight,
    'materialized source map matches its compact preflight');
is(scalar(@{$accepted->{artifacts}}), $accepted_artifact_preflight,
    'materialized artifact graph matches its compact preflight');

my ($byte_artifact_preflights, $byte_map_preflights) = (0, 0);
my ($byte_validation_calls, $byte_review_calls, $byte_entry_calls) = (0, 0, 0);
my $byte_command_calls = 0;
my $byte_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_render_fixture = sub {
        return 'x' x 16_777_217;
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_preflight_artifact_count = sub {
        ++$byte_artifact_preflights;
        return $original_artifact_preflight->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_preflight_source_map_entry_count = sub {
        ++$byte_map_preflights;
        return $original_map_preflight->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_source_map_entries = sub {
        ++$byte_entry_calls;
        return $original_entries->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_command_record = sub {
        ++$byte_command_calls;
        return $original_command->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableStaticValidator::validate = sub {
        ++$byte_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableReviewClosure::build = sub {
        ++$byte_review_calls;
        return $original_review->(@_);
    };
    $byte_rejected = emit_reference();
}
ok(!$byte_rejected->{ok}, 'exact generated-source byte excess is rejected');
is_deeply($byte_rejected->{diagnostics}, [{
    code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
    severity => 'error',
    message => 'generated VHDL exceeds the 16 MiB backend cap',
    path => '/artifacts',
}], 'generated-source excess retains its exact diagnostic');
is($byte_artifact_preflights, 0,
    'exact generated bytes retain precedence over artifact admission');
is($byte_map_preflights, 0,
    'exact generated bytes retain precedence over map census');
is($byte_validation_calls, 0,
    'generated-source excess performs no structural validation');
is($byte_review_calls, 0,
    'generated-source excess constructs no review closure');
is($byte_entry_calls, 0,
    'generated-source excess creates no source-map entries');
is($byte_command_calls, 0,
    'generated-source excess creates no command records');
is_deeply($byte_rejected->{artifacts}, [],
    'generated-source excess publishes no partial artifact graph');

my ($inventory_map_preflights, $inventory_validation_calls) = (0, 0);
my ($inventory_review_calls, $inventory_command_calls) = (0, 0);
my $inventory_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_artifact = sub {
        return () if $_[3] eq 'vhdl_types_package';
        return $original_artifact->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_preflight_source_map_entry_count = sub {
        ++$inventory_map_preflights;
        return $original_map_preflight->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_command_record = sub {
        ++$inventory_command_calls;
        return $original_command->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableStaticValidator::validate = sub {
        ++$inventory_validation_calls;
        return $original_validate->(@_);
    };
    local *FSM::VIAL::Backend::VHDLPortableReviewClosure::build = sub {
        ++$inventory_review_calls;
        return $original_review->(@_);
    };
    $inventory_rejected = emit_reference();
}
ok(!$inventory_rejected->{ok}, 'unexpected source inventory is rejected');
is_deeply($inventory_rejected->{diagnostics}, [{
    code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
    severity => 'error',
    message => 'portable VHDL review closure emitted an unexpected artifact count',
    path => '/artifacts',
}], 'source-inventory contradiction retains its exact diagnostic');
is($inventory_map_preflights, 0,
    'source-inventory contradiction precedes map census');
is($inventory_validation_calls, 0,
    'source-inventory contradiction precedes structural validation');
is($inventory_review_calls, 0,
    'source-inventory contradiction constructs no review closure');
is($inventory_command_calls, 0,
    'source-inventory contradiction creates no command records');
is($inventory_rejected->{source_map}, undef,
    'source-inventory contradiction returns no partial source map');
is_deeply($inventory_rejected->{artifacts}, [],
    'source-inventory contradiction publishes no partial artifact graph');

done_testing();

sub emit_reference {
    return $backend_class->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => '.artifacts/tmp/vial/backend-cap-order',
        backend_profile => 'vhdl_portable_ghdl',
    });
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
