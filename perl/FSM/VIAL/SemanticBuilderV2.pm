package FSM::VIAL::SemanticBuilderV2;

use strict;
use warnings;

use Math::BigInt;
use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyRegistry qw(
    negotiate_vial_semantic_family_requirements
    vial_semantic_family_negotiation_message
);
use FSM::VIAL::LifecycleControl qw(
    build_vial_lifecycle_semantic_family
);

use constant {
    MAX_FAMILY_BLOCKS_PER_PACKAGE => 256,
    MAX_FAMILY_NODES_PER_BLOCK    => 4_096,
    MAX_FAMILY_NODES_PER_CATALOG  => 65_536,
    MAX_FAMILY_REVISIONS_PER_CATALOG => 256,
};

my @SECTIONS = qw(imports types transactions models scoreboards intents fixtures);
my @CAPABILITIES = qw(
    vial.profile.core_directed_single_clock_v2
    vial.semantic_ir.v2
    vial.source.v2
);

sub build {
    my ($class, $args) = @_;
    _invocation_error($args) unless ref($args) eq 'HASH' && !blessed($args);
    my %expected = map { $_ => 1 } qw(root_source_name forms sources);
    my @unknown = sort grep { !$expected{$_} } keys %{$args};
    _invocation_error($args, "unknown builder key '$unknown[0]'") if @unknown;
    for my $key (keys %expected) {
        _invocation_error($args, "missing builder key '$key'") unless exists $args->{$key};
    }
    _invocation_error($args, "builder key 'root_source_name' must be a scalar")
        if !defined($args->{root_source_name}) || ref($args->{root_source_name});
    _invocation_error($args, "builder key 'forms' must be an unblessed hash")
        unless ref($args->{forms}) eq 'HASH' && !blessed($args->{forms});
    _invocation_error($args, "builder key 'sources' must be an unblessed array")
        unless ref($args->{sources}) eq 'ARRAY' && !blessed($args->{sources});

    my (%family_revision, @family_requirements, @intent_spans,
        @package_family_blocks);
    my $family_nodes_total = 0;
    my $expanded_lifecycle_nodes_total = 0;
    my %v1_forms;
    for my $package_index (0 .. $#{$args->{sources}}) {
        my $source = $args->{sources}[$package_index];
        my $source_name = ref($source) eq 'HASH' ? $source->{source_name} : undef;
        _invocation_error($args, "source record $package_index has no scalar source_name")
            if !defined($source_name) || ref($source_name);
        my $root = $args->{forms}{$source_name};
        _fail(
            'VIAL_PARSE_ERROR', 'parse', 'source form is missing',
            _zero_location($source_name), '/',
        ) unless $root;

        my $root_items = _form($root, 'vial', 3, 3, '/');
        my $version_items = _form($root_items->[1], 'version', 2, 2, '/language_version');
        my $version = _positive_integer($version_items->[1], '/language_version');
        _fail(
            'VIAL_VERSION_UNSUPPORTED', 'parse',
            "VIAL language version '$version' is not supported by the version-2 builder",
            $version_items->[1]{span}, '/language_version',
        ) unless $version eq '2';

        my $package_path = "/packages/$package_index";
        my $package_node = $root_items->[2];
        my $package_items = _form($package_node, 'package', 9, 9, $package_path);
        _identifier($package_items->[1], "$package_path/name");
        my %section;
        for my $offset (0 .. $#SECTIONS) {
            my $name = $SECTIONS[$offset];
            my $node = $package_items->[$offset + 2];
            my $items = _form($node, $name, 1, undef, "$package_path/$name");
            $section{$name} = { node => $node, items => [@{$items}[1 .. $#{$items}]] };
        }
        push @intent_spans, _clone($section{intents}{node}{span});

        for my $index (0 .. $#{$section{imports}{items}}) {
            my $path = "$package_path/imports/$index";
            my $items = _form($section{imports}{items}[$index], 'import', 3, undef, $path);
            _fail(
                'VIAL_LIMIT_ERROR', 'limit',
                'import edge exceeds the one-compatibility-adapter limit',
                $section{imports}{items}[$index]{span}, "$path/adapter",
            ) if @{$items} > 4;
            _identifier($items->[1], "$path/alias");
            _string($items->[2], "$path/source_name");
            next unless @{$items} == 4;
            my $adapter = _form($items->[3], 'adapter', 2, 2, "$path/adapter");
            my $adapter_id = _identifier($adapter->[1], "$path/adapter/id");
            _fail(
                'VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE', 'import',
                "compatibility adapter '$adapter_id' is not registered",
                $adapter->[1]{span}, "$path/adapter",
            );
        }

        my $blocks = $section{intents}{items};
        $package_family_blocks[$package_index] = [];
        _fail(
            'VIAL_LIMIT_ERROR', 'limit',
            'package exceeds the 256 intent-family-block limit',
            $section{intents}{node}{span}, "$package_path/intent_families",
        ) if @{$blocks} > MAX_FAMILY_BLOCKS_PER_PACKAGE;

        my %package_family;
        for my $index (0 .. $#{$blocks}) {
            my $path = "$package_path/intent_families/$index";
            my $items = _form($blocks->[$index], 'family', 3, undef, $path);
            my $family_id = _identifier($items->[1], "$path/family_id");
            _fail(
                'VIAL_PARSE_ERROR', 'parse',
                "duplicate intent family '$family_id' in one package",
                $items->[1]{span}, "$path/family_id",
                [{
                    message => 'first family block',
                    source_location => _clone($package_family{$family_id}),
                }],
            ) if $package_family{$family_id};
            $package_family{$family_id} = _clone($items->[1]{span});

            my $revision_items = _form($items->[2], 'revision', 2, 2, "$path/revision");
            my $revision = _positive_integer($revision_items->[1], "$path/revision");
            if (exists($family_revision{$family_id})
                && $family_revision{$family_id}{revision} ne $revision) {
                _fail(
                    'VIAL_FAMILY_REVISION_MISMATCH', 'resolve',
                    "intent family '$family_id' uses revision $revision after revision $family_revision{$family_id}{revision}",
                    $revision_items->[1]{span}, "$path/revision",
                    [{
                        message => 'first family revision',
                        source_location => _clone($family_revision{$family_id}{span}),
                    }],
                );
            }
            $family_revision{$family_id} ||= {
                revision => $revision,
                span => _clone($revision_items->[1]{span}),
            };
            _fail(
                'VIAL_LIMIT_ERROR', 'limit',
                'intent families across the catalog exceed the 256-family-revision limit',
                $revision_items->[1]{span}, "$path/revision",
            ) if scalar(keys %family_revision) > MAX_FAMILY_REVISIONS_PER_CATALOG;

            my $node_count = @{$items} - 3;
            _fail(
                'VIAL_LIMIT_ERROR', 'limit',
                "intent family '$family_id' exceeds the 4096-node limit",
                $blocks->[$index]{span}, "$path/nodes",
            ) if $node_count > MAX_FAMILY_NODES_PER_BLOCK;
            $family_nodes_total += $node_count;
            _fail(
                'VIAL_LIMIT_ERROR', 'limit',
                'intent families across the catalog exceed the 65536-node limit',
                $blocks->[$index]{span}, "$path/nodes",
            ) if $family_nodes_total > MAX_FAMILY_NODES_PER_CATALOG;
            push @family_requirements, {
                family_id => $family_id,
                revision => 0 + $revision,
                location => _clone($items->[1]{span}),
                path => $path,
            };
            push @{$package_family_blocks[$package_index]}, {
                form => $blocks->[$index],
                family_id => $family_id,
                revision => 0 + $revision,
                family_index => $index,
            };
        }

        my $v1_root = _clone($root);
        $v1_root->{items}[1]{items}[1]{value} = '1';
        $v1_root->{items}[1]{items}[1]{raw} = '1';
        $v1_root->{items}[2]{items} = [
            map { _clone($_) } @{$package_items}[0 .. 6],
            _clone($package_items->[8]),
        ];
        $v1_forms{$source_name} = $v1_root;
    }

    if (@family_requirements) {
        my $negotiation = negotiate_vial_semantic_family_requirements({
            stage => 'parser',
            profile_id => 'vial_parser_v2',
            source_language_version => 2,
            execution_schema => undef,
            execution_profile => undef,
            requirements => [map {{
                family_id => $_->{family_id},
                revision => $_->{revision},
                required_capabilities => [],
                effect_kinds => [],
            }} @family_requirements],
        });
        my $first = $family_requirements[0];
        my $revision_mismatch = grep {
            $_->{kind} eq 'family_revision'
        } @{$negotiation->{issues}};
        _fail(
            $revision_mismatch
                ? 'VIAL_FAMILY_REVISION_MISMATCH'
                : 'VIAL_FAMILY_UNSUPPORTED',
            'semantic',
            vial_semantic_family_negotiation_message($negotiation),
            $first->{location},
            "$first->{path}/" . ($revision_mismatch ? 'revision' : 'family_id'),
            [map {{
                message => "required intent family '$_->{family_id}\@$_->{revision}'",
                source_location => _clone($_->{location}),
            }} @family_requirements[1 .. $#family_requirements]],
        ) unless $negotiation->{accepted};
    }

    require FSM::VIAL::SemanticBuilder;
    my $v1_ir;
    my $ok = eval {
        $v1_ir = FSM::VIAL::SemanticBuilder->build({
            root_source_name => $args->{root_source_name},
            forms => \%v1_forms,
            sources => _clone($args->{sources}),
        });
        1;
    };
    die _upgrade_exception($@, $args->{root_source_name}) unless $ok;

    my $data = $v1_ir->as_hashref;
    $data->{schema} = 'fsmgen.vial_semantic_ir.v2';
    $data->{schema_version} = 2;
    $data->{language_version} = 2;
    $data->{profile} = 'core_directed_single_clock_v2';
    my %required_capability = map { $_ => 1 } @CAPABILITIES;
    for my $package_index (0 .. $#{$data->{packages}}) {
        my @families;
        for my $block (@{$package_family_blocks[$package_index]}) {
            my $family = build_vial_lifecycle_semantic_family({
                form => $block->{form},
                package => $data->{packages}[$package_index],
                package_index => $package_index,
                family_index => $block->{family_index},
                expanded_nodes_before => $expanded_lifecycle_nodes_total,
            });
            $expanded_lifecycle_nodes_total += @{$family->{nodes}};
            push @families, $family;
            $required_capability{'vial.family.lifecycle_control.v1'} = 1;
            $required_capability{'vial.family.lifecycle_control.deadline.v1'} = 1;
            $required_capability{'vial.semantic_family_envelope.v2'} = 1;
            $data->{provenance}{$family->{semantic_path}}
                = _clone($family->{source_span});
            for my $node (@{$family->{nodes}}) {
                $data->{provenance}{$node->{semantic_path}}
                    = _clone($node->{source_span});
            }
        }
        $data->{packages}[$package_index]{intent_families} = \@families;
        $data->{provenance}{"/packages/$package_index/intent_families"}
            = _clone($intent_spans[$package_index]);
    }
    $data->{required_capabilities} = [sort keys %required_capability];

    require FSM::VIAL::SemanticIR;
    return FSM::VIAL::SemanticIR->_new_validated($data);
}

sub _form {
    my ($node, $expected_head, $min, $max, $path) = @_;
    _fail('VIAL_PARSE_ERROR', 'parse', 'expected a list form', _location($node), $path)
        unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'list';
    my $items = $node->{items};
    _fail('VIAL_PARSE_ERROR', 'parse', 'empty list form is not allowed', $node->{span}, $path)
        unless @{$items};
    if (@{$items} < $min || (defined($max) && @{$items} > $max)) {
        my $expected = defined($max) && $min == $max
            ? "$min items" : "at least $min items";
        _fail(
            'VIAL_PARSE_ERROR', 'parse',
            "$expected_head form requires $expected",
            $node->{span}, $path,
        );
    }
    my $actual = _atom($items->[0]);
    _fail(
        'VIAL_PARSE_ERROR', 'parse',
        "expected '$expected_head' form, found '$actual'",
        _location($items->[0]), $path,
    ) unless $actual eq $expected_head;
    return $items;
}

sub _identifier {
    my ($node, $path) = @_;
    my $value = _atom($node);
    _fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected an unqualified identifier',
        _location($node), $path,
    ) unless ($node->{atom_kind} || '') eq 'identifier' && $value !~ /\./;
    return $value;
}

sub _string {
    my ($node, $path) = @_;
    _fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected a string literal',
        _location($node), $path,
    ) unless ($node->{atom_kind} || '') eq 'string';
    _fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        'string must be non-empty and single-line', _location($node), $path,
    ) if $node->{value} eq '' || $node->{value} =~ /[\r\n]/;
    return $node->{value};
}

sub _positive_integer {
    my ($node, $path) = @_;
    _fail(
        'VIAL_TYPE_ERROR', 'type', 'expected a literal positive integer',
        _location($node), $path,
    ) unless ($node->{atom_kind} || '') eq 'integer';
    my $raw = $node->{value};
    my $value = $raw =~ /\A0[bB]/
        ? Math::BigInt->from_bin($raw)
        : $raw =~ /\A0[xX]/
            ? Math::BigInt->from_hex($raw)
            : Math::BigInt->new($raw);
    _fail(
        'VIAL_TYPE_ERROR', 'type', 'expected a literal positive integer',
        _location($node), $path,
    ) if $value->is_nan || !$value->is_pos;
    return $value->bstr;
}

sub _atom {
    my ($node) = @_;
    return '' unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'atom';
    return defined($node->{value}) ? $node->{value} : '';
}

sub _upgrade_exception {
    my ($exception, $source_name) = @_;
    if (blessed($exception) && $exception->isa('FSM::VIAL::DiagnosticBundle')) {
        return bless({
            diagnostics => [map { _upgrade_diagnostic($_) } @{$exception->{diagnostics}}],
        }, 'FSM::VIAL::DiagnosticBundle');
    }
    return bless(_upgrade_diagnostic($exception), 'FSM::VIAL::Diagnostic')
        if blessed($exception) && $exception->isa('FSM::VIAL::Diagnostic');
    return bless({
        schema => 'fsmgen.vial_diagnostic.v2',
        schema_version => 2,
        severity => 'error',
        code => 'VIAL_SEMANTIC_ERROR',
        phase => 'semantic',
        message => 'internal semantic validation failed closed',
        semantic_path => '/',
        source_location => _zero_location($source_name),
        notes => [],
    }, 'FSM::VIAL::Diagnostic');
}

sub _upgrade_diagnostic {
    my ($diagnostic) = @_;
    my $upgraded = _clone($diagnostic);
    $upgraded->{schema} = 'fsmgen.vial_diagnostic.v2';
    $upgraded->{schema_version} = 2;
    return $upgraded;
}

sub _invocation_error {
    my ($args, $message) = @_;
    my $source_name = ref($args) eq 'HASH'
        && defined($args->{root_source_name}) && !ref($args->{root_source_name})
            ? $args->{root_source_name} : 'vial/input.vial';
    _fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        $message || 'builder invocation must be one unblessed hash',
        _zero_location($source_name), '/',
    );
}

sub _fail {
    my ($code, $phase, $message, $location, $path, $notes) = @_;
    $message =~ s/[\r\n]+/ /g;
    die bless({
        schema => 'fsmgen.vial_diagnostic.v2',
        schema_version => 2,
        severity => 'error',
        code => $code,
        phase => $phase,
        message => $message,
        semantic_path => defined($path) ? $path : '/',
        source_location => _clone($location),
        notes => _clone($notes || []),
    }, 'FSM::VIAL::Diagnostic');
}

sub _location {
    my ($node) = @_;
    return _clone($node->{span})
        if ref($node) eq 'HASH' && ref($node->{span}) eq 'HASH';
    return _zero_location('vial/input.vial');
}

sub _zero_location {
    my ($source_name) = @_;
    return {
        source_name => $source_name,
        start_byte => 0,
        end_byte_exclusive => 0,
        start_line => 1,
        start_column => 1,
        end_line => 1,
        end_column => 1,
    };
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    my $type = ref($value) ? (reftype($value) || '') : '';
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} }
        if $type eq 'HASH';
    return [map { _clone($_) } @{$value}] if $type eq 'ARRAY';
    return $value;
}

1;
