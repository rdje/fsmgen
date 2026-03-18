package FSM::Composition::RTLInterfaceLoader;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Basename qw(dirname);
use File::Spec;
use FSM::Composition::Port;
use FSM::SourcePathResolver;
use Lispish;

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
        path_resolver => $args{path_resolver}
            // FSM::SourcePathResolver->new(
                extra_search_paths => ($args{extra_search_paths} || []),
            ),
    }, $class;
}

sub load_interface ($self, %args) {
    my $module_name = $args{module_name}
        or confess "RTLInterfaceLoader requires 'module_name'";
    my $source_file = $args{source_file}
        or confess "RTLInterfaceLoader requires 'source_file'";
    my $embedded_raw_ast = $args{embedded_raw_ast};

    if (defined $embedded_raw_ast) {
        my $embedded_rtlif_ast = $self->find_embedded_rtlif_root(
            $embedded_raw_ast,
            $module_name,
            $source_file,
        );
        if ($embedded_rtlif_ast) {
            my $metadata_path = $self->embedded_metadata_label($source_file, $module_name);
            my $ports = $self->parse_metadata_ast($module_name, $embedded_rtlif_ast, $metadata_path);
            return {
                module_name => $module_name,
                metadata_path => $metadata_path,
                interface_ports => $ports,
                raw_ast => $embedded_rtlif_ast,
            };
        }
    }

    my $metadata_path = $self->resolve_metadata_path($module_name, $source_file);
    my $raw_ast = Lispish::multi($metadata_path)
        or confess "Failed to parse RTL interface metadata '$metadata_path' for module '$module_name'";
    my $ports = $self->parse_metadata_ast($module_name, $raw_ast, $metadata_path);

    return {
        module_name => $module_name,
        metadata_path => $metadata_path,
        interface_ports => $ports,
        raw_ast => $raw_ast,
    };
}

sub resolve_metadata_path ($self, $module_name, $source_file) {
    my @preferred_dirs = ();
    push @preferred_dirs, dirname($source_file) if $source_file =~ m{/};
    my @search_dirs = @{
        $self->{path_resolver}->normalized_search_paths(
            preferred_dirs => \@preferred_dirs,
            include_cwd => 1,
        )
    };

    my @candidates = map { File::Spec->catfile($_, "$module_name.rtlif") } @search_dirs;
    for my $candidate (@candidates) {
        return $candidate if -f $candidate;
    }

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata resolution is blocked because no declared interface metadata file '$module_name.rtlif' was found. ".
        "Search roots: ".join(', ', @search_dirs).". ".
        "The active C3 lane requires external RTL interface metadata to be prepared separately and loaded for composition use. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub embedded_metadata_label ($self, $source_file, $module_name) {
    return "$source_file:?rtlif:$module_name";
}

sub parse_metadata_ast ($self, $module_name, $raw_ast, $metadata_path) {
    my $rtlif_ast = $self->find_rtlif_root($raw_ast, $module_name);
    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata structure is blocked because declared interface metadata '$metadata_path' does not contain a '?rtlif:$module_name' root. ".
        "The active C3 lane requires one flat '?rtlif:$module_name' root per external RTL child interface. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $rtlif_ast;

    my ($header, $items) = @$rtlif_ast;
    my ($declared_name) = ($header // '') =~ /^\?rtlif:(\w+)/;
    confess
        "RTL interface metadata '$metadata_path' declares '$header', ".
        "but the active C3 lane expected '?rtlif:$module_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless defined $declared_name && $declared_name eq $module_name;

    $items ||= [];
    confess
        "RTL interface metadata '$metadata_path' must contain a flat item list under '?rtlif:$module_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless ref($items) eq 'ARRAY';

    my @ports;
    my %ports_by_name;
    for my $item (@$items) {
        confess
            "RTL interface metadata '$metadata_path' contains nested structure under '?rtlif:$module_name', ".
            "but the active C3 lane only accepts flat explicit port tokens. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if ref($item);

        my $port = $self->parse_port_token($module_name, $item, $metadata_path);
        confess
            "Composition references external RTL module '$module_name', ".
            "but RTL interface metadata port declaration uniqueness is blocked because declared interface metadata '$metadata_path' repeats port '".$port->name."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $ports_by_name{$port->name};

        $ports_by_name{$port->name} = $port;
        push @ports, $port;
    }

    confess
        "RTL interface metadata '$metadata_path' declares no ports under '?rtlif:$module_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @ports;

    return \@ports;
}

sub find_rtlif_root ($self, $raw_ast, $module_name) {
    my @matches = $self->find_rtlif_roots($raw_ast, $module_name);
    return $matches[0];
}

sub find_embedded_rtlif_root ($self, $raw_ast, $module_name, $source_file) {
    my @matches = $self->find_rtlif_roots($raw_ast, $module_name);
    confess
        "Composition source '$source_file' contains multiple embedded '?rtlif:$module_name' roots. ".
        "The active RTL interface contract allows at most one embedded interface root per external RTL module name in the same source. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if @matches > 1;
    return $matches[0];
}

sub find_rtlif_roots ($self, $raw_ast, $module_name) {
    return undef unless ref($raw_ast) eq 'ARRAY';
    my @matches;

    if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] eq "?rtlif:$module_name") {
        push @matches, $raw_ast;
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        push @matches, $ast_node if $ast_node->[0] eq "?rtlif:$module_name";
    }

    return @matches;
}

sub parse_port_token ($self, $module_name, $token, $metadata_path) {
    $token =~ /^(?<port>\w+)(?:(?<direction>[<>])(?<size>\d+)?)?(?:[:](?<type>\w+))?$/o;
    my ($port, $direction, $size, $type) = @+{qw/port direction size type/};
    my $resolved_type = $type;

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata token shape is blocked because token '$token' is an invalid port token for the current '.rtlif' contract. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $port;
    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata port sizing is blocked because token '$token' declares non-positive port width '$size'. ".
        "The active '.rtlif' contract requires positive explicit widths when a width is declared. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if defined($size) && $size < 1;

    $resolved_type //= 'clock' if $port eq 'clk';
    $resolved_type //= 'reset' if $port eq 'rstn' || $port eq 'rst_n';
    $resolved_type //= 'data';

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata port typing is blocked because token '$token' resolves to unsupported port type '$resolved_type'. ".
        "The active '.rtlif' contract currently supports only 'data', 'clock', and 'reset' type annotations. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $resolved_type =~ /^(?:data|clock|reset)$/;

    return FSM::Composition::Port->new(
        name => $port,
        direction => defined($direction) ? ($direction eq '<' ? 'input' : 'output') : 'input',
        width => $size // 1,
        type => $resolved_type,
        raw_token => $token,
        origin_kind => 'rtlif_declared_port',
    );
}

1;
