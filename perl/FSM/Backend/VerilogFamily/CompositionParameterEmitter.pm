package FSM::Backend::VerilogFamily::CompositionParameterEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::CompositionBindingEmitter;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub lower_declarations ($class, %args) {
    my $structural = $args{structural};
    confess "Composition parameter lowering requires a structural hash\n"
        unless ref($structural) eq 'HASH';
    my $language = $structural->{target_language} // 'systemverilog';
    confess "Composition parameter lowering requires a Verilog-family target\n"
        unless !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    return [] unless exists $structural->{parameter_environment};

    my $environment = $structural->{parameter_environment};
    confess "Composition parameter lowering requires a resolved environment\n"
        unless ref($environment) eq 'HASH'
            && ref($environment->{scope}) eq 'HASH'
            && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    my $module = $structural->{module_name};
    my $scope = $environment->{scope};
    confess "Composition parameter scope must identify the actual structural module\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($module)
            && defined($scope->{kind}) && !ref($scope->{kind}) && $scope->{kind} eq 'composition_top'
            && defined($scope->{owner}) && !ref($scope->{owner}) && $scope->{owner} eq $module;

    my %reserved = ($module => 'module');
    for my $bucket (['ports', 'name', 'port'], ['nets', 'name', 'net'], ['instances', 'instance_name', 'instance']) {
        my ($key, $name_key, $origin) = @$bucket;
        my $entries = $structural->{$key} // [];
        confess "Composition parameter namespace requires structural $key as an array\n"
            unless ref($entries) eq 'ARRAY';
        for my $entry (@$entries) {
            confess "Composition parameter namespace requires a named structural $origin\n"
                unless ref($entry) eq 'HASH'
                    && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($entry->{$name_key});
            $reserved{$entry->{$name_key}} //= $origin;
        }
    }
    my $typedefs = $args{aggregate_typedef_lookup};
    confess "Composition parameter namespace requires the collected aggregate typedef lookup\n"
        unless ref($typedefs) eq 'HASH';
    for my $name (values %$typedefs) {
        confess "Composition parameter namespace has an invalid generated typedef name\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
        $reserved{$name} //= 'typedef';
    }

    my ($parameters, $order, $bindings) = @{$environment}{qw(parameters declaration_order default_bindings)};
    my %declared;
    for my $name (@$order) {
        confess "Composition parameter lowering has invalid declaration order\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($parameters->{$name}) && !$declared{$name}++;
        confess "Composition parameter '$name' is reserved in SystemVerilog\n"
            if grep {$_ eq 'SystemVerilog'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
        confess "Composition parameter '$name' collides with structural $reserved{$name}\n"
            if exists $reserved{$name};
        my $parameter = $parameters->{$name};
        confess "Composition declaration '$name' requires a scalar parameter\n"
            unless ref($parameter) eq 'HASH' && ($parameter->{value_kind} // '') eq 'scalar'
                && ref($parameter->{value_payload}) eq 'HASH'
                && ($parameter->{value_payload}{kind} // '') =~ /\A(?:scalar|scalar_expr)\z/;
        if (exists $parameter->{value_type_spec}) {
            my $type = $parameter->{value_type_spec};
            confess "Composition declaration '$name' has an unsupported inferred scalar type\n"
                unless ref($type) eq 'HASH' && ($type->{kind} // '') =~ /\A(?:bit|bits)\z/;
        }
    }
    confess "Composition parameter lowering has incomplete declaration order\n"
        unless keys(%declared) == keys(%$parameters);
    confess "Composition parameter lowering requires complete default binding membership\n"
        unless ref($bindings) eq 'HASH' && keys(%$bindings) == keys(%declared)
            && !grep {!exists $bindings->{$_}} @$order;

    my (%lowered, %dependencies);
    for my $name (@$order) {
        my $expression = FSM::Backend::VerilogFamily::CompositionBindingEmitter->lower_expression(
            binding => $bindings->{$name}, environment => $environment, target_language => $language);
        $lowered{$name} = {name => $name, default_text => $expression->{text},
            parameter_references => $expression->{parameter_references}};
        $dependencies{$name} = {map {$_ => 1} @{$expression->{parameter_references}}};
    }

    # Choose the first currently ready declaration in authored order. This
    # preserves independent tie order while moving forward dependencies ahead
    # of their consumers, without consulting cached resolution values.
    my (%emitted, @result);
    while (@result < @$order) {
        my $next;
        for my $candidate (@$order) {
            next if $emitted{$candidate};
            next if grep {!$emitted{$_}} keys %{$dependencies{$candidate}};
            $next = $candidate;
            last;
        }
        confess "Composition parameter defaults contain a dependency cycle in module '$module'\n"
            unless defined $next;
        push @result, $lowered{$next};
        $emitted{$next} = 1;
    }
    return \@result;
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::CompositionParameterEmitter - Canonical scalar top declaration preparation

=head1 DESCRIPTION

Prepares the scalar top declarations consumed by the Verilog-family structural
emitter. This package renders no module. Source admission, symbolic port widths,
explicit typed tops, aggregates and the VHDL profile remain separately guarded.

=head1 METHODS

=head2 lower_declarations

Consumes a prepared structural hash as C<structural> and the actual backend
collector's C<aggregate_typedef_lookup>. For a captured C<parameter_environment>,
returns fresh C<name>, C<default_text> and ordered C<parameter_references>
records in dependency order. The earliest currently ready authored declaration
wins each tie. Static structural inputs return an empty array.

Scope must name the actual module. Module, port, net, instance and collected
typedef names reserve the case-sensitive target namespace. Invalid or reserved
parameter identifiers, incomplete declaration/binding membership, cycles,
foreign references, aggregate values and unsupported inferred types refuse.
Canonical scalar bindings retain selected aliases, literal sizing, operator
nesting and static payloads through L<FSM::Backend::VerilogFamily::CompositionBindingEmitter>.
Validation values and widths never supply declaration text or fixed ranges:
these records prepare untyped parameter defaults, not declarations sized from
their initial values. Explicit typed top parameters remain outside this profile.
Inputs remain read-only and returned nested lists belong to the result.

=cut
