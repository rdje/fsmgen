package FSM::VerificationOutput::VHDL::ObservationPackageSkeleton;

use strict;
use warnings;

use Exporter 'import';
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();

our @EXPORT_OK = qw(
    build_vhdl_observation_package_skeleton
    write_vhdl_observation_package_skeleton
);

my %VHDL_RESERVED = map { $_ => 1 } qw(
    abs access after alias all and architecture array assert attribute
    begin block body buffer bus case component configuration constant
    disconnect downto else elsif end entity exit file for function
    generate generic group guarded if impure in inertial inout is label
    library linkage literal loop map mod nand new next nor not null of
    on open or others out package port postponed procedure process pure
    range record register reject rem report return rol ror select severity
    signal shared sla sll sra srl subtype then to transport type unaffected
    units until use variable wait when while with xnor xor
);

sub build_vhdl_observation_package_skeleton {
    my (%args) = @_;

    my $actor = $args{actor} || {};
    my $schedule_report = $args{schedule_report} || {};
    my $source_file = $args{source_file};
    my $actor_name = $actor->{actor_name} || $schedule_report->{source} || 'unknown_actor';
    $actor_name =~ s/\.isf\z//;

    my $observations = $schedule_report->{verification_observations} || [];
    die "Error: verification output target 'vhdl-observation-package' requires at least one passive_monitor observation\n"
        unless ref($observations) eq 'ARRAY' && @{$observations};

    my $package_name = _vhdl_identifier($actor_name) . '_observation_vhdl_pkg';
    my $artifact_relpath = 'vhdl/' . $package_name . '.vhd';

    my @manifest_observations;
    my @constant_blocks;
    my %used_constant_prefixes;

    for my $observation (@{$observations}) {
        die "Error: verification observation entry is malformed\n"
            unless ref($observation) eq 'HASH';

        my $role = $observation->{role} // '';
        die "Error: verification output target 'vhdl-observation-package' does not support observation role '$role'\n"
            unless $role eq 'passive_monitor';

        my $observation_name = $observation->{name} // 'unnamed_observation';
        my $signals = $observation->{signals} || [];
        die "Error: verification observation '$observation_name' has no observed signals\n"
            unless ref($signals) eq 'ARRAY' && @{$signals};

        my $constant_prefix = _unique_constant_prefix($observation_name, \%used_constant_prefixes);
        my @manifest_signals;
        my @constant_lines = (
            '  constant ' . $constant_prefix . '_OBSERVATION_NAME : string := ' . _vhdl_string($observation_name) . ';',
            '  constant ' . $constant_prefix . '_OBSERVATION_ROLE : string := ' . _vhdl_string($role) . ';',
            '  constant ' . $constant_prefix . '_OBSERVATION_CLOCK : string := ' . _vhdl_string($observation->{clock} // '') . ';',
            '  constant ' . $constant_prefix . '_OBSERVATION_RESET : string := ' . _vhdl_string(_observation_reset_name($observation)) . ';',
            '  constant ' . $constant_prefix . '_SIGNAL_COUNT : natural := ' . scalar(@{$signals}) . ';',
        );

        for my $index (0 .. $#{$signals}) {
            my $signal = $signals->[$index];
            die "Error: verification observation '$observation_name' contains malformed signal metadata\n"
                unless ref($signal) eq 'HASH';

            my $signal_name = $signal->{name} // '';
            my $direction = $signal->{direction} // '';
            my $width = _positive_width($signal->{width});

            push @constant_lines,
                '  constant ' . $constant_prefix . '_SIGNAL_' . $index . '_NAME : string := ' . _vhdl_string($signal_name) . ';',
                '  constant ' . $constant_prefix . '_SIGNAL_' . $index . '_DIRECTION : string := ' . _vhdl_string($direction) . ';',
                '  constant ' . $constant_prefix . '_SIGNAL_' . $index . '_WIDTH : natural := ' . $width . ';';

            push @manifest_signals, {
                name => $signal_name,
                direction => $direction,
                width => $width,
            };
        }

        push @manifest_observations, {
            name => $observation_name,
            role => $role,
            constant_prefix => $constant_prefix,
            signals => \@manifest_signals,
        };

        push @constant_blocks, join("\n", @constant_lines);
    }

    my $artifact_text = _render_package(
        package_name => $package_name,
        constant_blocks => \@constant_blocks,
    );

    my $manifest = {
        schema_version => 1,
        mode => 'verification_output',
        target => 'vhdl_observation_package_skeleton',
        source => {
            resolved_path => $source_file,
            source_kind => 'isf',
        },
        actor => $actor_name,
        artifacts => [
            {
                kind => 'vhdl_observation_package_skeleton',
                language => 'vhdl',
                relpath => $artifact_relpath,
                package_name => $package_name,
                observations => \@manifest_observations,
            },
        ],
        validation => {
            claimed_vhdl_compile_support => JSON::PP::false,
            vhdl_syntax_validator => 'none',
            claimed_psl_support => JSON::PP::false,
            psl_validator => 'none',
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

sub write_vhdl_observation_package_skeleton {
    my (%args) = @_;

    my $output_dir = $args{output_dir};
    die "Error: --verification-outdir is required for --emit-verification-output vhdl-observation-package\n"
        unless defined($output_dir) && length($output_dir);

    my $result = build_vhdl_observation_package_skeleton(%args);

    my $vhdl_dir = File::Spec->catdir($output_dir, 'vhdl');
    make_path($vhdl_dir) unless -d $vhdl_dir;

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
    my $constant_blocks = $args{constant_blocks} || [];

    return join("\n",
        '-- Generated by FSMGen observation metadata package skeleton.',
        '',
        'package ' . $package_name . ' is',
        '',
        join("\n\n", @{$constant_blocks}),
        '',
        'end package ' . $package_name . ';',
        '',
    );
}

sub _unique_constant_prefix {
    my ($name, $used) = @_;

    my $base = _vhdl_constant_prefix($name);
    my $candidate = $base;
    my $suffix = 2;
    while ($used->{$candidate}) {
        $candidate = $base . '_' . $suffix++;
    }
    $used->{$candidate} = 1;
    return $candidate;
}

sub _vhdl_constant_prefix {
    my ($name) = @_;

    my $identifier = _vhdl_identifier($name);
    $identifier =~ s/\A_+//;
    $identifier =~ s/_+\z//;
    $identifier = 'unnamed' unless length($identifier);
    return uc($identifier);
}

sub _vhdl_identifier {
    my ($name) = @_;

    $name = 'unnamed' unless defined($name) && length($name);
    $name = lc($name);
    $name =~ s/[^a-z0-9]+/_/g;
    $name =~ s/_+/_/g;
    $name =~ s/\A_+//;
    $name =~ s/_+\z//;
    $name = 'unnamed' unless length($name);
    $name = 'fsmgen_' . $name if $name !~ /\A[a-z]/;
    $name .= '_id' if $VHDL_RESERVED{$name};
    return $name;
}

sub _observation_reset_name {
    my ($observation) = @_;

    return '' unless ref($observation->{reset}) eq 'HASH';
    return $observation->{reset}{name} // '';
}

sub _positive_width {
    my ($width) = @_;
    $width = 1 unless defined($width) && "$width" =~ /\A[0-9]+\z/ && $width > 0;
    return int($width);
}

sub _vhdl_string {
    my ($value) = @_;

    $value = '' unless defined $value;
    $value =~ s/"/""/g;
    return '"' . $value . '"';
}

sub _write_text_file {
    my ($path, $text) = @_;

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} $text;
    close $fh;
}

1;
