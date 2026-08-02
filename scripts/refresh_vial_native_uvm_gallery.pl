#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $gallery_rel = join '/', qw(
    vial review_gallery sv_uvm_emit.accellera_2020_3_1
    ahb_base_output_foundation
);
my @gallery_parts = split m{/}, $gallery_rel;
my %filename = (
    uvm_types_package => 'fsmgen_vial_uvm_types_pkg.sv',
    uvm_component_foundations => 'fsmgen_vial_uvm_components_pkg.sv',
    uvm_fixture_interface => 'base_output_arbitration_if.sv',
    uvm_notification_interception => 'base_output_arbitration_notifications_pkg.sv',
    uvm_stimulus_services => 'base_output_arbitration_services_pkg.sv',
    uvm_checking_results => 'base_output_arbitration_checking_pkg.sv',
    bound_sva_checker => 'base_output_arbitration_sva_checker.sv',
    uvm_fixture_package => 'base_output_arbitration_pkg.sv',
    uvm_fixture_top => 'base_output_arbitration_tb.sv',
);

my $semantic_ir = FSM::VIAL::Parser->parse_source({
    text => _slurp($vial_id),
    source_name => $vial_id,
    source_catalog => {},
});
my $built = FSM::VIAL::PlanBuilder->build({
    semantic_ir => $semantic_ir,
    hial_source => {
        source_id => $hial_id,
        text => _slurp($hial_id),
        format => 'ppif',
    },
    fixture_id => undef,
    scenario_ids => [],
    execution_profile => 'core_directed_single_clock_execution_v1',
    replay_manifest => undef,
    native_extension_catalog => [],
});
die 'cannot build native UVM gallery plan: '
    . JSON::PP->new->canonical(1)->encode($built->{diagnostics}) . "\n"
    unless $built->{ok};

my $emission = FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
    execution_ir => $built->{execution_ir},
    bridge_manifest => $built->{bridge_manifest},
    backend_inputs => $built->{backend_inputs},
    artifact_root => '.artifacts/gallery/vial-native-uvm',
    backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
});
die 'cannot emit native UVM gallery: '
    . JSON::PP->new->canonical(1)->encode($emission->{diagnostics}) . "\n"
    unless $emission->{ok};

my %artifact = map { $_->{role} => $_ }
    grep { exists $filename{$_->{role}} } @{$emission->{artifacts}};
die "native UVM gallery role set is incomplete\n"
    unless keys(%artifact) == keys(%filename);

for my $role (sort keys %filename) {
    my $path = _repo_path(@gallery_parts, $filename{$role});
    open my $fh, '>:raw', $path or die "cannot write $gallery_rel/$filename{$role}: $!\n";
    print {$fh} $artifact{$role}{content}
        or die "cannot write bytes to $gallery_rel/$filename{$role}: $!\n";
    close $fh or die "cannot close $gallery_rel/$filename{$role}: $!\n";
}

print 'refreshed ', scalar(keys %filename), ' native UVM gallery sources; ',
    scalar(@{$emission->{source_map}{entries}}), ' source-map entries; ',
    scalar(@{$emission->{static_validation}{checks}}), " static checks\n";

sub _slurp {
    my ($relpath) = @_;
    my $path = _repo_path(split m{/}, $relpath);
    open my $fh, '<:raw', $path or die "cannot read $relpath: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $relpath: $!\n";
    return $text;
}

sub _repo_path {
    return File::Spec->catfile($repo_root, @_);
}
