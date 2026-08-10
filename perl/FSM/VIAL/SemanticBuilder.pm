package FSM::VIAL::SemanticBuilder;

use strict;
use warnings;

use Math::BigInt;
use Scalar::Util qw(blessed);

use constant {
    MAX_DECLARATIONS       => 4_096,
    MAX_FIXTURES           => 1_024,
    MAX_SCENARIO_ACTIONS   => 65_536,
    MAX_PARALLEL_DEPTH     => 16,
    MAX_PARALLEL_FIBERS    => 256,
    MAX_SCALAR_WIDTH       => 65_536,
    MAX_LIST_LENGTH        => 65_536,
    MAX_RECORD_FIELDS      => 256,
    MAX_AGGREGATE_DEPTH    => 32,
    MAX_SCOREBOARD_CAPACITY => 1_000_000,
    MAX_CROSS_BINS         => 1_000_000,
    MAX_CYCLES             => 2_147_483_647,
    MAX_REPEAT             => 1_000_000,
};

my @CAPABILITIES = qw(
    vial.profile.core_directed_single_clock_v1
    vial.semantic_ir.v1
    vial.source.v1
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

    my $self = bless({
        root_source_name => $args->{root_source_name},
        forms => $args->{forms},
        sources => _clone($args->{sources}),
        provenance => {},
        package_contexts => [],
        package_by_source => {},
        package_by_id => {},
        diagnostics => [],
    }, $class);

    $self->_declare_packages;
    $self->_link_imports;
    $self->_build_declarations;
    $self->_build_fixtures;
    $self->_throw_collected_diagnostics if @{$self->{diagnostics}};

    my ($root_source) = grep {
        $_->{source_name} eq $self->{root_source_name}
    } @{$self->{sources}};
    _fail(
        'VIAL_SEMANTIC_ERROR', 'semantic', 'root source identity is missing',
        _zero_location($self->{root_source_name}), '/',
    ) unless $root_source;

    my $data = {
        schema_version => 1,
        language => 'vial',
        language_version => 1,
        profile => 'core_directed_single_clock_v1',
        root_source => _clone($root_source),
        sources => _clone($self->{sources}),
        packages => [map { _clone($_->{record}) } @{$self->{package_contexts}}],
        required_capabilities => [@CAPABILITIES],
        provenance => _clone($self->{provenance}),
    };

    require FSM::VIAL::SemanticIR;
    return FSM::VIAL::SemanticIR->_new_validated($data);
}

