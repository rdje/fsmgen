package FSM::VerificationOutput::UVM::PassiveMonitorSkeleton;

use strict;
use warnings;

use Exporter 'import';
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();

our @EXPORT_OK = qw(
    build_uvm_passive_monitor_skeleton
    write_uvm_passive_monitor_skeleton
);

sub build_uvm_passive_monitor_skeleton {
    my (%args) = @_;

    my $actor = $args{actor} || {};
    my $schedule_report = $args{schedule_report} || {};
    my $source_file = $args{source_file};
    my $actor_name = $actor->{actor_name} || $schedule_report->{source} || 'unknown_actor';
    $actor_name =~ s/\.isf\z//;

    my $observations = $schedule_report->{verification_observations} || [];
    die "Error: verification output target 'uvm-passive-monitor' requires at least one passive_monitor observation\n"
        unless ref($observations) eq 'ARRAY' && @{$observations};

    my $package_name = _sv_identifier($actor_name) . '_observation_uvm_pkg';
    my $artifact_relpath = 'uvm/' . $package_name . '.sv';

    my @manifest_observations;
    my @package_blocks;
    my %used_class_names;

    for my $observation (@{$observations}) {
        die "Error: verification observation entry is malformed\n"
            unless ref($observation) eq 'HASH';

        my $role = $observation->{role} // '';
        die "Error: verification output target 'uvm-passive-monitor' does not support observation role '$role'\n"
            unless $role eq 'passive_monitor';

        my $observation_name = $observation->{name} // 'unnamed_observation';
        my $class_stem = _sv_identifier($observation_name);
        my $snapshot_class = $class_stem . '_snapshot';
        my $monitor_class = $class_stem . '_monitor';

        for my $class_name ($snapshot_class, $monitor_class) {
            die "Error: verification output class-name collision for '$class_name'\n"
                if $used_class_names{$class_name}++;
        }

        my $signals = $observation->{signals} || [];
        die "Error: verification observation '$observation_name' has no observed signals\n"
            unless ref($signals) eq 'ARRAY' && @{$signals};

        my @manifest_signals;
        my @field_lines;
        for my $signal (@{$signals}) {
            die "Error: verification observation '$observation_name' contains malformed signal metadata\n"
                unless ref($signal) eq 'HASH';

            my $signal_name = $signal->{name} // '';
            my $field_name = _sv_identifier($signal_name);
            my $width = _positive_width($signal->{width});
            push @field_lines, '    ' . _sv_field_type($width) . ' ' . $field_name . ';';
            push @manifest_signals, {
                name => $signal_name,
                direction => $signal->{direction} // '',
                width => $width,
            };
        }

        push @manifest_observations, {
            name => $observation_name,
            role => $role,
            snapshot_class => $snapshot_class,
            monitor_class => $monitor_class,
            signals => \@manifest_signals,
        };

        push @package_blocks, _render_observation_classes(
            observation => $observation,
            snapshot_class => $snapshot_class,
            monitor_class => $monitor_class,
            field_lines => \@field_lines,
        );
    }

    my $artifact_text = _render_package(
        package_name => $package_name,
        class_blocks => \@package_blocks,
    );

    my $manifest = {
        schema_version => 1,
        mode => 'verification_output',
        target => 'uvm_passive_monitor_skeleton',
        source => {
            resolved_path => $source_file,
            source_kind => 'isf',
        },
        actor => $actor_name,
        artifacts => [
            {
                kind => 'uvm_passive_monitor_skeleton_package',
                language => 'systemverilog',
                uvm_version => '1.2',
                relpath => $artifact_relpath,
                package_name => $package_name,
                observations => \@manifest_observations,
            },
        ],
        validation => {
            claimed_uvm_compile_support => JSON::PP::false,
            uvm_compile_validator => 'none',
            artifact_shape_checked => JSON::PP::true,
            inert_behavior_checked => JSON::PP::true,
        },
    };

    return {
        package_name => $package_name,
        artifact_relpath => $artifact_relpath,
        artifact_text => $artifact_text,
        manifest_relpath => 'verification-output-manifest.json',
        manifest => $manifest,
    };
}

