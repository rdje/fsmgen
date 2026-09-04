package FSM::VIAL::SourceProjection;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed);

use FSM::VIAL::Parser;

my @PACKAGE_SECTIONS_V1 = qw(imports types transactions models scoreboards fixtures);
my @PACKAGE_SECTIONS_V2 = qw(imports types transactions models scoreboards intents fixtures);
my %PACKAGE_HEAD_SECTION = (
    import => 'imports',
    type => 'types',
    enum => 'types',
    transaction => 'transactions',
    model => 'models',
    scoreboard => 'scoreboards',
    family => 'intents',
    fixture => 'fixtures',
);

sub source_style {
    my ($class, $args) = @_;
    my ($form) = _parse_invocation($args);
    my (undef, $style) = $class->_normalize_parsed_form({
        form => $form,
        source_name => $args->{source_name},
    });
    return $style;
}

sub import_source_names {
    my ($class, $args) = @_;
    my ($form) = _parse_invocation($args);
    my ($normal, undef, $version) = $class->_normalize_parsed_form({
        form => $form,
        source_name => $args->{source_name},
    });
    return [] if defined($version) && $version != 1;
    my $package = $normal->{items}[2];
    my $imports = $package->{items}[2];
    my @names;
    for my $index (1 .. $#{$imports->{items}}) {
        my $import = $imports->{items}[$index];
        next unless _is_list($import) && _head($import) eq 'import';
        next unless @{$import->{items}} == 3 || @{$import->{items}} == 4;
        next unless ($import->{items}[2]{atom_kind} || '') eq 'string';
        push @names, $import->{items}[2]{value};
    }
    return [@names];
}

sub import_source_names_v2 {
    my ($class, $args) = @_;
    my ($form) = _parse_invocation($args);
    my ($normal, undef, $version) = $class->_normalize_parsed_form({
        form => $form,
        source_name => $args->{source_name},
    });
    return [] unless defined($version) && $version == 2;
    my $package = $normal->{items}[2];
    my $imports = $package->{items}[2];
    my @names;
    for my $index (1 .. $#{$imports->{items}}) {
        my $import = $imports->{items}[$index];
        next unless _is_list($import) && _head($import) eq 'import';
        next unless @{$import->{items}} == 3 || @{$import->{items}} == 4;
        next unless ($import->{items}[2]{atom_kind} || '') eq 'string';
        push @names, $import->{items}[2]{value};
    }
    return [@names];
}

sub _source_language_version {
    my ($class, $args) = @_;
    die "VIAL source language-version inspection is private\n"
        unless caller eq 'FSM::VIAL::Tool';
    my ($form) = _parse_invocation($args);
    my (undef, undef, $version) = $class->_normalize_parsed_form({
        form => $form,
        source_name => $args->{source_name},
    });
    return defined($version) ? 0 + $version : 1;
}

sub format_source {
    my ($class, $args) = @_;
    die "VIAL formatter requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    my %allowed = map { $_ => 1 } qw(text source_name output_style);
    my @unknown = sort grep { !$allowed{$_} } keys %{$args};
    die "VIAL formatter received unknown key '$unknown[0]'\n" if @unknown;
    die "VIAL formatter output_style must be normal or terse\n"
        unless defined($args->{output_style})
            && !ref($args->{output_style})
            && ($args->{output_style} eq 'normal' || $args->{output_style} eq 'terse');

    my ($form) = _parse_invocation({
        text => $args->{text},
        source_name => $args->{source_name},
    });
    my ($normal, $input_style) = $class->_normalize_parsed_form({
        form => $form,
        source_name => $args->{source_name},
    });
    my $output = $args->{output_style} eq 'normal'
        ? $normal
        : _normal_to_terse($normal, $args->{source_name});
    return {
        input_style => $input_style,
        output_style => $args->{output_style},
        text => join("\n", @{_render_lines($output, 0)}) . "\n",
    };
}

sub semantic_projection {
    my ($class, $semantic_ir) = @_;
    die "semantic projection requires exact FSM::VIAL::SemanticIR\n"
        unless ref($semantic_ir) eq 'FSM::VIAL::SemanticIR';
    my $data = $semantic_ir->as_hashref;
    my $version = $data->{language_version};
    die "semantic projection does not support VIAL language version $version\n"
        unless $version == 1 || $version == 2;
    my $projection = {
        schema => "fsmgen.vial_semantic_projection.v$version",
        schema_version => 0 + $version,
        language => $data->{language},
        language_version => $data->{language_version},
        profile => $data->{profile},
        root_source => { source_name => $data->{root_source}{source_name} },
        sources => [map { { source_name => $_->{source_name} } } @{$data->{sources}}],
        packages => _without_source_spans($data->{packages}),
        required_capabilities => [@{$data->{required_capabilities}}],
    };
    return _clone($projection);
}

