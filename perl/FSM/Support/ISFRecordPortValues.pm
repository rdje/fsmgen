package FSM::Support::ISFRecordPortValues;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Storable qw(dclone);
use FSM::Package::AggregatePathSupport;
use FSM::Composition::InterfacePortBuilder;
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);

our @EXPORT_OK = qw(record_value_scope record_value_reference validate_record_port_copy);

# Preparation only: callers supply resolved declaration facts, not source text.
# Local bindings mask outer declarations even when their type is unresolved.
sub record_value_scope {
    my %args = @_;
    _keys(\%args, [qw(outer local)], [], 'scope');
    my %scope;
    for my $layer (qw(outer local)) {
        my $roots = $args{$layer};
        _require(ref($roots) eq 'HASH', "$layer roots must be a map");
        for my $name (sort keys %$roots) {
            _require(_identifier($name), 'invalid declaration root');
            my $root = $roots->{$name};
            _keys($root, [qw(role type_spec)], [], "root '$name'");
            # Numeric validation can change Perl scalar flags and therefore
            # JSON kinds even without an assignment. Detach before any reads.
            $root = dclone($root);
            _require(_role($root->{role}), "root '$name' has invalid role");
            my $spec = $root->{type_spec};
            _validate_type($spec, "root '$name'") if defined $spec;
            $scope{$name} = {
                role => $root->{role},
                type_spec => FSM::Package::AggregatePathSupport->clone_structured_value($spec),
            };
        }
    }
    return \%scope;
}

# An unrelated token or unresolved binding belongs to the caller's existing
# validator. In particular, it must not fall through to a shadowed outer root.
sub record_value_reference {
    my %args = @_;
    _keys(\%args, [qw(scope token access context)], ['allow_whole'], 'reference');
    my ($scope, $token, $access, $context) = @args{qw(scope token access context)};
    _require(ref($scope) eq 'HASH', 'reference scope must be a map');
    _require(_text($context), 'reference requires context');
    _require(defined($access) && !ref($access) && ($access eq 'read' || $access eq 'write'),
        "$context has invalid access");
    my $allow_whole = $args{allow_whole} // 0;
    _require(_binary($allow_whole), "$context has invalid whole-value permission");
    return undef unless defined($token) && !ref($token)
        && $token =~ /\A([A-Za-z_]\w*)(.*)\z/s;
    my ($name, $path) = ($1, $2);
    return undef unless exists $scope->{$name};
    my $root = $scope->{$name};
    _keys($root, [qw(role type_spec)], [], "$context root '$name'");
    $root = dclone($root);
    _require(_role($root->{role}), "$context root '$name' has invalid role");
    _require($access ne 'write' || $root->{role} ne 'input',
        "$context cannot write declared input '$token'");
    return undef unless defined $root->{type_spec};
    _validate_type($root->{type_spec}, "$context root '$name'");
    my %result = (root => $name, role => $root->{role}, path_text => $path);
    if (!length $path) {
        my $spec = $root->{type_spec};
        _require($allow_whole || !_aggregate($spec),
            "$context requires a scalar value; '$token' is a whole $spec->{kind}");
        $result{type_spec} = FSM::Package::AggregatePathSupport->clone_structured_value($spec);
        $result{width} = 0 + $spec->{width};
        return \%result;
    }
    # Preserve scalar formal/local slices when they mask an outer record.
    # Core traversal accepts scalar indexing after a member; a one-member
    # wrapper supplies that anchor without changing the packed bit offsets.
    my ($path_root, $path_text) = ($root->{type_spec}, $path);
    if (!_aggregate($path_root)) {
        $path_root = _wrapper($path_root);
        $path_text = '.value' . $path;
    }
    my $resolved = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $path_root, path_text => $path_text,
    );
    _require($resolved->{ok}, "$context has invalid declared path '$token': "
        . ($resolved->{code} // 'unresolved'));
    _require(!_aggregate($resolved->{type_spec}),
        "$context requires a scalar leaf; '$token' resolves to $resolved->{type_spec}{kind}");
    @result{qw(type_spec width low high)} = @{$resolved}{qw(type_spec width low high)};
    return \%result;
}

# Return false for the caller's established scalar/storage-only assignment
# contract. Only a whole record port introduces the stricter copy obligation.
sub validate_record_port_copy {
    my %args = @_;
    _keys(\%args, [qw(source target context)], [], 'copy');
    my ($source, $target, $context) = @args{qw(source target context)};
    _require(_text($context), 'copy requires context');
    $source = dclone($source) if ref($source) eq 'HASH';
    $target = dclone($target) if ref($target) eq 'HASH';
    _validate_reference($_, $context) for grep { defined $_ } ($source, $target);
    return 0 unless _record_port($source) || _record_port($target);
    _require(_whole_record($source) && _whole_record($target),
        "$context whole record port copy requires declared record roots");
    _require($target->{role} ne 'input',
        "$context cannot write declared input '$target->{root}'");
    _require(!FSM::Composition::InterfacePortBuilder->declared_type_conflicts(
        $source->{type_spec}, $target->{type_spec}),
        "$context record port copy from '$source->{root}' to '$target->{root}' requires the same resolved record type");
    return 1;
}

sub _validate_reference {
    my ($value, $context) = @_;
    _keys($value, [qw(root role path_text type_spec width)], [qw(low high)], "$context value");
    _require(_identifier($value->{root}) && _role($value->{role})
        && defined($value->{path_text}) && !ref($value->{path_text}), "$context has invalid declaration facts");
    _validate_type($value->{type_spec}, $context);
    _require(_positive($value->{width}) && $value->{width} == $value->{type_spec}{width},
        "$context value width disagrees with resolved type");
    my $leaf = length($value->{path_text}) ? 1 : 0;
    _require($leaf == (exists($value->{low}) && exists($value->{high}) ? 1 : 0),
        "$context value range disagrees with path");
    _require($leaf || (!exists($value->{low}) && !exists($value->{high})),
        "$context whole value cannot have a range");
    if ($leaf) {
        _require(!_aggregate($value->{type_spec}) && _nonnegative($value->{low})
            && _nonnegative($value->{high}) && $value->{high} - $value->{low} + 1 == $value->{width},
            "$context has invalid scalar range");
    }
}

sub _validate_type {
    my ($spec, $context) = @_;
    _require(ref($spec) eq 'HASH', "$context lacks a resolved type");
    # The qualified declaration producer owns recursive layout, cycle, width,
    # member inventory and scalar-property validation. A wrapper lets the same
    # check consume existing list storage without admitting list-root ports.
    my $checked = $spec;
    if (($spec->{kind} // '') eq 'list') {
        $checked = _wrapper($spec);
    }
    my $ok = eval {
        capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',
            width => $checked->{width}, type_spec => $checked}], outputs => []});
        1;
    };
    my $error = $@;
    _require($ok, "$context has invalid resolved type: $error");
    _closed_type($spec, $context);
}

