package FSM::Support::ISFWidthSymbols;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(build_width_symbol_plan);

sub build_width_symbol_plan {
    my ($ir) = @_;
    my $bindings = $ir->{_width_bindings};
    confess "Width symbols require canonical width/default bindings\n"
        unless ref($bindings) eq 'HASH';
    my $context = {reserved => _reserved_names($ir), captures => {}, statics => {}};
    my @captures;
    my $actor = $ir->{_width_scopes}{actor};
    my %actor_parameters = map {$_->{name} => $_} @{$actor->{params} || []};
    for my $capture (sort {_identity($a) cmp _identity($b)} @{$bindings->{captures}}) {
        my $parameter = $actor_parameters{$capture->{token}};
        confess "Width symbols lack canonical capture default '$capture->{token}'\n"
            unless ref($parameter) eq 'HASH' && exists($parameter->{value})
                && $capture->{scope}{kind} eq 'actor' && $capture->{scope}{owner} eq $actor->{owner};
        my $name = _allocate($context, 'capture');
        $context->{captures}{_identity($capture)} = $name;
        my $value = exists($parameter->{resolved_value}) ? $parameter->{resolved_value} : $parameter->{value};
        push @captures, {name => $name, source => _copy($capture), value => _copy($value)};
    }

    # The IAL0 default resolver selects parameter roots before static symbols.
    # Protect only static references whose root is an actual module parameter.
    # A constant declaration uses the static namespace and adds no parameter knob.
    my %parameters = map {lc($_->{name}) => 1} @{$ir->{params} || []};
    my %needed;
    _collect_static_aliases($_->{expression}, \%parameters, \%needed)
        for values %{$bindings->{parameter_defaults}};
    my @constants;
    for my $key (sort keys %needed) {
        my $source = $needed{$key};
        my $name = _allocate($context, 'static');
        $context->{statics}{$key} = $name;
        push @constants, {name => $name, source => _copy($source), value => _static_value($actor, $source)};
    }

    return {module_parameters => _copy($bindings->{module_parameters}),
        widths => {map {$_ => _expression($context, $bindings->{declarations}{$_}{expression}, 'width')}
            sort keys %{$bindings->{declarations}}},
        parameter_defaults => {map {$_ => _expression($context, $bindings->{parameter_defaults}{$_}{expression}, 'default')}
            sort keys %{$bindings->{parameter_defaults}}},
        capture_parameters => \@captures, constants => \@constants};
}

sub _collect_static_aliases {
    my ($node, $parameters, $needed) = @_;
    my $kind = $node->{kind};
    if ($kind eq 'list') {
        _collect_static_aliases($_, $parameters, $needed) for @{$node->{items}};
    } elsif ($kind eq 'inline_parameter') {
        _collect_static_aliases($node->{default}, $parameters, $needed);
    } elsif (_is_static($kind)) {
        my ($root) = split /\./, $node->{token};
        $needed->{_identity($node)} = $node if $parameters->{lc($root)};
    }
}

sub _expression {
    my ($context, $node, $slot) = @_;
    my $kind = $node->{kind};
    return _copy($node->{token}) if $kind eq 'literal';
    return [map {_expression($context, $_, $slot)} @{$node->{items}}] if $kind eq 'list';
    return _expression($context, $node->{default}, $slot) if $kind eq 'inline_parameter';
    if ($kind eq 'parameter' || $kind eq 'capture') {
        my $name = $kind eq 'parameter' ? $node->{token} : $context->{captures}{_identity($node)};
        confess "Width symbols lack a declared capture target\n" unless defined $name;
        return $slot eq 'width' ? ['param', _copy($name)] : _copy($name);
    }
    if (_is_static($kind)) {
        my $token = $context->{statics}{_identity($node)} // $node->{token};
        # Arithmetic selects the canonical scalar namespace instead of bare
        # +size's named-type namespace. It performs no new evaluation here.
        return $slot eq 'width' ? ['+', _copy($token), '0'] : _copy($token);
    }
    confess "Width symbols have unsupported binding kind '$kind'\n";
}

sub _is_static {return $_[0] eq 'constant' || $_[0] eq 'package_constant' || $_[0] eq 'enum_member'}

