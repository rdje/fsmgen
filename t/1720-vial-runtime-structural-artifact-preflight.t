#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $vial_text = slurp_raw(repo_path(split m{/}, $vial_id));
my $hial_text = slurp_raw(repo_path(split m{/}, $hial_id));
my $original_emit = \&FSM::VIAL::Backend::SVPortableVerilator::emit;
my $runner_calls = 0;
my $sink = [];
my $result;

{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::SVPortableVerilator::emit = sub {
        my $emission = $original_emit->(@_);
        die 'reference portable-SystemVerilog emission failed'
            unless $emission->{ok};
        push @{$emission->{artifacts}}, map {
            {
                relpath => "structural-excess/$_-artifact.txt",
                kind => 'report',
                language => 'text',
                role => 'structural_excess_witness',
                content => '',
                encoding => 'utf-8',
                source_layer => 'VIAL',
                generated_from => [],
            }
        } 1 .. 257;
        return $emission;
    };
    local *FSM::VIAL::Backend::Runner::run = sub {
        ++$runner_calls;
        return {
            ok => JSON::PP::false,
            diagnostics => [{
                code => 'VIAL_RUN_HOST_ERROR',
                message => 'Runner must not receive a known structural excess',
                path => '/',
            }],
        };
    };
    $result = execute_vial_tool_request(run_request(), {
        source_catalog => {},
        artifact_sink => $sink,
        repository_root => $repo_root,
    });
}

ok(!$result->{success}, 'known complete structural artifact excess is rejected');
is($result->{diagnostics}[0]{code}, 'VIAL_MANIFEST_SCHEMA_ERROR',
    'structural excess retains the public manifest diagnostic family');
is($result->{diagnostics}[0]{semantic_path}, '/artifacts',
    'structural excess retains the public artifact path');
like($result->{diagnostics}[0]{message},
    qr/\Aartifact count exceeds the limit 256\z/,
    'structural excess reports the established exact artifact ceiling');
is($runner_calls, 0,
    'known structural excess is rejected before shared lifecycle eligibility');
is_deeply($sink, [],
    'known structural excess publishes no partial public artifact graph');

done_testing;

sub run_request {
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => 'run',
        vial_source => source_envelope($vial_id, $vial_text, 'vial'),
        hial_source => source_envelope($hial_id, $hial_text, 'ppif'),
        options => {
            source_style => 'auto',
            output_style => undef,
            fixture_id => 'base_output_arbitration',
            scenario_ids => [],
            execution_profile =>
                'core_directed_single_clock_execution_v1',
            backend_profile => 'sv_portable_verilator',
            replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => {mode => 'virtual', artifact_root => undef},
            quiet => JSON::PP::false,
        },
    };
}

sub source_envelope {
    my ($source_id, $text, $kind) = @_;
    return {
        source_id => $source_id,
        source_kind_hint => $kind,
        text => $text,
        encoding => 'utf-8',
        origin => 'memory',
        display_name => $source_id,
        canonical_id => undef,
        relative_path => $source_id,
        metadata => {},
    };
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}