sub _closed_type {
    my ($spec, $context) = @_;
    my $kind = $spec->{kind};
    my @extra = $kind eq 'record' ? qw(members member_order) : $kind eq 'list' ? ('items') : ();
    _keys($spec, [qw(kind width signed), @extra],
        _aggregate($spec) ? [] : ['state_model'], "$context resolved type");
    _require(_binary($spec->{signed}), "$context has invalid resolved signed fact");
    if (_aggregate($spec)) {
        _require($spec->{signed} == 0, "$context aggregate has a scalar signed overlay");
        my @children = $kind eq 'record'
            ? map { $spec->{members}{$_} } @{$spec->{member_order}}
            : @{$spec->{items}};
        _closed_type($_, $context) for @children;
    }
}

sub _record_port {
    my ($value) = @_;
    return 0 unless _whole_record($value);
    return ($value->{role} eq 'input' || $value->{role} eq 'output') ? 1 : 0;
}
sub _wrapper {
    my ($spec) = @_;
    return {kind => 'record', width => $spec->{width}, signed => 0,
        member_order => ['value'], members => {value => $spec}};
}
sub _whole_record {
    my ($value) = @_;
    return (ref($value) eq 'HASH' && !length($value->{path_text})
        && $value->{type_spec}{kind} eq 'record') ? 1 : 0;
}
sub _aggregate { ($_[0]{kind} eq 'record' || $_[0]{kind} eq 'list') ? 1 : 0 }
sub _identifier { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/) ? 1 : 0 }
sub _role { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:input|output|storage|local)\z/) ? 1 : 0 }
sub _text { (defined($_[0]) && !ref($_[0]) && length($_[0])) ? 1 : 0 }
sub _positive { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[1-9][0-9]*\z/) ? 1 : 0 }
sub _nonnegative { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/) ? 1 : 0 }
sub _binary { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[01]\z/) ? 1 : 0 }
sub _keys {
    my ($value, $required, $optional, $context) = @_;
    _require(ref($value) eq 'HASH', "$context must be a map");
    my %allowed = map { $_ => 1 } (@$required, @$optional);
    _require(!grep(!exists($value->{$_}), @$required), "$context lacks required facts");
    _require(!grep(!$allowed{$_}, keys %$value), "$context has unknown facts");
}
sub _require {
    confess "Invalid ISF record value: validation requires a predicate and message\n" unless @_ == 2;
    confess "Invalid ISF record value: $_[1]\n" unless $_[0];
}

1;