sub write_uvm_passive_monitor_skeleton {
    my (%args) = @_;

    my $output_dir = $args{output_dir};
    die "Error: --verification-outdir is required for --emit-verification-output uvm-passive-monitor\n"
        unless defined($output_dir) && length($output_dir);

    my $result = build_uvm_passive_monitor_skeleton(%args);

    my $uvm_dir = File::Spec->catdir($output_dir, 'uvm');
    make_path($uvm_dir) unless -d $uvm_dir;

    my $artifact_path = File::Spec->catfile($output_dir, split m{/}, $result->{artifact_relpath});
    my $manifest_path = File::Spec->catfile($output_dir, $result->{manifest_relpath});

    _write_text_file($artifact_path, $result->{artifact_text});
    _write_text_file(
        $manifest_path,
        JSON::PP->new->ascii->canonical->pretty->encode($result->{manifest}),
    );

    return {
        %{$result},
        artifact_path => $artifact_path,
        manifest_path => $manifest_path,
    };
}

sub _render_package {
    my (%args) = @_;

    my $package_name = $args{package_name};
    my $class_blocks = $args{class_blocks} || [];

    return join("\n",
        "`ifndef FSMGEN_" . uc($package_name) . "_SV",
        "`define FSMGEN_" . uc($package_name) . "_SV",
        '',
        'package ' . $package_name . ';',
        '',
        '  import uvm_pkg::*;',
        '  `include "uvm_macros.svh"',
        '',
        join("\n\n", @{$class_blocks}),
        '',
        'endpackage : ' . $package_name,
        '',
        '`endif',
        '',
    );
}

sub _render_observation_classes {
    my (%args) = @_;

    my $observation = $args{observation};
    my $snapshot_class = $args{snapshot_class};
    my $monitor_class = $args{monitor_class};
    my $field_lines = $args{field_lines} || [];

    my $name = _sv_string($observation->{name} // '');
    my $role = _sv_string($observation->{role} // '');
    my $clock = _sv_string($observation->{clock} // '');
    my $reset = ref($observation->{reset}) eq 'HASH'
        ? _sv_string($observation->{reset}{name} // '')
        : '""';
    my $signal_names = _sv_string(join(',', map { $_->{name} // '' } @{$observation->{signals} || []}));

    return join("\n",
        '  class ' . $snapshot_class . ' extends uvm_sequence_item;',
        '    `uvm_object_utils(' . $snapshot_class . ')',
        '',
        @{$field_lines},
        '',
        '    function new(string name = "' . $snapshot_class . '");',
        '      super.new(name);',
        '    endfunction',
        '',
        '  endclass : ' . $snapshot_class,
        '',
        '  class ' . $monitor_class . ' extends uvm_monitor;',
        '    `uvm_component_utils(' . $monitor_class . ')',
        '',
        '    uvm_analysis_port #(' . $snapshot_class . ') observed_ap;',
        '    localparam string OBSERVATION_NAME = ' . $name . ';',
        '    localparam string OBSERVATION_ROLE = ' . $role . ';',
        '    localparam string OBSERVATION_CLOCK = ' . $clock . ';',
        '    localparam string OBSERVATION_RESET = ' . $reset . ';',
        '    localparam string OBSERVED_SIGNALS = ' . $signal_names . ';',
        '',
        '    function new(string name, uvm_component parent);',
        '      super.new(name, parent);',
        '      observed_ap = new("observed_ap", this);',
        '    endfunction',
        '',
        '  endclass : ' . $monitor_class,
    );
}

sub _positive_width {
    my ($width) = @_;
    $width = 1 unless defined($width) && "$width" =~ /\A[0-9]+\z/ && $width > 0;
    return int($width);
}

sub _sv_field_type {
    my ($width) = @_;
    return 'bit' if $width == 1;
    return 'bit [' . ($width - 1) . ':0]';
}

sub _sv_identifier {
    my ($name) = @_;
    $name = 'unnamed' unless defined($name) && length($name);
    $name =~ s/[^A-Za-z0-9_]/_/g;
    $name = '_' . $name if $name !~ /\A[A-Za-z_]/;
    return $name;
}

sub _sv_string {
    my ($value) = @_;
    $value = '' unless defined $value;
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return '"' . $value . '"';
}

sub _write_text_file {
    my ($path, $text) = @_;

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} $text;
    close $fh;
}

1;