sub _declare_packages {
    my ($self) = @_;
    my %package_names;

    for my $package_index (0 .. $#{$self->{sources}}) {
        my $source = $self->{sources}[$package_index];
        my $source_name = $source->{source_name};
        my $root = $self->{forms}{$source_name};
        _fail('VIAL_PARSE_ERROR', 'parse', 'source form is missing', _zero_location($source_name), '/')
            unless $root;

        my $root_items = _form($root, 'vial', 3, 3, '/');
        my $version_items = _form($root_items->[1], 'version', 2, 2, '/language_version');
        my $version = _positive_integer($version_items->[1], '/language_version', 1, 1);
        _fail(
            'VIAL_PARSE_ERROR', 'parse', 'only VIAL language version 1 is accepted',
            $version_items->[1]{span}, '/language_version',
        ) unless $version == 1;

        my $package_node = $root_items->[2];
        my $package_items = _form($package_node, 'package', 8, 8, "/packages/$package_index");
        my $package_name = _identifier($package_items->[1], "/packages/$package_index/name", 0);
        if ($package_names{$package_name}) {
            _fail(
                'VIAL_REFERENCE_ERROR', 'resolve', "duplicate package name '$package_name'",
                $package_items->[1]{span}, "/packages/$package_index/name",
                [_note('first package declaration', $package_names{$package_name})],
            );
        }
        $package_names{$package_name} = $package_items->[1]{span};

        my @section_names = qw(imports types transactions models scoreboards fixtures);
        my %sections;
        for my $offset (0 .. $#section_names) {
            my $node = $package_items->[$offset + 2];
            my $items = _form($node, $section_names[$offset], 1, undef, "/packages/$package_index/$section_names[$offset]");
            $sections{$section_names[$offset]} = { node => $node, items => [@{$items}[1 .. $#{$items}]] };
        }
        for my $section (qw(types transactions models scoreboards)) {
            if (@{$sections{$section}{items}} > MAX_DECLARATIONS) {
                _fail(
                    'VIAL_LIMIT_ERROR', 'limit',
                    "package section '$section' exceeds 4096 declarations",
                    $sections{$section}{node}{span}, "/packages/$package_index/$section",
                );
            }
        }
        if (@{$sections{fixtures}{items}} > MAX_FIXTURES) {
            _fail(
                'VIAL_LIMIT_ERROR', 'limit', 'package exceeds 1024 fixtures',
                $sections{fixtures}{node}{span}, "/packages/$package_index/fixtures",
            );
        }
        if (!@{$sections{fixtures}{items}}) {
            _fail(
                'VIAL_PARSE_ERROR', 'parse', 'package must declare at least one fixture',
                $sections{fixtures}{node}{span}, "/packages/$package_index/fixtures",
            );
        }

        my $package_path = "/packages/$package_index";
        my $package_id = "$package_name\::package\::$package_name";
        my $record = {
            %{$self->_meta($package_path, $package_node)},
            semantic_id => $package_id,
            name => $package_name,
            source_name => $source_name,
            imports => [],
            types => [],
            transactions => [],
            models => [],
            scoreboards => [],
            fixtures => [],
        };
        my $context = {
            index => $package_index,
            source_name => $source_name,
            name => $package_name,
            semantic_id => $package_id,
            record => $record,
            sections => \%sections,
            imports => {},
            declarations => {
                types => {}, transactions => {}, models => {}, scoreboards => {}, fixtures => {},
            },
        };
        push @{$self->{package_contexts}}, $context;
        $self->{package_by_source}{$source_name} = $context;
        $self->{package_by_id}{$package_id} = $context;
        $self->_declare_stubs($context);
    }
}

sub _declare_stubs {
    my ($self, $context) = @_;
    my %head_for = (
        types => { type => 1, enum => 1 },
        transactions => { transaction => 1 },
        models => { model => 1 },
        scoreboards => { scoreboard => 1 },
        fixtures => { fixture => 1 },
    );
    my %kind_for = (
        types => 'type', transactions => 'transaction', models => 'model',
        scoreboards => 'scoreboard', fixtures => 'fixture',
    );

    for my $section (qw(types transactions models scoreboards fixtures)) {
        my $items = $context->{sections}{$section}{items};
        for my $index (0 .. $#{$items}) {
            my $node = $items->[$index];
            my $path = "/packages/$context->{index}/$section/$index";
            my $form_items = _form($node, undef, 2, undef, $path);
            my $head = _atom($form_items->[0]);
            if (!$head_for{$section}{$head}) {
                _fail(
                    'VIAL_PARSE_ERROR', 'parse', "unknown '$head' form in $section section",
                    $form_items->[0]{span}, $path,
                );
            }
            my $name = _identifier($form_items->[1], "$path/name", 0);
            my $prior = $context->{declarations}{$section}{$name};
            if ($prior) {
                _fail(
                    'VIAL_REFERENCE_ERROR', 'resolve', "duplicate $kind_for{$section} declaration '$name'",
                    $form_items->[1]{span}, "$path/name",
                    [_note('first declaration', $prior->{name_node}{span})],
                );
            }
            my $kind = $kind_for{$section};
            $context->{declarations}{$section}{$name} = {
                head => $head,
                name => $name,
                name_node => $form_items->[1],
                node => $node,
                items => $form_items,
                index => $index,
                path => $path,
                semantic_id => "$context->{name}\::$kind\::$name",
                status => 'declared',
            };
        }
    }
}

sub _link_imports {
    my ($self) = @_;
    for my $context (@{$self->{package_contexts}}) {
        my %aliases;
        my %sources;
        my $items = $context->{sections}{imports}{items};
        for my $index (0 .. $#{$items}) {
            my $path = "/packages/$context->{index}/imports/$index";
            my $form_items = _form($items->[$index], 'import', 3, 3, $path);
            my $alias = _identifier($form_items->[1], "$path/alias", 0);
            my $source_name = _string($form_items->[2], "$path/source_name", 1);
            if ($alias eq $context->{name}) {
                _fail(
                    'VIAL_IMPORT_ERROR', 'import', "import alias '$alias' conflicts with the package name",
                    $form_items->[1]{span}, "$path/alias",
                );
            }
            if ($aliases{$alias}) {
                _fail(
                    'VIAL_IMPORT_ERROR', 'import', "duplicate import alias '$alias'",
                    $form_items->[1]{span}, "$path/alias",
                    [_note('first import alias', $aliases{$alias})],
                );
            }
            if ($sources{$source_name}) {
                _fail(
                    'VIAL_IMPORT_ERROR', 'import', "duplicate imported source '$source_name'",
                    $form_items->[2]{span}, "$path/source_name",
                    [_note('first source import', $sources{$source_name})],
                );
            }
            my $target = $self->{package_by_source}{$source_name};
            _fail(
                'VIAL_IMPORT_ERROR', 'import', "imported source '$source_name' was not parsed",
                $form_items->[2]{span}, "$path/source_name",
            ) unless $target;
            $aliases{$alias} = $form_items->[1]{span};
            $sources{$source_name} = $form_items->[2]{span};
            my $record = {
                %{$self->_meta($path, $items->[$index])},
                alias => $alias,
                source_name => $source_name,
                package_id => $target->{semantic_id},
            };
            push @{$context->{record}{imports}}, $record;
            $context->{imports}{$alias} = $target;
        }
    }
}

sub _build_declarations {
    my ($self) = @_;
    for my $context (@{$self->{package_contexts}}) {
        for my $stub (_ordered_stubs($context, 'types')) {
            $self->_capture_container($stub, sub {
                $self->_build_type_declaration($context, $stub);
            });
        }
    }
    for my $context (@{$self->{package_contexts}}) {
        for my $stub (_ordered_stubs($context, 'transactions')) {
            $self->_capture_container($stub, sub {
                $self->_build_transaction($context, $stub);
            });
        }
        for my $stub (_ordered_stubs($context, 'models')) {
            $self->_capture_container($stub, sub {
                $self->_build_model($context, $stub);
            });
        }
        for my $stub (_ordered_stubs($context, 'scoreboards')) {
            $self->_capture_container($stub, sub {
                $self->_build_scoreboard($context, $stub);
            });
        }
    }
}

sub _build_type_declaration {
    my ($self, $context, $stub) = @_;
    return $stub->{record} if $stub->{status} eq 'built';
    _dependent_failure() if $stub->{status} eq 'failed';
    if ($stub->{status} eq 'building') {
        _fail(
            'VIAL_TYPE_ERROR', 'type', "recursive type alias '$stub->{name}'",
            $stub->{name_node}{span}, $stub->{path},
        );
    }
    $stub->{status} = 'building';

    my $record;
    if ($stub->{head} eq 'type') {
        my $items = _form($stub->{node}, 'type', 3, 3, $stub->{path});
        my $type = $self->_type_expr($context, $items->[2], "$stub->{path}/type", 0);
        $record = {
            %{$self->_meta($stub->{path}, $stub->{node})},
            semantic_id => $stub->{semantic_id},
            name => $stub->{name},
            declaration_kind => 'alias',
            type => $type,
        };
    }
    else {
        my $items = _form($stub->{node}, 'enum', 4, undef, $stub->{path});
        my $base = $self->_type_expr($context, $items->[2], "$stub->{path}/base", 0);
        my $resolved_base = $self->_resolved_type($base);
        _fail(
            'VIAL_TYPE_ERROR', 'type', 'enum base must be a scalar type',
            $items->[2]{span}, "$stub->{path}/base",
        ) unless $resolved_base->{kind} eq 'scalar';
        my %members;
        my @members;
        for my $index (3 .. $#{$items}) {
            my $path = "$stub->{path}/members/" . ($index - 3);
            my $member_items = _form($items->[$index], undef, 2, 2, $path);
            my $name = _identifier($member_items->[0], "$path/name", 0);
            if ($members{$name}) {
                _fail(
                    'VIAL_REFERENCE_ERROR', 'resolve', "duplicate enum member '$name'",
                    $member_items->[0]{span}, "$path/name",
                    [_note('first enum member', $members{$name})],
                );
            }
            $members{$name} = $member_items->[0]{span};
            push @members, {
                %{$self->_meta($path, $items->[$index])},
                semantic_id => "$stub->{semantic_id}\::member\::$name",
                name => $name,
                value => $self->_literal($context, $member_items->[1], $base, "$path/value", {}),
            };
        }
        $record = {
            %{$self->_meta($stub->{path}, $stub->{node})},
            semantic_id => $stub->{semantic_id},
            name => $stub->{name},
            declaration_kind => 'enum',
            type => {
                kind => 'enum',
                semantic_id => $stub->{semantic_id},
                base_type => _clone($base),
                members => \@members,
            },
        };
    }
    $stub->{record} = $record;
    $stub->{status} = 'built';
    push @{$context->{record}{types}}, $record;
    return $record;
}

sub _type_expr {
    my ($self, $context, $node, $path, $aggregate_depth) = @_;
    if (($node->{node_kind} || '') eq 'atom') {
        my $name = _atom($node);
        return _scalar_type('bool', 1) if $name eq 'bool';
        _fail('VIAL_TYPE_ERROR', 'type', "unknown scalar type '$name'", $node->{span}, $path);
    }

    my $items = _form($node, undef, 2, undef, $path);
    my $head = _atom($items->[0]);
    if ($head eq 'u' || $head eq 's' || $head eq 'logic' || $head eq 'slogic') {
        _shape($items, 2, 2, $node, $path, $head);
        my $width = _positive_integer($items->[1], "$path/width", 1, MAX_SCALAR_WIDTH);
        return _scalar_type($head, $width);
    }
    if ($head eq 'type') {
        _shape($items, 2, 2, $node, $path, $head);
        my $spelling = _identifier($items->[1], "$path/reference", 1);
        my ($target_context, $stub) = $self->_resolve_stub($context, 'types', $spelling, $items->[1], $path);
        my $target = $self->_build_type_declaration($target_context, $stub);
        return {
            kind => 'reference',
            authored_name => $spelling,
            semantic_id => $target->{semantic_id},
            resolved => _clone($target->{type}),
        };
    }
    if ($head eq 'record') {
        _fail(
            'VIAL_LIMIT_ERROR', 'limit', 'aggregate nesting exceeds 32 levels',
            $node->{span}, $path,
        ) if $aggregate_depth >= MAX_AGGREGATE_DEPTH;
        my @field_nodes = @{$items}[1 .. $#{$items}];
        _fail('VIAL_TYPE_ERROR', 'type', 'record must contain at least one field', $node->{span}, $path)
            unless @field_nodes;
        _fail('VIAL_LIMIT_ERROR', 'limit', 'record exceeds 256 fields', $node->{span}, $path)
            if @field_nodes > MAX_RECORD_FIELDS;
        my %names;
        my @fields;
        for my $index (0 .. $#field_nodes) {
            my $field_path = "$path/fields/$index";
            my $field_items = _form($field_nodes[$index], undef, 2, 2, $field_path);
            my $name = _identifier($field_items->[0], "$field_path/name", 0);
            if ($names{$name}) {
                _fail(
                    'VIAL_REFERENCE_ERROR', 'resolve', "duplicate record field '$name'",
                    $field_items->[0]{span}, "$field_path/name",
                    [_note('first field', $names{$name})],
                );
            }
            $names{$name} = $field_items->[0]{span};
            push @fields, {
                name => $name,
                type => $self->_type_expr($context, $field_items->[1], "$field_path/type", $aggregate_depth + 1),
            };
        }
        return { kind => 'record', fields => \@fields };
    }
    if ($head eq 'list') {
        _shape($items, 3, 3, $node, $path, $head);
        _fail(
            'VIAL_LIMIT_ERROR', 'limit', 'aggregate nesting exceeds 32 levels',
            $node->{span}, $path,
        ) if $aggregate_depth >= MAX_AGGREGATE_DEPTH;
        my $length = _positive_integer($items->[1], "$path/length", 1, MAX_LIST_LENGTH);
        return {
            kind => 'list',
            length => $length,
            element_type => $self->_type_expr($context, $items->[2], "$path/element_type", $aggregate_depth + 1),
        };
    }
    _fail('VIAL_TYPE_ERROR', 'type', "unknown type form '$head'", $items->[0]{span}, $path);
}

sub _build_transaction {
    my ($self, $context, $stub) = @_;
    return $stub->{record} if $stub->{status} eq 'built';
    _dependent_failure() if $stub->{status} eq 'failed';
    my $items = _form($stub->{node}, 'transaction', 4, 4, $stub->{path});
    my $fields_items = _form($items->[2], 'fields', 2, undef, "$stub->{path}/fields");
    my $events_items = _form($items->[3], 'events', 2, undef, "$stub->{path}/events");
    my (%field_names, %event_names);
    my (@fields, @events);
    for my $index (1 .. $#{$fields_items}) {
        my $path = "$stub->{path}/fields/" . ($index - 1);
        my $field_items = _form($fields_items->[$index], undef, 2, 2, $path);
        my $name = _identifier($field_items->[0], "$path/name", 0);
        _unique_name(\%field_names, $name, $field_items->[0], $path, 'transaction field');
        push @fields, {
            %{$self->_meta($path, $fields_items->[$index])},
            semantic_id => "$stub->{semantic_id}\::field\::$name",
            name => $name,
            type => $self->_type_expr($context, $field_items->[1], "$path/type", 0),
        };
    }
    for my $index (1 .. $#{$events_items}) {
        my $path = "$stub->{path}/events/" . ($index - 1);
        my $name = _identifier($events_items->[$index], "$path/name", 0);
        _unique_name(\%event_names, $name, $events_items->[$index], $path, 'transaction event');
        push @events, {
            %{$self->_meta($path, $events_items->[$index])},
            semantic_id => "$stub->{semantic_id}\::event\::$name",
            name => $name,
        };
    }
    my $record = {
        %{$self->_meta($stub->{path}, $stub->{node})},
        semantic_id => $stub->{semantic_id}, name => $stub->{name},
        fields => \@fields, events => \@events,
    };
    $stub->{record} = $record;
    $stub->{status} = 'built';
    push @{$context->{record}{transactions}}, $record;
    return $record;
}

sub _build_model {
    my ($self, $context, $stub) = @_;
    return $stub->{record} if $stub->{status} eq 'built';
    _dependent_failure() if $stub->{status} eq 'failed';
    my $items = _form($stub->{node}, 'model', 5, 5, $stub->{path});
    my $inputs_items = _form($items->[2], 'inputs', 2, undef, "$stub->{path}/inputs");
    my $state_items = _form($items->[3], 'state', 2, undef, "$stub->{path}/state");
    my $rules_items = _form($items->[4], 'rules', 2, undef, "$stub->{path}/rules");

    my (%input_names, %state_names, @inputs, @state);
    for my $index (1 .. $#{$inputs_items}) {
        my $path = "$stub->{path}/inputs/" . ($index - 1);
        my $input_items = _form($inputs_items->[$index], undef, 2, 2, $path);
        my $name = _identifier($input_items->[0], "$path/name", 0);
        _unique_name(\%input_names, $name, $input_items->[0], $path, 'model input');
        my $type = _atom($input_items->[1]) eq 'event'
            ? { kind => 'event' }
            : $self->_type_expr($context, $input_items->[1], "$path/type", 0);
        my $record = {
            %{$self->_meta($path, $inputs_items->[$index])},
            semantic_id => "$stub->{semantic_id}\::input\::$name",
            name => $name, type => $type,
        };
        push @inputs, $record;
        $input_names{$name} = $record;
    }
    for my $index (1 .. $#{$state_items}) {
        my $path = "$stub->{path}/state/" . ($index - 1);
        my $decl_items = _form($state_items->[$index], undef, 3, 3, $path);
        my $name = _identifier($decl_items->[0], "$path/name", 0);
        _unique_name(\%state_names, $name, $decl_items->[0], $path, 'model state');
        my $type = $self->_type_expr($context, $decl_items->[1], "$path/type", 0);
        my $resolved = $self->_resolved_type($type);
        _fail(
            'VIAL_PROFILE_UNSUPPORTED', 'profile', 'aggregate model state is not implemented by core_directed_single_clock_v1',
            $decl_items->[1]{span}, "$path/type",
        ) unless $resolved->{kind} eq 'scalar' || $resolved->{kind} eq 'enum';
        my $record = {
            %{$self->_meta($path, $state_items->[$index])},
            semantic_id => "$stub->{semantic_id}\::state\::$name",
            name => $name, type => $type,
            initial_value => $self->_literal($context, $decl_items->[2], $type, "$path/initial_value", {}),
        };
        push @state, $record;
        $state_names{$name} = $record;
    }

    my %rule_inputs;
    my @rules;
    my %symbols = (%input_names, %state_names);
    my @expected_rule_inputs = map { $_->{name} } grep { $_->{type}{kind} eq 'event' } @inputs;
    for my $index (1 .. $#{$rules_items}) {
        my $path = "$stub->{path}/rules/" . ($index - 1);
        my $rule_items = _form($rules_items->[$index], 'on', 3, undef, $path);
        my $input_name = _identifier($rule_items->[1], "$path/input", 0);
        my $input = $input_names{$input_name};
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown model input '$input_name'", $rule_items->[1]{span}, "$path/input")
            unless $input;
        _fail('VIAL_TYPE_ERROR', 'type', "model rule input '$input_name' is not an event", $rule_items->[1]{span}, "$path/input")
            unless $input->{type}{kind} eq 'event';
        _unique_name(\%rule_inputs, $input_name, $rule_items->[1], $path, 'model rule');
        my $expected_input = $expected_rule_inputs[$index - 1];
        _fail(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            "model rules must follow event-input declaration order; expected '$expected_input'",
            $rule_items->[1]{span}, "$path/input",
        ) if !defined($expected_input) || $expected_input ne $input_name;
        my (%assigned, @assignments);
        for my $assignment_index (2 .. $#{$rule_items}) {
            my $assignment_path = "$path/assignments/" . ($assignment_index - 2);
            my $set_items = _form($rule_items->[$assignment_index], 'set', 3, 3, $assignment_path);
            my $state_name = _identifier($set_items->[1], "$assignment_path/state", 0);
            my $state_decl = $state_names{$state_name};
            _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown model state '$state_name'", $set_items->[1]{span}, "$assignment_path/state")
                unless $state_decl;
            _unique_name(\%assigned, $state_name, $set_items->[1], $assignment_path, 'model assignment target');
            push @assignments, {
                %{$self->_meta($assignment_path, $rule_items->[$assignment_index])},
                state_id => $state_decl->{semantic_id},
                expression => $self->_expr($context, $set_items->[2], $state_decl->{type}, "$assignment_path/expression", { symbols => \%symbols }),
            };
        }
        push @rules, {
            %{$self->_meta($path, $rules_items->[$index])},
            input_id => $input->{semantic_id}, assignments => \@assignments,
        };
    }
    my @event_inputs = grep { $_->{type}{kind} eq 'event' } @inputs;
    for my $input (@event_inputs) {
        _fail(
            'VIAL_SEMANTIC_ERROR', 'semantic', "event model input '$input->{name}' has no rule",
            $input->{source_span}, $input->{semantic_path},
        ) unless $rule_inputs{$input->{name}};
    }

    my $record = {
        %{$self->_meta($stub->{path}, $stub->{node})},
        semantic_id => $stub->{semantic_id}, name => $stub->{name},
        inputs => \@inputs, state => \@state, rules => \@rules,
    };
    $stub->{record} = $record;
    $stub->{status} = 'built';
    push @{$context->{record}{models}}, $record;
    return $record;
}

sub _build_scoreboard {
    my ($self, $context, $stub) = @_;
    return $stub->{record} if $stub->{status} eq 'built';
    _dependent_failure() if $stub->{status} eq 'failed';
    my $items = _form($stub->{node}, 'scoreboard', 5, 6, $stub->{path});
    my $transaction_items = _form($items->[2], 'transaction', 2, 2, "$stub->{path}/transaction");
    my $policy_items = _form($items->[3], 'policy', 2, 2, "$stub->{path}/policy");
    my $transaction_spelling = _identifier($transaction_items->[1], "$stub->{path}/transaction", 1);
    my ($target_context, $transaction_stub) = $self->_resolve_stub($context, 'transactions', $transaction_spelling, $transaction_items->[1], "$stub->{path}/transaction");
    my $transaction = $self->_build_transaction($target_context, $transaction_stub);
    my $policy = _identifier($policy_items->[1], "$stub->{path}/policy", 0);
    _fail('VIAL_SEMANTIC_ERROR', 'semantic', "unknown scoreboard policy '$policy'", $policy_items->[1]{span}, "$stub->{path}/policy")
        unless $policy eq 'in_order' || $policy eq 'keyed';

    my ($key, $capacity_node);
    if ($policy eq 'keyed') {
        _shape($items, 6, 6, $stub->{node}, $stub->{path}, 'scoreboard');
        my $key_items = _form($items->[4], 'key', 2, 2, "$stub->{path}/key");
        $key = _identifier($key_items->[1], "$stub->{path}/key", 0);
        my $field = _find_named($transaction->{fields}, $key);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown scoreboard key field '$key'", $key_items->[1]{span}, "$stub->{path}/key")
            unless $field;
        my $resolved = $self->_resolved_type($field->{type});
        _fail('VIAL_TYPE_ERROR', 'type', 'scoreboard key field must be scalar', $key_items->[1]{span}, "$stub->{path}/key")
            unless $resolved->{kind} eq 'scalar' || $resolved->{kind} eq 'enum';
        $capacity_node = $items->[5];
    }
    else {
        _shape($items, 5, 5, $stub->{node}, $stub->{path}, 'scoreboard');
        $capacity_node = $items->[4];
    }
    my $capacity_items = _form($capacity_node, 'capacity', 2, 2, "$stub->{path}/capacity");
    my $capacity = _positive_integer($capacity_items->[1], "$stub->{path}/capacity", 1, MAX_SCOREBOARD_CAPACITY);
    my $record = {
        %{$self->_meta($stub->{path}, $stub->{node})},
        semantic_id => $stub->{semantic_id}, name => $stub->{name},
        transaction_id => $transaction->{semantic_id}, policy => $policy,
        key => $key, capacity => $capacity,
    };
    $stub->{record} = $record;
    $stub->{status} = 'built';
    push @{$context->{record}{scoreboards}}, $record;
    return $record;
}

sub _build_fixtures {
    my ($self) = @_;
    for my $context (@{$self->{package_contexts}}) {
        for my $stub (_ordered_stubs($context, 'fixtures')) {
            $self->_capture_container($stub, sub {
                my $items = _form($stub->{node}, 'fixture', 8, 8, $stub->{path});
                my $fixture = {
                    %{$self->_meta($stub->{path}, $stub->{node})},
                    semantic_id => $stub->{semantic_id}, name => $stub->{name},
                };
                $fixture->{dut} = $self->_build_dut($context, $fixture, $items->[2], "$stub->{path}/dut");
                $fixture->{instances} = $self->_build_instances($context, $fixture, $items->[3], "$stub->{path}/instances");
                $fixture->{coverage} = $self->_build_coverage($context, $fixture, $items->[4], "$stub->{path}/coverage");
                $fixture->{faults} = $self->_build_faults($context, $fixture, $items->[5], "$stub->{path}/faults");
                $fixture->{randomness} = $self->_build_randomness($context, $fixture, $items->[6], "$stub->{path}/randomness");
                $fixture->{scenarios} = $self->_build_scenarios($context, $fixture, $items->[7], "$stub->{path}/scenarios");
                $self->_scrub_fixture_build_links($fixture);
                $stub->{record} = $fixture;
                $stub->{status} = 'built';
                push @{$context->{record}{fixtures}}, $fixture;
            });
        }
    }
}

sub _capture_container {
    my ($self, $stub, $builder) = @_;
    my $ok = eval {
        $builder->();
        1;
    };
    return 1 if $ok;

    my $exception = $@;
    if (blessed($exception) && $exception->isa('FSM::VIAL::DependentDiagnostic')) {
        $stub->{status} = 'failed';
        return 0;
    }
    die $exception unless blessed($exception) && $exception->isa('FSM::VIAL::Diagnostic');

    push @{$self->{diagnostics}}, _clone($exception);
    $stub->{status} = 'failed';
    for my $context (@{$self->{package_contexts}}) {
        for my $section (qw(types transactions models scoreboards fixtures)) {
            for my $candidate (values %{$context->{declarations}{$section}}) {
                $candidate->{status} = 'failed' if $candidate->{status} eq 'building';
            }
        }
    }
    return 0;
}

sub _throw_collected_diagnostics {
    my ($self) = @_;
    my %source_order = map {
        $self->{sources}[$_]{source_name} => $_
    } 0 .. $#{$self->{sources}};
    my @ordered = sort {
        ($source_order{$a->{source_location}{source_name}} // 0)
            <=> ($source_order{$b->{source_location}{source_name}} // 0)
        || $a->{source_location}{start_byte} <=> $b->{source_location}{start_byte}
        || $a->{semantic_path} cmp $b->{semantic_path}
    } @{$self->{diagnostics}};
    die bless({ diagnostics => _clone(\@ordered) }, 'FSM::VIAL::DiagnosticBundle');
}

sub _dependent_failure {
    die bless({}, 'FSM::VIAL::DependentDiagnostic');
}

sub _build_dut {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'dut', 6, 6, $path);
    my $name = _identifier($items->[1], "$path/name", 0);
    my $unit_items = _form($items->[2], 'unit', 2, 2, "$path/unit");
    my $unit_ref = _string($unit_items->[1], "$path/unit", 1);
    my $domains_items = _form($items->[3], 'domains', 2, undef, "$path/domains");
    my $endpoints_items = _form($items->[4], 'endpoints', 2, undef, "$path/endpoints");
    my $transactions_items = _form($items->[5], 'transactions', 1, undef, "$path/transactions");

    my (%domain_names, %domain_refs, @domains);
    for my $index (1 .. $#{$domains_items}) {
        my $item_path = "$path/domains/" . ($index - 1);
        my $domain_items = _form($domains_items->[$index], 'domain', 3, 3, $item_path);
        my $alias = _identifier($domain_items->[1], "$item_path/name", 0);
        my $bridge_ref = _string($domain_items->[2], "$item_path/bridge_ref", 1);
        _unique_name(\%domain_names, $alias, $domain_items->[1], $item_path, 'domain alias');
        _unique_scalar(\%domain_refs, $bridge_ref, $domain_items->[2], $item_path, 'domain bridge reference');
        push @domains, {
            %{$self->_meta($item_path, $domains_items->[$index])},
            semantic_id => "$fixture->{semantic_id}\::domain\::$alias",
            name => $alias, bridge_ref => $bridge_ref,
        };
    }
    if (@domains != 1) {
        _fail(
            'VIAL_PROFILE_UNSUPPORTED', 'profile',
            'core_directed_single_clock_v1 requires exactly one fixture domain',
            $items->[3]{span}, "$path/domains",
        );
    }

    my (%endpoint_names, %endpoint_refs, @endpoints);
    for my $index (1 .. $#{$endpoints_items}) {
        my $item_path = "$path/endpoints/" . ($index - 1);
        my $endpoint_items = _form($endpoints_items->[$index], 'endpoint', 5, 5, $item_path);
        my $alias = _identifier($endpoint_items->[1], "$item_path/name", 0);
        my $bridge_ref = _string($endpoint_items->[2], "$item_path/bridge_ref", 1);
        my $type = $self->_type_expr($context, $endpoint_items->[3], "$item_path/type", 0);
        my $access = _identifier($endpoint_items->[4], "$item_path/access", 0);
        if ($access eq 'native_hierarchy') {
            _fail('VIAL_PROFILE_UNSUPPORTED', 'profile', 'native_hierarchy access is deferred', $endpoint_items->[4]{span}, "$item_path/access");
        }
        _fail('VIAL_SEMANTIC_ERROR', 'semantic', "unknown endpoint access '$access'", $endpoint_items->[4]{span}, "$item_path/access")
            unless $access eq 'public_port' || $access eq 'verification_probe';
        _unique_name(\%endpoint_names, $alias, $endpoint_items->[1], $item_path, 'endpoint alias');
        _unique_scalar(\%endpoint_refs, $bridge_ref, $endpoint_items->[2], $item_path, 'endpoint bridge reference');
        push @endpoints, {
            %{$self->_meta($item_path, $endpoints_items->[$index])},
            semantic_id => "$fixture->{semantic_id}\::endpoint\::$alias",
            name => $alias, bridge_ref => $bridge_ref, type => $type, access => $access,
        };
    }
    _fail('VIAL_PROFILE_UNSUPPORTED', 'profile', 'fixture requires at least one public endpoint', $items->[4]{span}, "$path/endpoints")
        unless grep { $_->{access} eq 'public_port' } @endpoints;

    my (%transaction_names, %transaction_refs, @bindings);
    for my $index (1 .. $#{$transactions_items}) {
        my $item_path = "$path/transaction_bindings/" . ($index - 1);
        my $binding_items = _form($transactions_items->[$index], 'transaction', 4, 4, $item_path);
        my $alias = _identifier($binding_items->[1], "$item_path/name", 0);
        my $bridge_ref = _string($binding_items->[2], "$item_path/bridge_ref", 1);
        my $spelling = _identifier($binding_items->[3], "$item_path/transaction", 1);
        my ($target_context, $target_stub) = $self->_resolve_stub($context, 'transactions', $spelling, $binding_items->[3], "$item_path/transaction");
        my $transaction = $self->_build_transaction($target_context, $target_stub);
        _unique_name(\%transaction_names, $alias, $binding_items->[1], $item_path, 'transaction binding alias');
        _unique_scalar(\%transaction_refs, $bridge_ref, $binding_items->[2], $item_path, 'transaction bridge reference');
        push @bindings, {
            %{$self->_meta($item_path, $transactions_items->[$index])},
            semantic_id => "$fixture->{semantic_id}\::transaction_binding\::$alias",
            name => $alias, bridge_ref => $bridge_ref,
            authored_transaction => $spelling,
            transaction_id => $transaction->{semantic_id},
            transaction => $transaction,
        };
    }

    return {
        %{$self->_meta($path, $node)},
        semantic_id => "$fixture->{semantic_id}\::dut\::$name",
        name => $name, unit_bridge_ref => $unit_ref,
        domains => \@domains, endpoints => \@endpoints,
        transaction_bindings => \@bindings,
    };
}

sub _build_instances {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'instances', 1, undef, $path);
    my (%names, @models, @scoreboards);
    for my $index (1 .. $#{$items}) {
        my $item_path = "$path/" . ($index - 1);
        my $form_items = _form($items->[$index], undef, 3, undef, $item_path);
        my $head = _atom($form_items->[0]);
        my $name = _identifier($form_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $form_items->[1], $item_path, 'fixture instance');
        if ($head eq 'model') {
            my $spelling = _identifier($form_items->[2], "$item_path/model", 1);
            my ($target_context, $target_stub) = $self->_resolve_stub($context, 'models', $spelling, $form_items->[2], "$item_path/model");
            my $model = $self->_build_model($target_context, $target_stub);
            my %bindings;
            my @bindings;
            for my $binding_index (3 .. $#{$form_items}) {
                my $binding_path = "$item_path/bindings/" . ($binding_index - 3);
                my $bind_items = _form($form_items->[$binding_index], 'bind', 3, 3, $binding_path);
                my $input_name = _identifier($bind_items->[1], "$binding_path/input", 0);
                my $input = _find_named($model->{inputs}, $input_name);
                _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown model input '$input_name'", $bind_items->[1]{span}, "$binding_path/input")
                    unless $input;
                _unique_name(\%bindings, $input_name, $bind_items->[1], $binding_path, 'model input binding');
                my $value = $input->{type}{kind} eq 'event'
                    ? $self->_event_reference($fixture, $bind_items->[2], $binding_path, {})
                    : $self->_expr($context, $bind_items->[2], $input->{type}, "$binding_path/value", $self->_fixture_expr_env($fixture));
                push @bindings, {
                    %{$self->_meta($binding_path, $form_items->[$binding_index])},
                    input_id => $input->{semantic_id}, value => $value,
                };
            }
            for my $input (@{$model->{inputs}}) {
                _fail('VIAL_REFERENCE_ERROR', 'resolve', "model input '$input->{name}' is not bound", $items->[$index]{span}, $item_path)
                    unless $bindings{$input->{name}};
            }
            push @models, {
                %{$self->_meta($item_path, $items->[$index])},
                semantic_id => "$fixture->{semantic_id}\::model_instance\::$name",
                name => $name, model_id => $model->{semantic_id}, model => $model,
                bindings => \@bindings,
            };
        }
        elsif ($head eq 'scoreboard') {
            _shape($form_items, 4, 4, $items->[$index], $item_path, 'scoreboard');
            my $spelling = _identifier($form_items->[2], "$item_path/scoreboard", 1);
            my ($target_context, $target_stub) = $self->_resolve_stub($context, 'scoreboards', $spelling, $form_items->[2], "$item_path/scoreboard");
            my $scoreboard = $self->_build_scoreboard($target_context, $target_stub);
            my $actual_items = _form($form_items->[3], 'actual', 2, 2, "$item_path/actual");
            my $actual_name = _identifier($actual_items->[1], "$item_path/actual", 0);
            my $actual = _find_named($fixture->{dut}{transaction_bindings}, $actual_name);
            _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction binding '$actual_name'", $actual_items->[1]{span}, "$item_path/actual")
                unless $actual;
            _fail('VIAL_TYPE_ERROR', 'type', 'scoreboard actual transaction type does not match its declaration', $actual_items->[1]{span}, "$item_path/actual")
                unless $actual->{transaction_id} eq $scoreboard->{transaction_id};
            push @scoreboards, {
                %{$self->_meta($item_path, $items->[$index])},
                semantic_id => "$fixture->{semantic_id}\::scoreboard_instance\::$name",
                name => $name, scoreboard_id => $scoreboard->{semantic_id},
                transaction_id => $actual->{transaction_id},
                scoreboard => $scoreboard, actual_id => $actual->{semantic_id},
            };
        }
        else {
            _fail('VIAL_PARSE_ERROR', 'parse', "unknown instance form '$head'", $form_items->[0]{span}, $item_path);
        }
    }
    return { model_instances => \@models, scoreboard_instances => \@scoreboards };
}

sub _build_coverage {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'coverage', 1, undef, $path);
    my (%names, @coverpoints, @cross_nodes);
    for my $index (1 .. $#{$items}) {
        my $item_path = "$path/" . ($index - 1);
        my $head = _form_head($items->[$index], $item_path);
        if ($head eq 'cross') {
            push @cross_nodes, [$items->[$index], $item_path];
            next;
        }
        my $point_items = _form($items->[$index], 'coverpoint', 5, 5, $item_path);
        my $name = _identifier($point_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $point_items->[1], $item_path, 'coverage item');
        my $sample_items = _form($point_items->[2], 'sample', 2, 2, "$item_path/domain");
        my $domain_name = _identifier($sample_items->[1], "$item_path/domain", 0);
        my $domain = _find_named($fixture->{dut}{domains}, $domain_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown domain '$domain_name'", $sample_items->[1]{span}, "$item_path/domain") unless $domain;
        my $expr_items = _form($point_items->[3], 'expr', 2, 2, "$item_path/expression");
        my $expr = $self->_expr($context, $expr_items->[1], undef, "$item_path/expression", $self->_fixture_expr_env($fixture));
        my $resolved_expr_type = $self->_resolved_type($expr->{result_type});
        _fail('VIAL_TYPE_ERROR', 'type', 'coverpoint expression must be scalar', $expr_items->[1]{span}, "$item_path/expression")
            unless $resolved_expr_type->{kind} eq 'scalar' || $resolved_expr_type->{kind} eq 'enum';
        my $bins_items = _form($point_items->[4], 'bins', 2, undef, "$item_path/bins");
        my (%bin_names, @bins);
        for my $bin_index (1 .. $#{$bins_items}) {
            my $bin_path = "$item_path/bins/" . ($bin_index - 1);
            my $bin_items = _form($bins_items->[$bin_index], 'bin', 4, 4, $bin_path);
            my $bin_name = _identifier($bin_items->[1], "$bin_path/name", 0);
            _unique_name(\%bin_names, $bin_name, $bin_items->[1], $bin_path, 'coverage bin');
            my $classification = _identifier($bin_items->[2], "$bin_path/classification", 0);
            _fail('VIAL_SEMANTIC_ERROR', 'semantic', "unknown coverage bin class '$classification'", $bin_items->[2]{span}, "$bin_path/classification")
                unless $classification eq 'normal' || $classification eq 'illegal' || $classification eq 'ignore';
            my $matcher_items = _form($bin_items->[3], undef, 2, 3, "$bin_path/matcher");
            my $matcher_kind = _atom($matcher_items->[0]);
            my $matcher;
            if ($matcher_kind eq 'value') {
                _shape($matcher_items, 2, 2, $bin_items->[3], "$bin_path/matcher", $matcher_kind);
                $matcher = { kind => 'value', value => $self->_literal($context, $matcher_items->[1], $expr->{result_type}, "$bin_path/matcher/value", {}) };
            }
            elsif ($matcher_kind eq 'range') {
                _shape($matcher_items, 3, 3, $bin_items->[3], "$bin_path/matcher", $matcher_kind);
                my $resolved = $self->_resolved_type($expr->{result_type});
                _fail('VIAL_TYPE_ERROR', 'type', 'coverage range requires a two-state scalar expression', $bin_items->[3]{span}, "$bin_path/matcher")
                    unless $resolved->{kind} eq 'scalar' && !$resolved->{four_state};
                my $low = $self->_literal($context, $matcher_items->[1], $expr->{result_type}, "$bin_path/matcher/low", {});
                my $high = $self->_literal($context, $matcher_items->[2], $expr->{result_type}, "$bin_path/matcher/high", {});
                _fail('VIAL_SEMANTIC_ERROR', 'semantic', 'coverage range low exceeds high', $bin_items->[3]{span}, "$bin_path/matcher")
                    if _value_bigint($low)->bcmp(_value_bigint($high)) > 0;
                $matcher = { kind => 'range', low => $low, high => $high };
            }
            else {
                _fail('VIAL_PARSE_ERROR', 'parse', "unknown coverage matcher '$matcher_kind'", $matcher_items->[0]{span}, "$bin_path/matcher");
            }
            push @bins, {
                %{$self->_meta($bin_path, $bins_items->[$bin_index])},
                semantic_id => "$fixture->{semantic_id}\::coverpoint\::$name\::bin\::$bin_name",
                name => $bin_name, classification => $classification, matcher => $matcher,
            };
        }
        push @coverpoints, {
            %{$self->_meta($item_path, $items->[$index])},
            semantic_id => "$fixture->{semantic_id}\::coverpoint\::$name",
            name => $name, domain_id => $domain->{semantic_id}, expression => $expr, bins => \@bins,
        };
    }

    my @crosses;
    for my $pair (@cross_nodes) {
        my ($cross_node, $item_path) = @{$pair};
        my $cross_items = _form($cross_node, 'cross', 4, 4, $item_path);
        my $name = _identifier($cross_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $cross_items->[1], $item_path, 'coverage item');
        my $points_items = _form($cross_items->[2], 'points', 3, undef, "$item_path/points");
        my (%point_names, @point_ids);
        my $product = Math::BigInt->new(1);
        my $domain_id;
        for my $point_index (1 .. $#{$points_items}) {
            my $point_name = _identifier($points_items->[$point_index], "$item_path/points/" . ($point_index - 1), 0);
            _unique_name(\%point_names, $point_name, $points_items->[$point_index], $item_path, 'cross point');
            my $point = _find_named(\@coverpoints, $point_name);
            _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown coverpoint '$point_name'", $points_items->[$point_index]{span}, "$item_path/points") unless $point;
            _fail('VIAL_TYPE_ERROR', 'type', 'cross coverpoints must use one sample domain', $points_items->[$point_index]{span}, "$item_path/points")
                if defined($domain_id) && $domain_id ne $point->{domain_id};
            $domain_id = $point->{domain_id};
            push @point_ids, $point->{semantic_id};
            $product->bmul(scalar @{$point->{bins}});
        }
        my $max_items = _form($cross_items->[3], 'max_bins', 2, 2, "$item_path/max_bins");
        my $max_bins = _positive_integer($max_items->[1], "$item_path/max_bins", 1, MAX_CROSS_BINS);
        _fail('VIAL_LIMIT_ERROR', 'limit', 'coverage cross Cartesian product exceeds max_bins', $cross_node->{span}, $item_path)
            if $product->bcmp($max_bins) > 0;
        push @crosses, {
            %{$self->_meta($item_path, $cross_node)},
            semantic_id => "$fixture->{semantic_id}\::cross\::$name",
            name => $name, point_ids => \@point_ids, max_bins => $max_bins,
        };
    }
    return { coverpoints => \@coverpoints, crosses => \@crosses };
}

sub _build_faults {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'faults', 1, undef, $path);
    my (%names, @faults);
    for my $index (1 .. $#{$items}) {
        my $item_path = "$path/" . ($index - 1);
        my $fault_items = _form($items->[$index], 'fault', 5, 5, $item_path);
        my $name = _identifier($fault_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $fault_items->[1], $item_path, 'fault');
        my $target_items = _form($fault_items->[2], 'target', 2, 2, "$item_path/target");
        my $transaction_items = _form($target_items->[1], 'transaction', 3, 3, "$item_path/target");
        my $transaction_name = _identifier($transaction_items->[1], "$item_path/target/transaction", 0);
        my $field_name = _identifier($transaction_items->[2], "$item_path/target/field", 0);
        my $binding = _find_named($fixture->{dut}{transaction_bindings}, $transaction_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction binding '$transaction_name'", $transaction_items->[1]{span}, "$item_path/target") unless $binding;
        my $field = _find_named($binding->{transaction}{fields}, $field_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction field '$field_name'", $transaction_items->[2]{span}, "$item_path/target") unless $field;
        my $action_items = _form($fault_items->[3], 'action', 2, 2, "$item_path/action");
        my $substitute_items = _form($action_items->[1], 'substitute', 2, 2, "$item_path/action/substitute");
        my $substitute = $self->_expr($context, $substitute_items->[1], $field->{type}, "$item_path/action/substitute", $self->_fixture_expr_env($fixture));
        my $duration_items = _form($fault_items->[4], 'duration', 2, 2, "$item_path/duration");
        my $cycles_items = _form($duration_items->[1], 'cycles', 3, 3, "$item_path/duration");
        my $domain_name = _identifier($cycles_items->[1], "$item_path/duration/domain", 0);
        my $domain = _find_named($fixture->{dut}{domains}, $domain_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown domain '$domain_name'", $cycles_items->[1]{span}, "$item_path/duration/domain") unless $domain;
        my $duration = _positive_integer($cycles_items->[2], "$item_path/duration/cycles", 1, MAX_CYCLES);
        push @faults, {
            %{$self->_meta($item_path, $items->[$index])},
            semantic_id => "$fixture->{semantic_id}\::fault\::$name",
            name => $name, transaction_id => $binding->{transaction_id}, field_name => $field_name,
            substitute => $substitute, domain_id => $domain->{semantic_id}, duration_cycles => $duration,
        };
    }
    return \@faults;
}

sub _build_randomness {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'randomness', 2, undef, $path);
    my $seed_items = _form($items->[1], 'seed', 2, 2, "$path/seed");
    my $seed = _unsigned_integer_string($seed_items->[1], "$path/seed", Math::BigInt->new('18446744073709551615'));
    my (%names, %decision_ids, @choices);
    for my $index (2 .. $#{$items}) {
        my $item_path = "$path/choices/" . ($index - 2);
        my $choice_items = _form($items->[$index], 'choice', 6, 6, $item_path);
        my $name = _identifier($choice_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $choice_items->[1], $item_path, 'random choice');
        my $type = $self->_type_expr($context, $choice_items->[2], "$item_path/type", 0);
        my $resolved = $self->_resolved_type($type);
        _fail('VIAL_TYPE_ERROR', 'type', 'random choice type must be a two-state scalar', $choice_items->[2]{span}, "$item_path/type")
            unless $resolved->{kind} eq 'scalar' && !$resolved->{four_state};
        my $decision_items = _form($choice_items->[3], 'decision_id', 2, 2, "$item_path/decision_id");
        my $decision_id = _string($decision_items->[1], "$item_path/decision_id", 1);
        _unique_scalar(\%decision_ids, $decision_id, $decision_items->[1], $item_path, 'random decision ID');
        my $distribution_items = _form($choice_items->[4], 'distribution', 2, 2, "$item_path/distribution");
        my $uniform_items = _form($distribution_items->[1], 'uniform', 3, 3, "$item_path/distribution");
        my $low = $self->_literal($context, $uniform_items->[1], $type, "$item_path/distribution/low", {});
        my $high = $self->_literal($context, $uniform_items->[2], $type, "$item_path/distribution/high", {});
        _fail('VIAL_SEMANTIC_ERROR', 'semantic', 'random distribution low exceeds high', $uniform_items->[1]{span}, "$item_path/distribution")
            if _value_bigint($low)->bcmp(_value_bigint($high)) > 0;
        my $constraints_items = _form($choice_items->[5], 'constraints', 1, undef, "$item_path/constraints");
        my $choice_symbol = {
            name => $name,
            semantic_id => "$fixture->{semantic_id}\::choice\::$name",
            type => $type,
        };
        my @constraints;
        for my $constraint_index (1 .. $#{$constraints_items}) {
            push @constraints, $self->_property(
                $context, $constraints_items->[$constraint_index],
                "$item_path/constraints/" . ($constraint_index - 1),
                { %{$self->_fixture_expr_env($fixture)}, choices => { $name => $choice_symbol } },
            );
        }
        push @choices, {
            %{$self->_meta($item_path, $items->[$index])},
            semantic_id => $choice_symbol->{semantic_id}, name => $name, type => $type,
            decision_id => $decision_id,
            distribution => { kind => 'uniform', low => $low, high => $high },
            constraints => \@constraints,
        };
    }
    return { seed => $seed, choices => \@choices };
}

sub _build_scenarios {
    my ($self, $context, $fixture, $node, $path) = @_;
    my $items = _form($node, 'scenarios', 2, undef, $path);
    my (%names, @scenarios);
    for my $index (1 .. $#{$items}) {
        my $item_path = "$path/" . ($index - 1);
        my $scenario_items = _form($items->[$index], 'scenario', 4, 4, $item_path);
        my $name = _identifier($scenario_items->[1], "$item_path/name", 0);
        _unique_name(\%names, $name, $scenario_items->[1], $item_path, 'scenario');
        my $timeout_items = _form($scenario_items->[2], 'timeout', 2, 2, "$item_path/timeout");
        my $cycles_items = _form($timeout_items->[1], 'cycles', 3, 3, "$item_path/timeout");
        my $domain_name = _identifier($cycles_items->[1], "$item_path/timeout/domain", 0);
        my $domain = _find_named($fixture->{dut}{domains}, $domain_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown domain '$domain_name'", $cycles_items->[1]{span}, "$item_path/timeout/domain") unless $domain;
        my $timeout_cycles = _positive_integer($cycles_items->[2], "$item_path/timeout/cycles", 1, MAX_CYCLES);
        my $steps_items = _form($scenario_items->[3], 'steps', 2, undef, "$item_path/steps");
        my $scenario_id = "$fixture->{semantic_id}\::scenario\::$name";
        my $state = {
            handles => {}, expectations => {}, injected_faults => {},
            action_count => 0, fiber_count => 0, scenario_id => $scenario_id,
        };
        my @actions;
        for my $action_index (1 .. $#{$steps_items}) {
            push @actions, $self->_action(
                $context, $fixture, $steps_items->[$action_index],
                "$item_path/actions/" . ($action_index - 1), $state, 0,
            );
        }
        _fail('VIAL_LIMIT_ERROR', 'limit', 'scenario exceeds 65536 expanded actions', $items->[$index]{span}, $item_path)
            if $state->{action_count} > MAX_SCENARIO_ACTIONS;
        push @scenarios, {
            %{$self->_meta($item_path, $items->[$index])},
            semantic_id => $scenario_id,
            name => $name, domain_id => $domain->{semantic_id}, timeout_cycles => $timeout_cycles,
            actions => \@actions, action_count => $state->{action_count}, fiber_count => $state->{fiber_count},
        };
    }
    return \@scenarios;
}

sub _action {
    my ($self, $context, $fixture, $node, $path, $state, $parallel_depth) = @_;
    my $items = _form($node, undef, 1, undef, $path);
    my $head = _atom($items->[0]);
    ++$state->{action_count};
    my $meta = $self->_meta($path, $node);
    my $env = {
        %{$self->_fixture_expr_env($fixture)},
        choices => { map { $_->{name} => $_ } @{$fixture->{randomness}{choices}} },
        handles => $state->{handles},
    };

    if ($head eq 'reset') {
        _shape($items, 3, 3, $node, $path, $head);
        my $domain = $self->_domain_ref($fixture, $items->[1], "$path/domain");
        return { %{$meta}, kind => 'reset', domain_id => $domain->{semantic_id}, cycles => _positive_integer($items->[2], "$path/cycles", 1, MAX_CYCLES) };
    }
    if ($head eq 'drive') {
        _shape($items, 3, 3, $node, $path, $head);
        my $endpoint = $self->_endpoint_ref($fixture, $items->[1], "$path/endpoint");
        return { %{$meta}, kind => 'drive', endpoint_id => $endpoint->{semantic_id}, value => $self->_expr($context, $items->[2], $endpoint->{type}, "$path/value", $env) };
    }
    if ($head eq 'start') {
        _shape($items, 4, 4, $node, $path, $head);
        my $handle_name = _identifier($items->[1], "$path/handle", 0);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "duplicate transaction handle '$handle_name'", $items->[1]{span}, "$path/handle")
            if $state->{handles}{$handle_name};
        my $binding_name = _identifier($items->[2], "$path/transaction", 0);
        my $binding = _find_named($fixture->{dut}{transaction_bindings}, $binding_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction binding '$binding_name'", $items->[2]{span}, "$path/transaction") unless $binding;
        my $fields = $self->_transaction_field_values($context, $fixture, $binding->{transaction}, $items->[3], "$path/fields", $env);
        my $handle = {
            semantic_id => "$state->{scenario_id}\::handle\::$handle_name",
            name => $handle_name, transaction => $binding->{transaction}, transaction_id => $binding->{transaction_id},
        };
        $state->{handles}{$handle_name} = $handle;
        return { %{$meta}, kind => 'start', handle_id => $handle->{semantic_id}, transaction_binding_id => $binding->{semantic_id}, fields => $fields };
    }
    if ($head eq 'await') {
        _shape($items, 2, 2, $node, $path, $head);
        return { %{$meta}, kind => 'await', property => $self->_property($context, $items->[1], "$path/property", $env) };
    }
    if ($head eq 'parallel') {
        _shape($items, 4, undef, $node, $path, $head);
        _fail('VIAL_LIMIT_ERROR', 'limit', 'parallel nesting exceeds 16 levels', $node->{span}, $path)
            if $parallel_depth >= MAX_PARALLEL_DEPTH;
        my $join = _identifier($items->[1], "$path/join", 0);
        _fail('VIAL_SEMANTIC_ERROR', 'semantic', "unknown parallel join '$join'", $items->[1]{span}, "$path/join")
            unless $join eq 'all' || $join eq 'any';
        my @fiber_nodes = @{$items}[2 .. $#{$items}];
        _fail('VIAL_LIMIT_ERROR', 'limit', 'parallel exceeds 256 fibers', $node->{span}, $path)
            if @fiber_nodes > MAX_PARALLEL_FIBERS;
        my (%fiber_names, @fibers);
        $state->{fiber_count} += scalar @fiber_nodes;
        for my $fiber_index (0 .. $#fiber_nodes) {
            my $fiber_path = "$path/fibers/$fiber_index";
            my $fiber_items = _form($fiber_nodes[$fiber_index], 'fiber', 3, undef, $fiber_path);
            my $name = _identifier($fiber_items->[1], "$fiber_path/name", 0);
            _unique_name(\%fiber_names, $name, $fiber_items->[1], $fiber_path, 'fiber');
            my @actions;
            for my $action_index (2 .. $#{$fiber_items}) {
                push @actions, $self->_action($context, $fixture, $fiber_items->[$action_index], "$fiber_path/actions/" . ($action_index - 2), $state, $parallel_depth + 1);
            }
            push @fibers, {
                %{$self->_meta($fiber_path, $fiber_nodes[$fiber_index])},
                semantic_id => "$state->{scenario_id}\::fiber_scope\::$fiber_path\::fiber\::$name",
                name => $name, actions => \@actions,
            };
        }
        return { %{$meta}, kind => 'parallel', join => $join, fibers => \@fibers };
    }
    if ($head eq 'repeat') {
        _shape($items, 3, undef, $node, $path, $head);
        my $count = _positive_integer($items->[1], "$path/count", 1, MAX_REPEAT);
        my $before = $state->{action_count};
        my @actions;
        for my $action_index (2 .. $#{$items}) {
            push @actions, $self->_action($context, $fixture, $items->[$action_index], "$path/actions/" . ($action_index - 2), $state, $parallel_depth);
        }
        my $body_count = $state->{action_count} - $before;
        $state->{action_count} += ($count - 1) * $body_count;
        return { %{$meta}, kind => 'repeat', count => $count, actions => \@actions };
    }
    if ($head eq 'expect') {
        _shape($items, 3, 3, $node, $path, $head);
        my $name = _identifier($items->[1], "$path/name", 0);
        _unique_name($state->{expectations}, $name, $items->[1], $path, 'expectation');
        return { %{$meta}, kind => 'expect', semantic_id => "$state->{scenario_id}\::expectation\::$name", name => $name, property => $self->_property($context, $items->[2], "$path/property", $env) };
    }
    if ($head eq 'scoreboard_expect') {
        _shape($items, 3, 3, $node, $path, $head);
        my $instance = $self->_scoreboard_instance_ref($fixture, $items->[1], "$path/scoreboard");
        my $transaction = $self->_transaction_by_id($instance->{transaction_id});
        return { %{$meta}, kind => 'scoreboard_expect', scoreboard_instance_id => $instance->{semantic_id}, fields => $self->_transaction_field_values($context, $fixture, $transaction, $items->[2], "$path/fields", $env) };
    }
    if ($head eq 'scoreboard_check') {
        _shape($items, 2, 2, $node, $path, $head);
        my $instance = $self->_scoreboard_instance_ref($fixture, $items->[1], "$path/scoreboard");
        return { %{$meta}, kind => 'scoreboard_check', scoreboard_instance_id => $instance->{semantic_id} };
    }
    if ($head eq 'inject') {
        _shape($items, 2, 2, $node, $path, $head);
        my $name = _identifier($items->[1], "$path/fault", 0);
        my $fault = _find_named($fixture->{faults}, $name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown fault '$name'", $items->[1]{span}, "$path/fault") unless $fault;
        _fail('VIAL_SEMANTIC_ERROR', 'semantic', "fault '$name' is injected more than once", $items->[1]{span}, "$path/fault")
            if $state->{injected_faults}{$name}++;
        return { %{$meta}, kind => 'inject', fault_id => $fault->{semantic_id} };
    }
    _fail('VIAL_PARSE_ERROR', 'parse', "unknown action '$head'", $items->[0]{span}, $path);
}

sub _transaction_field_values {
    my ($self, $context, $fixture, $transaction, $node, $path, $env) = @_;
    my $items = _form($node, 'fields', 2, undef, $path);
    my (%names, @values);
    for my $index (1 .. $#{$items}) {
        my $item_path = "$path/" . ($index - 1);
        my $field_items = _form($items->[$index], undef, 2, 2, $item_path);
        my $name = _identifier($field_items->[0], "$item_path/name", 0);
        _unique_name(\%names, $name, $field_items->[0], $item_path, 'transaction field value');
        my $field = _find_named($transaction->{fields}, $name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction field '$name'", $field_items->[0]{span}, "$item_path/name") unless $field;
        push @values, {
            %{$self->_meta($item_path, $items->[$index])},
            field_id => $field->{semantic_id},
            value => $self->_expr($context, $field_items->[1], $field->{type}, "$item_path/value", $env),
        };
    }
    for my $field (@{$transaction->{fields}}) {
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "transaction field '$field->{name}' is missing", $node->{span}, $path)
            unless $names{$field->{name}};
    }
    return \@values;
}

sub _property {
    my ($self, $context, $node, $path, $env) = @_;
    if (($node->{node_kind} || '') eq 'list') {
        my $head = _form_head($node, $path);
        if ($head eq '=>') {
            my $items = _form($node, '=>', 3, 3, $path);
            return {
                %{$self->_meta($path, $node)}, kind => 'property', op => '=>',
                result_type => _scalar_type('bool', 1),
                operands => [
                    $self->_property($context, $items->[1], "$path/operands/0", $env),
                    $self->_property($context, $items->[2], "$path/operands/1", $env),
                ],
            };
        }
        if ($head eq 'next') {
            my $items = _form($node, 'next', 2, 2, $path);
            return {
                %{$self->_meta($path, $node)}, kind => 'property', op => 'next',
                result_type => _scalar_type('bool', 1),
                operands => [$self->_property($context, $items->[1], "$path/operands/0", $env)],
            };
        }
        if ($head eq 'within') {
            my $items = _form($node, 'within', 3, 4, $path);
            my ($min, $max);
            if (@{$items} == 3) {
                $min = 1;
                $max = _positive_integer($items->[2], "$path/max_cycles", 1, MAX_CYCLES);
            }
            else {
                $min = _positive_integer($items->[2], "$path/min_cycles", 1, MAX_CYCLES);
                $max = _positive_integer($items->[3], "$path/max_cycles", 1, MAX_CYCLES);
                _fail('VIAL_SEMANTIC_ERROR', 'semantic', 'within min_cycles exceeds max_cycles', $node->{span}, $path)
                    if $min > $max;
            }
            return {
                %{$self->_meta($path, $node)}, kind => 'property', op => 'within',
                result_type => _scalar_type('bool', 1),
                operands => [$self->_property($context, $items->[1], "$path/operands/0", $env)],
                min_cycles => $min, max_cycles => $max,
            };
        }
    }
    return $self->_expr($context, $node, _scalar_type('bool', 1), $path, $env);
}

sub _expr {
    my ($self, $context, $node, $expected_type, $path, $env) = @_;
    if (($node->{node_kind} || '') eq 'atom') {
        my $kind = $node->{atom_kind} || '';
        if ($kind eq 'boolean' || $kind eq 'integer' || $kind eq 'four_state') {
            my $type = $expected_type;
            $type = _scalar_type('bool', 1) if !$type && $kind eq 'boolean';
            _fail('VIAL_TYPE_ERROR', 'type', 'literal requires an exact scalar type context', $node->{span}, $path) unless $type;
            return {
                %{$self->_meta($path, $node)}, kind => 'literal',
                result_type => _clone($type),
                value => $self->_literal($context, $node, $type, "$path/value", $env),
            };
        }
        if ($kind eq 'identifier') {
            my $name = $node->{value};
            if ($name =~ /\./) {
                my ($enum, $member) = $self->_resolve_enum_member($context, $name, $node, $path);
                my $expr = {
                    %{$self->_meta($path, $node)}, kind => 'reference', op => 'enum_member',
                    result_type => { kind => 'reference', authored_name => $name, semantic_id => $enum->{semantic_id}, resolved => _clone($enum->{type}) },
                    semantic_id => $member->{semantic_id},
                };
                $self->_require_type($expr->{result_type}, $expected_type, $node, $path) if $expected_type;
                return $expr;
            }
            my $symbol = ($env->{symbols} || {})->{$name};
            _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown expression identifier '$name'", $node->{span}, $path) unless $symbol;
            my $type = $symbol->{type};
            _fail('VIAL_TYPE_ERROR', 'type', "event identifier '$name' is not a value", $node->{span}, $path)
                if $type->{kind} eq 'event';
            $self->_require_type($type, $expected_type, $node, $path) if $expected_type;
            return {
                %{$self->_meta($path, $node)}, kind => 'reference', op => 'symbol',
                result_type => _clone($type), semantic_id => $symbol->{semantic_id},
            };
        }
        _fail('VIAL_TYPE_ERROR', 'type', 'atom is not a value expression', $node->{span}, $path);
    }

    my $items = _form($node, undef, 2, undef, $path);
    my $op = _atom($items->[0]);
    if ($op eq 'sample') {
        _shape($items, 2, 2, $node, $path, $op);
        my $endpoint = $self->_endpoint_ref_from_env($env, $items->[1], "$path/endpoint");
        $self->_require_type($endpoint->{type}, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'reference', op => 'sample', result_type => _clone($endpoint->{type}), semantic_id => $endpoint->{semantic_id} };
    }
    if ($op eq 'event' || $op eq 'event_count') {
        _shape($items, 3, 3, $node, $path, $op);
        my $event = $self->_event_reference_from_env($env, $items->[1], $items->[2], $path);
        my $type = $op eq 'event' ? _scalar_type('bool', 1) : _scalar_type('u', 64);
        $self->_require_type($type, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'reference', op => $op, result_type => $type, semantic_id => $event->{semantic_id} };
    }
    if ($op eq 'model') {
        _shape($items, 3, 3, $node, $path, $op);
        my $instance_name = _identifier($items->[1], "$path/model", 0);
        my $state_name = _identifier($items->[2], "$path/state", 0);
        my $instance = ($env->{model_instances} || {})->{$instance_name};
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown model instance '$instance_name'", $items->[1]{span}, "$path/model") unless $instance;
        my $state = _find_named($instance->{model}{state}, $state_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown model state '$state_name'", $items->[2]{span}, "$path/state") unless $state;
        $self->_require_type($state->{type}, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'reference', op => 'model', result_type => _clone($state->{type}), semantic_id => $state->{semantic_id} };
    }
    if ($op eq 'choice') {
        _shape($items, 2, 2, $node, $path, $op);
        my $name = _identifier($items->[1], "$path/choice", 0);
        my $choice = ($env->{choices} || {})->{$name};
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown random choice '$name'", $items->[1]{span}, "$path/choice") unless $choice;
        $self->_require_type($choice->{type}, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'reference', op => 'choice', result_type => _clone($choice->{type}), semantic_id => $choice->{semantic_id} };
    }
    if ($op eq 'field') {
        _shape($items, 3, 3, $node, $path, $op);
        my $base = $self->_expr($context, $items->[1], undef, "$path/operands/0", $env);
        my $field_name = _identifier($items->[2], "$path/field", 0);
        my $resolved = $self->_resolved_type($base->{result_type});
        _fail('VIAL_TYPE_ERROR', 'type', 'field operator requires a record operand', $items->[1]{span}, "$path/operands/0") unless $resolved->{kind} eq 'record';
        my $field = _find_named($resolved->{fields}, $field_name);
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown record field '$field_name'", $items->[2]{span}, "$path/field") unless $field;
        $self->_require_type($field->{type}, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => 'field', result_type => _clone($field->{type}), operands => [$base], field_name => $field_name };
    }

    if ($op eq 'not') {
        _shape($items, 2, 2, $node, $path, $op);
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => [$self->_expr($context, $items->[1], $bool, "$path/operands/0", $env)] };
    }
    if ($op eq 'and' || $op eq 'or') {
        _shape($items, 3, undef, $node, $path, $op);
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        my @operands = map { $self->_expr($context, $items->[$_], $bool, "$path/operands/" . ($_ - 1), $env) } 1 .. $#{$items};
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => \@operands };
    }
    if ($op eq 'xor') {
        _shape($items, 3, 3, $node, $path, $op);
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => [map { $self->_expr($context, $items->[$_], $bool, "$path/operands/" . ($_ - 1), $env) } 1, 2] };
    }
    if ($op eq 'same' || $op eq 'value_eq') {
        _shape($items, 3, 3, $node, $path, $op);
        my ($left, $right);
        if (_is_untyped_scalar_literal($items->[1]) && !_is_untyped_scalar_literal($items->[2])) {
            $right = $self->_expr($context, $items->[2], undef, "$path/operands/1", $env);
            $left = $self->_expr($context, $items->[1], $right->{result_type}, "$path/operands/0", $env);
        }
        else {
            $left = $self->_expr($context, $items->[1], undef, "$path/operands/0", $env);
            $right = $self->_expr($context, $items->[2], $left->{result_type}, "$path/operands/1", $env);
        }
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => [$left, $right] };
    }
    if ($op eq 'known') {
        _shape($items, 2, 2, $node, $path, $op);
        my $operand = $self->_expr($context, $items->[1], undef, "$path/operands/0", $env);
        my $resolved = $self->_resolved_type($operand->{result_type});
        _fail('VIAL_TYPE_ERROR', 'type', 'known operator requires a four-state scalar', $items->[1]{span}, "$path/operands/0")
            unless $resolved->{kind} eq 'scalar' && $resolved->{four_state};
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => [$operand] };
    }
    if ($op eq '+' || $op eq '-') {
        _shape($items, 3, 3, $node, $path, $op);
        my ($left, $right);
        if ($expected_type) {
            $left = $self->_expr($context, $items->[1], $expected_type, "$path/operands/0", $env);
        }
        elsif (_is_untyped_scalar_literal($items->[1]) && !_is_untyped_scalar_literal($items->[2])) {
            $right = $self->_expr($context, $items->[2], undef, "$path/operands/1", $env);
            $left = $self->_expr($context, $items->[1], $right->{result_type}, "$path/operands/0", $env);
        }
        else {
            $left = $self->_expr($context, $items->[1], undef, "$path/operands/0", $env);
        }
        my $resolved = $self->_resolved_type($left->{result_type});
        _fail('VIAL_TYPE_ERROR', 'type', 'arithmetic requires a two-state numeric scalar', $items->[1]{span}, "$path/operands/0")
            unless $resolved->{kind} eq 'scalar' && !$resolved->{four_state} && $resolved->{family} ne 'bool';
        $right ||= $self->_expr($context, $items->[2], $left->{result_type}, "$path/operands/1", $env);
        $self->_require_type($left->{result_type}, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => _clone($left->{result_type}), operands => [$left, $right], overflow_policy => 'error' };
    }
    if ($op eq '<' || $op eq '<=' || $op eq '>' || $op eq '>=') {
        _shape($items, 3, 3, $node, $path, $op);
        my ($left, $right);
        if (_is_untyped_scalar_literal($items->[1]) && !_is_untyped_scalar_literal($items->[2])) {
            $right = $self->_expr($context, $items->[2], undef, "$path/operands/1", $env);
            $left = $self->_expr($context, $items->[1], $right->{result_type}, "$path/operands/0", $env);
        }
        else {
            $left = $self->_expr($context, $items->[1], undef, "$path/operands/0", $env);
        }
        my $resolved = $self->_resolved_type($left->{result_type});
        _fail('VIAL_TYPE_ERROR', 'type', 'ordering requires a known two-state numeric scalar', $items->[1]{span}, "$path/operands/0")
            unless $resolved->{kind} eq 'scalar' && !$resolved->{four_state} && $resolved->{family} ne 'bool';
        $right ||= $self->_expr($context, $items->[2], $left->{result_type}, "$path/operands/1", $env);
        my $bool = _scalar_type('bool', 1);
        $self->_require_type($bool, $expected_type, $node, $path) if $expected_type;
        return { %{$self->_meta($path, $node)}, kind => 'operator', op => $op, result_type => $bool, operands => [$left, $right] };
    }
    _fail('VIAL_TYPE_ERROR', 'type', "unknown expression operator '$op'", $items->[0]{span}, $path);
}

sub _literal {
    my ($self, $context, $node, $type, $path, $env) = @_;
    my $resolved = $self->_resolved_type($type);
    if ($resolved->{kind} eq 'enum') {
        my $spelling = _identifier($node, $path, 1);
        my ($enum, $member) = $self->_resolve_enum_member($context, $spelling, $node, $path);
        _fail('VIAL_TYPE_ERROR', 'type', "enum member '$spelling' has the wrong enum type", $node->{span}, $path)
            unless $enum->{semantic_id} eq $resolved->{semantic_id};
        return { kind => 'enum_value', enum_id => $enum->{semantic_id}, member_id => $member->{semantic_id} };
    }
    _fail('VIAL_TYPE_ERROR', 'type', 'literal target must be a scalar or enum', $node->{span}, $path)
        unless $resolved->{kind} eq 'scalar';

    if ($resolved->{family} eq 'bool') {
        _fail('VIAL_TYPE_ERROR', 'type', 'Boolean context requires true or false', $node->{span}, $path)
            unless ($node->{atom_kind} || '') eq 'boolean';
        return { kind => 'bool_value', value => $node->{value} ? 1 : 0 };
    }
    if (($node->{atom_kind} || '') eq 'four_state') {
        _fail('VIAL_TYPE_ERROR', 'type', 'X/Z four-state literal cannot coerce into a two-state type', $node->{span}, $path)
            unless $resolved->{four_state};
        my $digits = substr($node->{value}, 2);
        _fail('VIAL_TYPE_ERROR', 'type', 'four-state literal width does not match its type', $node->{span}, $path)
            unless length($digits) == $resolved->{width};
        return _four_state_value($digits, $resolved->{signed});
    }
    _fail('VIAL_TYPE_ERROR', 'type', 'numeric scalar context requires an integer or four-state literal', $node->{span}, $path)
        unless ($node->{atom_kind} || '') eq 'integer';
    my $value = _integer_bigint($node);
    my ($min, $max) = _scalar_bounds($resolved);
    _fail('VIAL_TYPE_ERROR', 'type', 'integer literal does not fit the exact scalar type', $node->{span}, $path)
        if $value->bcmp($min) < 0 || $value->bcmp($max) > 0;
    if ($resolved->{four_state}) {
        my $modulus = Math::BigInt->new(2)->bpow($resolved->{width});
        my $unsigned = $value->copy;
        $unsigned->badd($modulus) if $unsigned->is_neg;
        my $digits = _bigint_binary($unsigned, $resolved->{width});
        return _four_state_value($digits, $resolved->{signed});
    }
    return {
        kind => 'integer_value', width => $resolved->{width}, signed => $resolved->{signed} ? 1 : 0,
        value_decimal => $value->bstr,
    };
}

sub _is_untyped_scalar_literal {
    my ($node) = @_;
    return 0 unless ($node->{node_kind} || '') eq 'atom';
    return ($node->{atom_kind} || '') eq 'integer' || ($node->{atom_kind} || '') eq 'four_state';
}

sub _resolved_type {
    my ($self, $type) = @_;
    my $current = $type;
    my %seen;
    while (($current->{kind} || '') eq 'reference') {
        _fail('VIAL_TYPE_ERROR', 'type', 'recursive resolved type reference', _zero_location($self->{root_source_name}), '/')
            if $seen{$current->{semantic_id}}++;
        $current = $current->{resolved};
    }
    return $current;
}

sub _require_type {
    my ($self, $actual, $expected, $node, $path) = @_;
    return unless $expected;
    _fail('VIAL_TYPE_ERROR', 'type', 'expression type does not exactly match its required type', $node->{span}, $path)
        unless _type_signature($self->_resolved_type($actual)) eq _type_signature($self->_resolved_type($expected));
}

sub _resolve_stub {
    my ($self, $context, $section, $spelling, $node, $path) = @_;
    my ($target_context, $name);
    if ($spelling =~ /\./) {
        my @parts = split /\./, $spelling;
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "qualified reference '$spelling' must contain one import alias and one name", $node->{span}, $path)
            unless @parts == 2;
        $target_context = $context->{imports}{$parts[0]};
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown import alias '$parts[0]'", $node->{span}, $path) unless $target_context;
        $name = $parts[1];
    }
    else {
        $target_context = $context;
        $name = $spelling;
    }
    my $stub = $target_context->{declarations}{$section}{$name};
    my $kind = $section;
    $kind =~ s/s\z//;
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown $kind reference '$spelling'", $node->{span}, $path) unless $stub;
    return ($target_context, $stub);
}

sub _resolve_enum_member {
    my ($self, $context, $spelling, $node, $path) = @_;
    my @parts = split /\./, $spelling;
    my ($type_spelling, $member_name);
    if (@parts == 2) {
        ($type_spelling, $member_name) = @parts;
    }
    elsif (@parts == 3) {
        $type_spelling = join('.', @parts[0, 1]);
        $member_name = $parts[2];
    }
    else {
        _fail('VIAL_REFERENCE_ERROR', 'resolve', "invalid enum member reference '$spelling'", $node->{span}, $path);
    }
    my ($target_context, $stub) = $self->_resolve_stub($context, 'types', $type_spelling, $node, $path);
    my $enum = $self->_build_type_declaration($target_context, $stub);
    _fail('VIAL_TYPE_ERROR', 'type', "type '$type_spelling' is not an enum", $node->{span}, $path)
        unless $enum->{declaration_kind} eq 'enum';
    my $member = _find_named($enum->{type}{members}, $member_name);
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown enum member '$member_name'", $node->{span}, $path) unless $member;
    return ($enum, $member);
}

sub _fixture_expr_env {
    my ($self, $fixture) = @_;
    return {
        endpoints => { map { $_->{name} => $_ } @{$fixture->{dut}{endpoints} || []} },
        transaction_bindings => { map { $_->{name} => $_ } @{$fixture->{dut}{transaction_bindings} || []} },
        model_instances => { map { $_->{name} => $_ } @{$fixture->{instances}{model_instances} || []} },
        choices => { map { $_->{name} => $_ } @{$fixture->{randomness}{choices} || []} },
        handles => {},
        symbols => {},
    };
}

sub _endpoint_ref_from_env {
    my ($self, $env, $node, $path) = @_;
    my $name = _identifier($node, $path, 0);
    my $endpoint = ($env->{endpoints} || {})->{$name};
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown endpoint '$name'", $node->{span}, $path) unless $endpoint;
    return $endpoint;
}

sub _endpoint_ref {
    my ($self, $fixture, $node, $path) = @_;
    return $self->_endpoint_ref_from_env($self->_fixture_expr_env($fixture), $node, $path);
}

sub _domain_ref {
    my ($self, $fixture, $node, $path) = @_;
    my $name = _identifier($node, $path, 0);
    my $domain = _find_named($fixture->{dut}{domains}, $name);
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown domain '$name'", $node->{span}, $path) unless $domain;
    return $domain;
}

sub _scoreboard_instance_ref {
    my ($self, $fixture, $node, $path) = @_;
    my $name = _identifier($node, $path, 0);
    my $instance = _find_named($fixture->{instances}{scoreboard_instances}, $name);
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown scoreboard instance '$name'", $node->{span}, $path) unless $instance;
    return $instance;
}

sub _event_reference {
    my ($self, $fixture, $node, $path, $handles) = @_;
    my $items = _form($node, 'event', 3, 3, "$path/value");
    my $env = {
        transaction_bindings => { map { $_->{name} => $_ } @{$fixture->{dut}{transaction_bindings}} },
        handles => $handles || {},
    };
    return $self->_event_reference_from_env($env, $items->[1], $items->[2], $path);
}

sub _event_reference_from_env {
    my ($self, $env, $owner_node, $event_node, $path) = @_;
    my $owner_name = _identifier($owner_node, "$path/owner", 0);
    my $event_name = _identifier($event_node, "$path/event", 0);
    my $owner = ($env->{handles} || {})->{$owner_name} || ($env->{transaction_bindings} || {})->{$owner_name};
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction or handle '$owner_name'", $owner_node->{span}, "$path/owner") unless $owner;
    my $transaction = $owner->{transaction};
    my $event = _find_named($transaction->{events}, $event_name);
    _fail('VIAL_REFERENCE_ERROR', 'resolve', "unknown transaction event '$event_name'", $event_node->{span}, "$path/event") unless $event;
    return {
        semantic_id => "$owner->{semantic_id}\::event\::$event_name",
        event_id => $event->{semantic_id},
    };
}

sub _scrub_fixture_build_links {
    my ($self, $fixture) = @_;
    delete $_->{transaction} for @{$fixture->{dut}{transaction_bindings}};
    for my $instance (@{$fixture->{instances}{model_instances}}) {
        delete $instance->{model};
    }
    for my $instance (@{$fixture->{instances}{scoreboard_instances}}) {
        delete $instance->{scoreboard};
    }
}

sub _transaction_by_id {
    my ($self, $semantic_id) = @_;
    for my $context (@{$self->{package_contexts}}) {
        for my $transaction (@{$context->{record}{transactions}}) {
            return $transaction if $transaction->{semantic_id} eq $semantic_id;
        }
    }
    _fail('VIAL_SEMANTIC_ERROR', 'semantic', 'internal transaction identity is unresolved', _zero_location($self->{root_source_name}), '/');
}

sub _meta {
    my ($self, $path, $node) = @_;
    my $location = _clone($node->{span});
    $self->{provenance}{$path} = _clone($location);
    return { semantic_path => $path, source_span => $location };
}

sub _ordered_stubs {
    my ($context, $section) = @_;
    return sort { $a->{index} <=> $b->{index} } values %{$context->{declarations}{$section}};
}

sub _form {
    my ($node, $expected_head, $min, $max, $path) = @_;
    _fail('VIAL_PARSE_ERROR', 'parse', 'expected a list form', $node->{span} || _zero_location('vial/input.vial'), $path)
        unless ($node->{node_kind} || '') eq 'list';
    my $items = $node->{items};
    _fail('VIAL_PARSE_ERROR', 'parse', 'empty list form is not allowed', $node->{span}, $path) unless @{$items};
    _shape($items, $min, $max, $node, $path, $expected_head || 'form');
    if (defined $expected_head) {
        my $actual = _atom($items->[0]);
        _fail('VIAL_PARSE_ERROR', 'parse', "expected '$expected_head' form, found '$actual'", $items->[0]{span}, $path)
            unless $actual eq $expected_head;
    }
    return $items;
}

sub _shape {
    my ($items, $min, $max, $node, $path, $label) = @_;
    if (@{$items} < $min || (defined($max) && @{$items} > $max)) {
        my $expected = defined($max) && $min == $max ? "$min items" : "at least $min items";
        _fail('VIAL_PARSE_ERROR', 'parse', "$label form requires $expected", $node->{span}, $path);
    }
}

sub _form_head {
    my ($node, $path) = @_;
    my $items = _form($node, undef, 1, undef, $path);
    return _atom($items->[0]);
}

sub _atom {
    my ($node) = @_;
    return '' unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'atom';
    return defined($node->{value}) ? $node->{value} : '';
}

sub _identifier {
    my ($node, $path, $qualified) = @_;
    my $kind = $node->{atom_kind} || '';
    my $value = _atom($node);
    my $valid = $kind eq 'identifier' && ($qualified || $value !~ /\./);
    _fail('VIAL_PARSE_ERROR', 'parse', $qualified ? 'expected an identifier or qualified name' : 'expected an unqualified identifier', $node->{span}, $path)
        unless $valid;
    return $value;
}

sub _string {
    my ($node, $path, $nonempty_single_line) = @_;
    _fail('VIAL_PARSE_ERROR', 'parse', 'expected a string literal', $node->{span}, $path)
        unless ($node->{atom_kind} || '') eq 'string';
    if ($nonempty_single_line && ($node->{value} eq '' || $node->{value} =~ /[\r\n]/)) {
        _fail('VIAL_SEMANTIC_ERROR', 'semantic', 'string must be non-empty and single-line', $node->{span}, $path);
    }
    return $node->{value};
}

sub _positive_integer {
    my ($node, $path, $min, $max) = @_;
    _fail('VIAL_TYPE_ERROR', 'type', 'expected a literal positive integer', $node->{span}, $path)
        unless ($node->{atom_kind} || '') eq 'integer';
    my $value = _integer_bigint($node);
    _fail('VIAL_LIMIT_ERROR', 'limit', "integer is outside the bounded range $min through $max", $node->{span}, $path)
        if $value->bcmp($min) < 0 || $value->bcmp($max) > 0;
    return 0 + $value->bstr;
}

sub _unsigned_integer_string {
    my ($node, $path, $max) = @_;
    _fail('VIAL_TYPE_ERROR', 'type', 'expected an unsigned integer literal', $node->{span}, $path)
        unless ($node->{atom_kind} || '') eq 'integer';
    my $value = _integer_bigint($node);
    _fail('VIAL_LIMIT_ERROR', 'limit', 'unsigned integer exceeds its 64-bit range', $node->{span}, $path)
        if $value->is_neg || $value->bcmp($max) > 0;
    return $value->bstr;
}

sub _integer_bigint {
    my ($node) = @_;
    my $raw = $node->{value};
    return Math::BigInt->from_bin($raw) if $raw =~ /\A0[bB]/;
    return Math::BigInt->from_hex($raw) if $raw =~ /\A0[xX]/;
    return Math::BigInt->new($raw);
}

sub _scalar_type {
    my ($family, $width) = @_;
    return {
        kind => 'scalar', family => $family, width => 0 + $width,
        signed => ($family eq 's' || $family eq 'slogic') ? 1 : 0,
        four_state => ($family eq 'logic' || $family eq 'slogic') ? 1 : 0,
    };
}

sub _scalar_bounds {
    my ($type) = @_;
    if ($type->{signed}) {
        my $limit = Math::BigInt->new(2)->bpow($type->{width} - 1);
        return ($limit->copy->bneg, $limit->copy->bsub(1));
    }
    return (Math::BigInt->new(0), Math::BigInt->new(2)->bpow($type->{width})->bsub(1));
}

sub _four_state_value {
    my ($digits, $signed) = @_;
    my ($value_bits, $known_mask, $z_mask) = ('', '', '');
    for my $char (split //, $digits) {
        $value_bits .= $char eq '1' ? '1' : '0';
        $known_mask .= ($char eq '0' || $char eq '1') ? '1' : '0';
        $z_mask .= $char eq 'z' ? '1' : '0';
    }
    my $width = length($digits);
    return {
        kind => 'logic_vector', width => $width, signed => $signed ? 1 : 0,
        value_bits => _binary_hex($value_bits, $width),
        known_mask => _binary_hex($known_mask, $width),
        z_mask => _binary_hex($z_mask, $width),
    };
}

sub _binary_hex {
    my ($bits, $width) = @_;
    my $hex = Math::BigInt->from_bin("0b$bits")->as_hex;
    $hex =~ s/\A0x//;
    $hex = lc($hex);
    my $digits = int(($width + 3) / 4);
    return ('0' x ($digits - length($hex))) . $hex;
}

sub _bigint_binary {
    my ($value, $width) = @_;
    my $bits = $value->as_bin;
    $bits =~ s/\A0b//;
    return ('0' x ($width - length($bits))) . $bits;
}

sub _type_signature {
    my ($type) = @_;
    return join(':', 'scalar', @{$type}{qw(family width signed four_state)}) if $type->{kind} eq 'scalar';
    return 'enum:' . $type->{semantic_id} if $type->{kind} eq 'enum';
    return 'record:' . join(',', map { $_->{name} . '=' . _type_signature($_->{type}{kind} eq 'reference' ? $_->{type}{resolved} : $_->{type}) } @{$type->{fields}}) if $type->{kind} eq 'record';
    return 'list:' . $type->{length} . ':' . _type_signature($type->{element_type}{kind} eq 'reference' ? $type->{element_type}{resolved} : $type->{element_type}) if $type->{kind} eq 'list';
    return 'unknown';
}

sub _value_bigint {
    my ($value) = @_;
    return Math::BigInt->new($value->{value_decimal}) if $value->{kind} eq 'integer_value';
    return Math::BigInt->new($value->{value} ? 1 : 0) if $value->{kind} eq 'bool_value';
    _fail('VIAL_TYPE_ERROR', 'type', 'value is not an ordered known scalar', _zero_location('vial/input.vial'), '/');
}

sub _find_named {
    my ($items, $name) = @_;
    for my $item (@{$items || []}) {
        return $item if defined($item->{name}) && $item->{name} eq $name;
    }
    return undef;
}

sub _unique_name {
    my ($seen, $name, $node, $path, $kind) = @_;
    if ($seen->{$name}) {
        my $location = ref($seen->{$name}) eq 'HASH' && exists($seen->{$name}{source_name})
            ? $seen->{$name}
            : ref($seen->{$name}) eq 'HASH' && $seen->{$name}{source_span}
                ? $seen->{$name}{source_span}
                : undef;
        _fail(
            'VIAL_REFERENCE_ERROR', 'resolve', "duplicate $kind '$name'",
            $node->{span}, $path,
            $location ? [_note("first $kind", $location)] : [],
        );
    }
    $seen->{$name} = $node->{span};
}

sub _unique_scalar {
    my ($seen, $value, $node, $path, $kind) = @_;
    if ($seen->{$value}) {
        _fail(
            'VIAL_REFERENCE_ERROR', 'resolve', "duplicate $kind '$value'",
            $node->{span}, $path,
            [_note("first $kind", $seen->{$value})],
        );
    }
    $seen->{$value} = $node->{span};
}

sub _note {
    my ($message, $location) = @_;
    return { message => $message, source_location => _clone($location) };
}

sub _invocation_error {
    my ($args, $message) = @_;
    my $source_name = ref($args) eq 'HASH' && defined($args->{root_source_name}) && !ref($args->{root_source_name})
        ? $args->{root_source_name} : 'vial/input.vial';
    _fail('VIAL_SEMANTIC_ERROR', 'semantic', $message || 'builder invocation must be one unblessed hash', _zero_location($source_name), '/');
}

sub _fail {
    my ($code, $phase, $message, $location, $path, $notes) = @_;
    $message =~ s/[\r\n]+/ /g;
    die bless({
        schema_version => 1, severity => 'error', code => $code, phase => $phase,
        message => $message, semantic_path => defined($path) ? $path : '/',
        source_location => _clone($location), notes => _clone($notes || []),
    }, 'FSM::VIAL::Diagnostic');
}

sub _zero_location {
    my ($source_name) = @_;
    return {
        source_name => $source_name, start_byte => 0, end_byte_exclusive => 0,
        start_line => 1, start_column => 1, end_line => 1, end_column => 1,
    };
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
