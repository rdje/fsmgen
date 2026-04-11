package FSM::Composition::RTLInterfaceLoader;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Basename qw(dirname);
use File::Spec;
use FSM::ParameterValueSupport;
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
        my $embedded_rtlif_ast = $self->_with_rtl_child_context(
            source_file => $source_file,
            module_name => $module_name,
            code => sub {
                return $self->find_embedded_rtlif_root(
                    $embedded_raw_ast,
                    $module_name,
                    $source_file,
                );
            },
        );
        if ($embedded_rtlif_ast) {
            my $metadata_path = $self->embedded_metadata_label($source_file, $module_name);
            my $metadata = $self->_with_rtl_child_context(
                source_file => $source_file,
                module_name => $module_name,
                code => sub {
                    return $self->parse_metadata_ast($module_name, $embedded_rtlif_ast, $metadata_path);
                },
            );
            return {
                module_name => $module_name,
                metadata_path => $metadata_path,
                interface_ports => $metadata->{ports},
                parameter_declarations => $metadata->{parameter_declarations},
                raw_ast => $embedded_rtlif_ast,
            };
        }
    }

    my $metadata_path = $self->_with_rtl_child_context(
        source_file => $source_file,
        module_name => $module_name,
        context_kind => 'missing_external_metadata',
        code => sub {
            return $self->resolve_metadata_path($module_name, $source_file);
        },
    );
    my $raw_ast = $self->_with_rtl_child_context(
        source_file => $source_file,
        module_name => $module_name,
        metadata_path => $metadata_path,
        context_kind => 'external_metadata',
        code => sub {
            my $raw_ast = Lispish::multi($metadata_path)
                or confess "Failed to parse RTL interface metadata '$metadata_path' for module '$module_name'";
            return $raw_ast;
        },
    );
    my $metadata = $self->_with_rtl_child_context(
        source_file => $source_file,
        module_name => $module_name,
        metadata_path => $metadata_path,
        context_kind => 'external_metadata',
        code => sub {
            return $self->parse_metadata_ast($module_name, $raw_ast, $metadata_path);
        },
    );

    return {
        module_name => $module_name,
        metadata_path => $metadata_path,
        interface_ports => $metadata->{ports},
        parameter_declarations => $metadata->{parameter_declarations},
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
    my @parameter_declarations;
    my %parameters_by_name;
    for my $item (@$items) {
        if (ref($item)) {
            my $nested_header = ref($item) eq 'ARRAY' && @$item && !ref($item->[0])
                ? $item->[0]
                : undef;

            if (defined($nested_header) && $nested_header eq 'params') {
                confess
                    "Composition references external RTL module '$module_name', ".
                    "but RTL interface metadata parameter declaration uniqueness is blocked because declared interface metadata '$metadata_path' repeats '(params ...)' under '?rtlif:$module_name'. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    if @parameter_declarations;
                my $declarations = $self->parse_parameter_declarations_block($module_name, $item, $metadata_path);
                for my $declaration (@$declarations) {
                    confess
                        "Composition references external RTL module '$module_name', ".
                        "but RTL interface metadata parameter declaration uniqueness is blocked because declared interface metadata '$metadata_path' repeats parameter/generic '".$declaration->{name}."'. ".
                        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                        if $parameters_by_name{$declaration->{name}};
                    $parameters_by_name{$declaration->{name}} = 1;
                    push @parameter_declarations, $declaration;
                }
                next;
            }

            confess
                "Composition references external RTL module '$module_name', ".
                "but RTL interface metadata flatness is blocked because declared interface metadata '$metadata_path' contains nested structure under '?rtlif:$module_name'. ".
                "The active C3 lane accepts flat explicit port tokens plus one optional '(params (NAME value) ...)' declaration block, not arbitrary nested metadata. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

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
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata port presence is blocked because declared interface metadata '$metadata_path' declares no ports under '?rtlif:$module_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @ports;

    return {
        ports => \@ports,
        parameter_declarations => \@parameter_declarations,
    };
}

sub find_rtlif_root ($self, $raw_ast, $module_name) {
    my @matches = $self->find_rtlif_roots($raw_ast, $module_name);
    return $matches[0];
}

sub find_embedded_rtlif_root ($self, $raw_ast, $module_name, $source_file) {
    my @matches = $self->find_rtlif_roots($raw_ast, $module_name);
    confess
        "Composition source '$source_file' contains multiple embedded '?rtlif:$module_name' roots, ".
        "but RTL interface metadata embedded-root uniqueness is blocked because the active RTL interface contract allows at most one embedded interface root per external RTL module name in the same source. ".
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
        "but RTL interface metadata token shape is blocked because token '$token' in declared interface metadata '$metadata_path' is an invalid port token for the current '.rtlif' contract. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $port;
    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata port sizing is blocked because token '$token' in declared interface metadata '$metadata_path' declares non-positive port width '$size'. ".
        "The active '.rtlif' contract requires positive explicit widths when a width is declared. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if defined($size) && $size < 1;

    $resolved_type //= 'clock' if $port eq 'clk';
    $resolved_type //= 'reset' if $port eq 'rstn' || $port eq 'rst_n';
    $resolved_type //= 'data';

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata port typing is blocked because token '$token' in declared interface metadata '$metadata_path' resolves to unsupported port type '$resolved_type'. ".
        "The active '.rtlif' contract currently supports only 'data', 'clock', and 'reset' type annotations. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $resolved_type =~ /^(?:data|clock|reset)$/;

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata system-port direction is blocked because token '$token' in declared interface metadata '$metadata_path' resolves to '$resolved_type' while declaring an output direction. ".
        "The active '.rtlif' contract treats 'clock' and 'reset' ports as system inputs only. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if $resolved_type =~ /^(?:clock|reset)$/ && defined($direction) && $direction eq '>';

    return FSM::Composition::Port->new(
        name => $port,
        direction => defined($direction) ? ($direction eq '<' ? 'input' : 'output') : 'input',
        width => $size // 1,
        type => $resolved_type,
        raw_token => $token,
        origin_kind => 'rtlif_declared_port',
    );
}

sub parse_parameter_declarations_block ($self, $module_name, $params_block, $metadata_path) {
    my $entries = $params_block->[1] // [];

    confess
        "Composition references external RTL module '$module_name', ".
        "but RTL interface metadata parameter declaration shape is blocked because '(params ...)' in declared interface metadata '$metadata_path' must contain one or more '(NAME default_value)' scalar or aggregate declarations. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless ref($entries) eq 'ARRAY' && @$entries;

    my @declarations;
    for my $entry (@$entries) {
        confess
            "Composition references external RTL module '$module_name', ".
            "but RTL interface metadata parameter declaration shape is blocked because '(params ...)' entries in declared interface metadata '$metadata_path' must use '(NAME default_value)'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($name_ast, $value_ast) = @$entry;
        my $name = $self->_unwrap_scalar_token($name_ast);
        confess
            "Composition references external RTL module '$module_name', ".
            "but RTL interface metadata parameter declaration token shape is blocked because parameter/generic '".$self->_describe_contract_name($name)."' in declared interface metadata '$metadata_path' is not HDL-identifier-compatible. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $self->_is_contract_identifier($name);

        my $value_info = FSM::ParameterValueSupport->canonical_value(
            value_ast => $value_ast,
            context => "RTL interface metadata '$metadata_path' parameter/generic '$name'",
            docs_hint => " See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md",
        );

        my $raw_value = $self->_unwrap_scalar_token($value_ast);
        my $declaration = {
            name => $name,
            default_value_text => $value_info->{value_text},
            default_value_kind => $value_info->{value_kind},
            default_value_payload => $value_info->{value_payload},
            origin_kind => 'rtlif_parameter_declaration',
        };
        $declaration->{raw_default_value} = $raw_value if defined($raw_value) && !ref($raw_value);
        $declaration->{raw_default_value_ast} = $value_ast if ref($raw_value);
        $declaration->{default_value_width} = $value_info->{value_width} if defined $value_info->{value_width};
        $declaration->{default_value_type_spec} = $value_info->{value_type_spec} if ref($value_info->{value_type_spec}) eq 'HASH';

        push @declarations, $declaration;
    }

    return \@declarations;
}

sub _unwrap_scalar_token ($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub _is_contract_identifier ($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub _describe_contract_name ($self, $value) {
    return defined($value) && !ref($value) ? $value : 'unknown';
}

sub _with_rtl_child_context ($self, %args) {
    my $source_file = $args{source_file}
        or confess "RTLInterfaceLoader requires a source_file";
    my $module_name = $args{module_name}
        or confess "RTLInterfaceLoader requires a module_name";
    my $code_ref = $args{code}
        or confess "RTLInterfaceLoader requires a code callback";

    my @result = eval { $code_ref->() };
    if (!$@) {
        return wantarray ? @result : $result[0];
    }

    my $error = $@;
    die $error if ref($error);
    die $error if $error =~ /(?:^|\n)(?:Source file|RTL metadata file|Expected RTL metadata file):\s+'/s;

    my ($clean_error, $search_roots) = $self->_extract_search_roots($error);
    $error = $clean_error;

    my $message = '';
    if (($args{context_kind} // '') eq 'external_metadata') {
        my $metadata_path = $args{metadata_path}
            or confess "RTLInterfaceLoader external metadata context requires a metadata_path";
        $message .= "RTL metadata file: '$metadata_path'\n";
        $message .= "Parent composition source: '$source_file'\n";
    }
    elsif (($args{context_kind} // '') eq 'missing_external_metadata') {
        $message .= "Source file: '$source_file'\n";
        $message .= "Expected RTL metadata file: '" . $args{module_name} . ".rtlif'\n";
        if (defined($search_roots) && length($search_roots)) {
            $message .= "Search roots: $search_roots\n";
        }
    }
    else {
        $message .= "Source file: '$source_file'\n";
    }
    $message .= "RTL child module: '?rtl' '$module_name'\n";

    die $message.$error;
}

sub _extract_search_roots ($self, $error) {
    my $search_roots;
    my $clean_error = $error;

    if ($clean_error =~ s/\s+Search roots:\s*(.+?)\.\s+(?=(?:The active|See docs\/|\z))/ /s) {
        $search_roots = $1;
    }

    return ($clean_error, $search_roots);
}

1;