sub _static_value {
    my ($actor, $source) = @_;
    my ($kind, $token) = @{$source}{qw(kind token)};
    my $value;
    if ($kind eq 'constant') {
        my ($constant) = grep {$_->{name} eq $token} @{$actor->{constants} || []};
        $value = $constant->{resolved_value} if $constant;
    } elsif ($kind eq 'package_constant') {
        my $owner = $source->{scope}{owner};
        my $prefix = $owner . '.';
        my $member = index($token, $prefix) == 0 ? substr($token, length($prefix)) : '';
        my $payload = ($actor->{package_constants}{$owner} || {})->{$member};
        $value = $payload->{payload} if ref($payload) eq 'HASH' && $payload->{kind} eq 'scalar';
    } elsif ($kind eq 'enum_member') {
        my @path = split /\./, $token;
        my $enums = $actor->{enum_symbols};
        $value = ($enums->{local}{$path[0]} || {})->{$path[1]} if @path == 2;
        $value = (($enums->{packages}{$path[0]} || {})->{$path[1]} || {})->{$path[2]} if @path == 3;
    }
    confess "Width symbols lack the selected canonical static value '$token'\n"
        unless defined($value) && !ref($value);
    return _copy($value);
}

sub _identity {
    my ($node) = @_;
    my $scope = $node->{scope};
    return join("\0", $node->{kind}, $scope->{kind}, $scope->{actor} // '', $scope->{owner}, $node->{token});
}

sub _allocate {
    my ($context, $family) = @_;
    my $ordinal = $context->{ordinals}{$family} // 0;
    my $name;
    do {$name = 'isf_width_' . $family . '_' . ++$ordinal} while $context->{reserved}{lc($name)};
    $context->{ordinals}{$family} = $ordinal;
    $context->{reserved}{lc($name)} = 1;
    return $name;
}

sub _reserved_names {
    my ($ir) = @_;
    my %reserved = (current_state => 1, next_state => 1);
    # Reserve final emitted declarations and identifiers in executable forms,
    # including implicit signals. Exclude child bodies and private environments:
    # each module allocates against its own namespace, not a guessed ancestor.
    for my $field (qw(actor_name clock reset ports explicit_interface_ports explicit_internal_signals
        params constants type_declarations enum_declarations package_imports package_roots
        counters declared_storage signal_widths signal_type_refs states dt_blocks
        immediate_assertions spawn_instances library_uses atl_top_instances)) {
        _reserve_tokens(\%reserved, $ir->{$field});
    }
    for my $block (@{$ir->{states} || []}, @{$ir->{dt_blocks} || []}) {
        my $name = $block->{name};
        next unless defined($name) && !ref($name);
        $name =~ s/^-//;
        $reserved{lc($name . '_en')} = 1;
        # State encoding localparams use uppercase names. The folded registry
        # covers those and conservative VHDL case collisions together.
        $reserved{lc($name)} = 1;
    }
    return \%reserved;
}

sub _reserve_tokens {
    my ($reserved, $value) = @_;
    return unless defined $value;
    if (ref($value) eq 'ARRAY') {_reserve_tokens($reserved, $_) for @$value}
    elsif (ref($value) eq 'HASH') {
        _reserve_tokens($reserved, $_) for keys %$value, values %$value;
    } elsif (!ref($value)) {
        $reserved->{lc($_)} = 1 for $value =~ /([A-Za-z_][A-Za-z_0-9]*)/g;
    } else {confess "Width symbols cannot reserve an unsupported reference\n"}
}

sub _copy {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Width symbols contain an unsupported reference\n";
}

1;

=head1 NAME

FSM::Support::ISFWidthSymbols - Private target symbols for bound scalar widths and defaults

=head1 DESCRIPTION

C<build_width_symbol_plan($ir)> consumes a final module's canonical width/default
bindings and returns detached C<widths>, C<parameter_defaults>,
C<capture_parameters>, C<constants> and C<module_parameters>. It retains real
parameter names, uses C<(param NAME)> in width positions and inlines immutable
transaction defaults. Nested default lists preserve their structure.

Foreign actor parameters receive deterministic compiler context names and their
canonical resolved defaults. Their source identities remain attached; actual
instance forwarding is a separate required stage. Ambiguous static default
roots receive immutable constant aliases from their selected canonical static
cache values, with source tokens retained separately. Qualified enum tokens
need not be admitted as constant-declaration expressions to preserve identity.
Static widths use canonical scalar arithmetic to avoid bare named-type lookup.

Allocation reserves final module declaration/executable tokens, state encodings
and top-level enable names with conservative case folding. Child bodies and
private lexical environments do not become this module's namespace. No global
allocator state or second evaluator is used. Names avoid collisions among the
observed source declarations; downstream carrier and HDL qualification remain
required. This private plan changes no emitted source, public schema or HDL.

=cut
