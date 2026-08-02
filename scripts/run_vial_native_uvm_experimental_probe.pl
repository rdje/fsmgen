#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMExperimentalProbe;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $uvm_source = join '/', qw(
    .artifacts cache uvm-verilator
    656f20d087370a7c742e00188d20bbf30fa95339 source
);
my $report_rel = join '/', qw(
    vial experimental_probes
    sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0
    probe-report.json
);
my $check_only = 0;
GetOptions(
    'check' => \$check_only,
    'uvm-source=s' => \$uvm_source,
) or _usage();
_usage() if @ARGV;
_safe_relative($uvm_source, '--uvm-source');

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
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
die 'cannot build experimental native UVM probe plan: '
    . JSON::PP->new->canonical(1)->encode($built->{diagnostics}) . "\n"
    unless $built->{ok};

my $emission = FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
    execution_ir => $built->{execution_ir},
    bridge_manifest => $built->{bridge_manifest},
    backend_inputs => $built->{backend_inputs},
    artifact_root => '.artifacts/probe/vial-native-uvm',
    backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
});
die 'cannot emit experimental native UVM probe fixture: '
    . JSON::PP->new->canonical(1)->encode($emission->{diagnostics}) . "\n"
    unless $emission->{ok};

my $probe = FSM::VIAL::Backend::SVUVMExperimentalProbe->run({
    repo_root => $repo_root,
    emission => $emission,
    uvm_source_root => $uvm_source,
});
die 'native UVM experimental probe could not complete: '
    . JSON::PP->new->canonical(1)->encode($probe->{diagnostics}) . "\n"
    unless $probe->{ok};

my $report_path = _repo_path(split m{/}, $report_rel);
if ($check_only) {
    die "native UVM experimental report is missing: $report_rel\n"
        unless -f $report_path && !-l $report_path;
    my $actual = _slurp_path($report_path, $report_rel);
    die "native UVM experimental report has byte drift: $report_rel\n"
        unless $actual eq $probe->{content};
    print "native UVM experimental report current: $probe->{status}\n";
}
else {
    die "native UVM experimental report parent is unavailable\n"
        unless -d File::Spec->catdir(
            $repo_root, qw(vial experimental_probes),
            'sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0');
    die "native UVM experimental report must not overwrite a symlink\n"
        if -l $report_path;
    open my $fh, '>:raw', $report_path
        or die "cannot write $report_rel: $!\n";
    print {$fh} $probe->{content}
        or die "cannot write bytes to $report_rel: $!\n";
    close $fh or die "cannot close $report_rel: $!\n";
    print "wrote native UVM experimental report: $probe->{status}\n";
}

sub _slurp {
    my ($relative) = @_;
    return _slurp_path(
        _repo_path(split m{/}, $relative), $relative);
}

sub _slurp_path {
    my ($path, $identity) = @_;
    open my $fh, '<:raw', $path or die "cannot read $identity: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $identity: $!\n";
    return $text;
}

sub _safe_relative {
    my ($relative, $label) = @_;
    die "$label must be one safe repository-relative path\n"
        unless defined($relative) && length($relative)
            && $relative !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $relative, -1;
}

sub _repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub _usage {
    die "usage: perl scripts/run_vial_native_uvm_experimental_probe.pl "
        . "[--check] [--uvm-source REPOSITORY_RELATIVE_PATH]\n";
}