sub semantic_projection_sha256 {
    my ($class, $semantic_ir) = @_;
    my $json = JSON::PP->new->canonical->utf8->encode($class->semantic_projection($semantic_ir));
    return sha256_hex($json);
}

sub compatibility_projection {
    my ($class, $semantic_ir) = @_;
    die "compatibility projection requires exact FSM::VIAL::SemanticIR\n"
        unless ref($semantic_ir) eq 'FSM::VIAL::SemanticIR';
    my $data = $semantic_ir->as_hashref;
    my $version = $data->{language_version};
    die "compatibility projection supports only VIAL language versions 1 and 2\n"
        unless $version == 1 || $version == 2;

    my $packages = _without_source_spans($data->{packages});
    if ($version == 2) {
        for my $package (@{$packages}) {
            delete $package->{intent_families};
        }
    }
    return _clone({
        schema => 'fsmgen.vial_compatibility_projection.v1',
        schema_version => 1,
        language => 'vial',
        root_source => { source_name => $data->{root_source}{source_name} },
        sources => [map { { source_name => $_->{source_name} } } @{$data->{sources}}],
        packages => $packages,
        required_base_semantics => [qw(
            vial.profile.core_directed_single_clock
            vial.semantic_ir
            vial.source
        )],
    });
}

sub compatibility_projection_sha256 {
    my ($class, $semantic_ir) = @_;
    my $json = JSON::PP->new->canonical->utf8->encode(
        $class->compatibility_projection($semantic_ir),
    );
    return sha256_hex($json);
}

sub _normalize_parsed_form {
    my ($class, $args) = @_;
    die "VIAL source normalization is private\n"
        unless caller eq 'FSM::VIAL::Parser'
            || caller eq __PACKAGE__;
    die "VIAL source normalization requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    my $form = $args->{form};
    my $source_name = $args->{source_name};
    my $v1_only = $args->{v1_only} ? 1 : 0;
    return (_clone($form), 'normal', undef)
        unless _is_list($form) && @{$form->{items}} == 3 && _head($form) eq 'vial';

    my $selector = $form->{items}[1];
    if (_is_list($selector) && _head($selector) eq 'version') {
        my $version = _normal_selector_version($selector);
        if ($v1_only || !defined($version) || $version == 1) {
            _validate_normal_outer_shape($form, $source_name, 1);
            return (_clone($form), 'normal', $version);
        }
        _version_error($source_name, $selector, $version) unless $version == 2;
        _validate_normal_outer_shape($form, $source_name, 2);
        return (_clone($form), 'normal', 2);
    }
    if (_is_atom($selector)
        && ($selector->{atom_kind} || '') eq 'integer'
        && $selector->{value} eq '1') {
        return (_terse_to_normal($form, $source_name, 1), 'terse', 1);
    }
    if (!$v1_only
        && _is_atom($selector)
        && ($selector->{atom_kind} || '') eq 'integer') {
        my $version = _integer_value($selector);
        _version_error($source_name, $selector, $version) unless $version == 2;
        FSM::VIAL::Parser::_throw(
            'VIAL_VERSION_UNSUPPORTED', 'parse',
            'terse VIAL version selector must use decimal integer 2',
            $selector->{span}, '/language_version', [], 2,
        ) unless $selector->{value} eq '2';
        return (_terse_to_normal($form, $source_name, 2), 'terse', 2);
    }
    _style_error(
        $source_name, $selector,
        'source style is ambiguous; use normal (version 1) or terse integer 1 at the root',
    );
}

sub _validate_normal_outer_shape {
    my ($root, $source_name, $version) = @_;
    my @sections = _package_sections($version);
    my %section_rank = map { $sections[$_] => $_ } 0 .. $#sections;
    my $package = $root->{items}[2];
    return unless _is_list($package) && _head($package) eq 'package';
    for my $index (2 .. $#{$package->{items}}) {
        my $head = _head($package->{items}[$index]);
        if (exists $PACKAGE_HEAD_SECTION{$head}
            && exists $section_rank{$PACKAGE_HEAD_SECTION{$head}}) {
            _style_error($source_name, $package->{items}[$index], "normal source requires the '$PACKAGE_HEAD_SECTION{$head}' wrapper", $version);
        }
    }
    return unless @{$package->{items}} == @sections + 2;
    for my $offset (0 .. $#sections) {
        my $section = $package->{items}[$offset + 2];
        next unless _is_list($section) && _head($section) eq $sections[$offset];
        next unless $sections[$offset] eq 'fixtures';
        for my $fixture (@{$section->{items}}[1 .. $#{$section->{items}}]) {
            next unless _is_list($fixture) && _head($fixture) eq 'fixture';
            for my $item (@{$fixture->{items}}[2 .. $#{$fixture->{items}}]) {
                _style_error($source_name, $item, "normal source requires the 'scenarios' wrapper", $version)
                    if _head($item) eq 'scenario';
                next unless _head($item) eq 'scenarios';
                for my $scenario (@{$item->{items}}[1 .. $#{$item->{items}}]) {
                    next unless _is_list($scenario) && _head($scenario) eq 'scenario';
                    next unless @{$scenario->{items}} >= 4;
                    _style_error($source_name, $scenario->{items}[3], "normal source requires the 'steps' wrapper", $version)
                        unless _head($scenario->{items}[3]) eq 'steps';
                }
            }
        }
    }
}

sub _terse_to_normal {
    my ($root, $source_name, $version) = @_;
    my @sections_order = _package_sections($version);
    my %section_rank = map { $sections_order[$_] => $_ } 0 .. $#sections_order;
    my $section_order = join(', ', @sections_order[0 .. $#sections_order - 1])
        . ", $sections_order[-1] order";
    my $package = $root->{items}[2];
    _style_error($source_name, $package, 'terse source requires one package form', $version)
        unless _is_list($package) && _head($package) eq 'package' && @{$package->{items}} >= 3;

    my %sections = map { $_ => [] } @sections_order;
    my $last_section_rank = -1;
    for my $item (@{$package->{items}}[2 .. $#{$package->{items}}]) {
        my $head = _head($item);
        _style_error($source_name, $item, "terse source must not use the '$head' wrapper", $version)
            if grep { $_ eq $head } @sections_order;
        my $section = $PACKAGE_HEAD_SECTION{$head};
        _style_error($source_name, $item, "unknown terse package declaration '$head'", $version)
            unless defined($section) && exists($section_rank{$section});
        my $rank = $section_rank{$section};
        _style_error(
            $source_name,
            $item,
            "terse declaration families must remain in $section_order",
            $version,
        ) if $rank < $last_section_rank;
        $last_section_rank = $rank;
        push @{$sections{$section}}, $head eq 'fixture'
            ? _terse_fixture_to_normal($item, $source_name, $version)
            : _clone($item);
    }

    my $package_span = $package->{span};
    my @package_items = (
        _clone($package->{items}[0]),
        _clone($package->{items}[1]),
        map {
            _list([
                _identifier_atom($_, $package_span),
                @{$sections{$_}},
            ], $package_span)
        } @sections_order,
    );
    return _list([
        _clone($root->{items}[0]),
        _list([
            _identifier_atom('version', $root->{items}[1]{span}),
            _integer_atom("$version", $root->{items}[1]{span}),
        ], $root->{items}[1]{span}),
        _list(\@package_items, $package_span),
    ], $root->{span});
}

sub _terse_fixture_to_normal {
    my ($fixture, $source_name, $version) = @_;
    _style_error($source_name, $fixture, 'terse fixture requires fixed DUT, instance, coverage, fault, randomness, and scenario forms', $version)
        unless @{$fixture->{items}} >= 8;
    my @fixed_heads = qw(dut instances coverage faults randomness);
    for my $offset (0 .. $#fixed_heads) {
        my $item = $fixture->{items}[$offset + 2];
        _style_error($source_name, $item, "terse fixture requires '$fixed_heads[$offset]' in fixed order", $version)
            unless _head($item) eq $fixed_heads[$offset];
    }
    my @scenarios;
    for my $item (@{$fixture->{items}}[7 .. $#{$fixture->{items}}]) {
        _style_error($source_name, $item, "terse fixture must not use the 'scenarios' wrapper", $version)
            if _head($item) eq 'scenarios';
        _style_error($source_name, $item, 'terse fixture accepts only scenario forms after randomness', $version)
            unless _head($item) eq 'scenario';
        push @scenarios, _terse_scenario_to_normal($item, $source_name, $version);
    }
    return _list([
        map { _clone($_) } @{$fixture->{items}}[0 .. 6],
        _list([
            _identifier_atom('scenarios', $fixture->{span}),
            @scenarios,
        ], $fixture->{span}),
    ], $fixture->{span});
}

sub _terse_scenario_to_normal {
    my ($scenario, $source_name, $version) = @_;
    _style_error($source_name, $scenario, 'terse scenario requires a name, timeout, and at least one action', $version)
        unless @{$scenario->{items}} >= 4;
    _style_error($source_name, $scenario->{items}[3], "terse scenario must not use the 'steps' wrapper", $version)
        if _head($scenario->{items}[3]) eq 'steps';
    return _list([
        map { _clone($_) } @{$scenario->{items}}[0 .. 2],
        _list([
            _identifier_atom('steps', $scenario->{span}),
            map { _clone($_) } @{$scenario->{items}}[3 .. $#{$scenario->{items}}],
        ], $scenario->{span}),
    ], $scenario->{span});
}

sub _normal_to_terse {
    my ($root, $source_name) = @_;
    my $version = _normal_selector_version($root->{items}[1]);
    _style_error($source_name, $root->{items}[1], 'normal source has an unsupported version selector', 2)
        unless defined($version) && ($version == 1 || $version == 2);
    my @sections = _package_sections($version);
    my $package = $root->{items}[2];
    _style_error($source_name, $package, 'normal package cannot be formatted because its section wrappers are malformed', $version)
        unless _is_list($package) && @{$package->{items}} == @sections + 2;
    my @body;
    for my $offset (0 .. $#sections) {
        my $section_name = $sections[$offset];
        my $section = $package->{items}[$offset + 2];
        _style_error($source_name, $section, "normal package requires '$section_name' wrapper", $version)
            unless _is_list($section) && _head($section) eq $section_name;
        for my $item (@{$section->{items}}[1 .. $#{$section->{items}}]) {
            push @body, $section_name eq 'fixtures'
                ? _normal_fixture_to_terse($item, $source_name, $version)
                : _clone($item);
        }
    }
    return _list([
        _clone($root->{items}[0]),
        _integer_atom("$version", $root->{items}[1]{span}),
        _list([
            _clone($package->{items}[0]),
            _clone($package->{items}[1]),
            @body,
        ], $package->{span}),
    ], $root->{span});
}

sub _package_sections {
    my ($version) = @_;
    return $version == 2 ? @PACKAGE_SECTIONS_V2 : @PACKAGE_SECTIONS_V1;
}

sub _normal_selector_version {
    my ($selector) = @_;
    return undef unless _is_list($selector)
        && @{$selector->{items}} == 2
        && _head($selector) eq 'version';
    return _integer_value($selector->{items}[1]);
}

sub _integer_value {
    my ($node) = @_;
    return undef unless _is_atom($node) && ($node->{atom_kind} || '') eq 'integer';
    my $value = $node->{value};
    my $number = $value =~ /\A0[bB]/
        ? Math::BigInt->from_bin($value)
        : $value =~ /\A0[xX]/
            ? Math::BigInt->from_hex($value)
            : Math::BigInt->new($value);
    return undef if !defined($number) || $number->is_nan || $number->is_neg;
    return 0 + $number->bstr if $number->bcmp(2_147_483_647) <= 0;
    return $number->bstr;
}

sub _version_error {
    my ($source_name, $node, $version) = @_;
    my $shown = defined($version) ? $version : 'invalid';
    FSM::VIAL::Parser::_throw(
        'VIAL_VERSION_UNSUPPORTED', 'parse',
        "VIAL language version '$shown' is not supported",
        $node->{span}, '/language_version', [], 2,
    );
}

sub _normal_fixture_to_terse {
    my ($fixture, $source_name, $version) = @_;
    _style_error($source_name, $fixture, 'normal fixture cannot be formatted because its scenarios wrapper is malformed', $version)
        unless _is_list($fixture) && @{$fixture->{items}} == 8 && _head($fixture->{items}[7]) eq 'scenarios';
    my $scenarios = $fixture->{items}[7];
    return _list([
        map { _clone($_) } @{$fixture->{items}}[0 .. 6],
        map { _normal_scenario_to_terse($_, $source_name, $version) }
            @{$scenarios->{items}}[1 .. $#{$scenarios->{items}}],
    ], $fixture->{span});
}

sub _normal_scenario_to_terse {
    my ($scenario, $source_name, $version) = @_;
    _style_error($source_name, $scenario, 'normal scenario cannot be formatted because its steps wrapper is malformed', $version)
        unless _is_list($scenario) && @{$scenario->{items}} == 4 && _head($scenario->{items}[3]) eq 'steps';
    my $steps = $scenario->{items}[3];
    return _list([
        map { _clone($_) } @{$scenario->{items}}[0 .. 2],
        map { _clone($_) } @{$steps->{items}}[1 .. $#{$steps->{items}}],
    ], $scenario->{span});
}

sub _parse_invocation {
    my ($args) = @_;
    die "VIAL source projection requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    my %allowed = map { $_ => 1 } qw(text source_name);
    my @unknown = sort grep { !$allowed{$_} } keys %{$args};
    die "VIAL source projection received unknown key '$unknown[0]'\n" if @unknown;
    for my $required (qw(text source_name)) {
        die "VIAL source projection requires scalar '$required'\n"
            unless exists($args->{$required}) && defined($args->{$required}) && !ref($args->{$required});
    }
    return FSM::VIAL::Parser->_parse_source_form_for_projection($args);
}

sub _render_lines {
    my ($node, $indent) = @_;
    return [(' ' x $indent) . _render_atom($node)] if _is_atom($node);
    my @items = @{$node->{items}};
    return [(' ' x $indent) . '()'] unless @items;
    if (!grep { _is_list($_) } @items) {
        return [(' ' x $indent) . '(' . join(' ', map { _render_atom($_) } @items) . ')'];
    }

    my @leading;
    while (@items && _is_atom($items[0])) {
        push @leading, shift @items;
    }
    my @lines = ((' ' x $indent) . '(' . join(' ', map { _render_atom($_) } @leading));
    for my $item (@items) {
        push @lines, @{_render_lines($item, $indent + 2)};
    }
    $lines[-1] .= ')';
    return \@lines;
}

sub _render_atom {
    my ($node) = @_;
    my $kind = $node->{atom_kind} || '';
    return JSON::PP->new->allow_nonref->canonical->encode($node->{value})
        if $kind eq 'string';
    return $node->{value} ? 'true' : 'false' if $kind eq 'boolean';
    return lc($node->{value}) if $kind eq 'integer' || $kind eq 'four_state';
    return $node->{value};
}

sub _without_source_spans {
    my ($value) = @_;
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _without_source_spans($value->{$_}) }
                grep { $_ ne 'source_span' } sort keys %{$value}
        };
    }
    return [map { _without_source_spans($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

sub _style_error {
    my ($source_name, $node, $message, $schema_version) = @_;
    my $span = ref($node) eq 'HASH' && ref($node->{span}) eq 'HASH'
        ? $node->{span}
        : {
            source_name => $source_name,
            start_byte => 0,
            end_byte_exclusive => 0,
            start_line => 1,
            start_column => 1,
            end_line => 1,
            end_column => 1,
        };
    FSM::VIAL::Parser::_throw(
        'VIAL_SOURCE_STYLE_ERROR', 'parse', $message, $span, '/', [],
        defined($schema_version) && $schema_version == 2 ? 2 : 1,
    );
}

sub _identifier_atom {
    my ($value, $span) = @_;
    return {
        node_kind => 'atom', atom_kind => 'identifier',
        value => $value, raw => $value, span => _clone($span),
    };
}

sub _integer_atom {
    my ($value, $span) = @_;
    return {
        node_kind => 'atom', atom_kind => 'integer',
        value => $value, raw => $value, span => _clone($span),
    };
}

sub _list {
    my ($items, $span) = @_;
    return { node_kind => 'list', items => $items, span => _clone($span) };
}

sub _head {
    my ($node) = @_;
    return '' unless _is_list($node) && @{$node->{items}};
    return _is_atom($node->{items}[0]) ? $node->{items}[0]{value} : '';
}

sub _is_list {
    my ($node) = @_;
    return ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'list';
}

sub _is_atom {
    my ($node) = @_;
    return ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'atom';
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
