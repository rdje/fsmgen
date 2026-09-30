package FSM::Support::ISFRecordPortScopes;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use FSM::Support::ISFRecordPortValues qw(record_value_scope);

our @EXPORT_OK = qw(record_actor_scope record_transaction_scope record_drive_scope);

# Preparatory declaration projection only. Existing parser/lowering validators
# still own declaration admission, including local collisions and options.
sub record_actor_scope {
    my %args = @_;
    _arguments(\%args, [qw(actor)]);
    my $actor = $args{actor};
    _require(ref($actor) eq 'HASH', 'actor must be a map');
    my %roots;
    _ports($actor->{interface}, \%roots, 'actor');
    for my $entry (@{$actor->{storage} || []}) {
        _require(ref($entry) eq 'HASH', 'storage declaration must be a map');
        next unless ($entry->{kind} // '') eq 'var';
        my $name = $entry->{name};
        _require(_identifier($name), 'storage declaration requires an identifier');
        # Preserve pin roles even on caller-supplied conflicting declarations.
        # Authored pin/storage collisions remain rejected by the parser.
        next if exists $roots{$name};
        $roots{$name} = _binding($entry, 'storage', "storage '$name'");
    }
    return record_value_scope(outer => \%roots, local => {});
}

sub record_transaction_scope {
    my %args = @_;
    _arguments(\%args, [qw(actor transaction)]);
    my $outer = record_actor_scope(actor => $args{actor});
    my $tx = $args{transaction};
    _require(ref($tx) eq 'HASH', 'transaction must be a map');
    my %local;
    _ports($tx->{ports}, \%local, 'transaction');
    for my $clause (@{$tx->{clauses} || []}) {
        next unless ref($clause) eq 'ARRAY' && @$clause
            && defined($clause->[0]) && !ref($clause->[0]) && $clause->[0] eq 'local';
        my $name = $clause->[1];
        _require(_identifier($name), 'local declaration requires an identifier');
        my ($width, $typed);
        for my $option (@{$clause}[2 .. $#$clause]) {
            next unless ref($option) eq 'ARRAY' && @$option >= 2;
            next unless defined($option->[0]) && !ref($option->[0]);
            $width = $option->[1] if $option->[0] eq 'width';
            $typed = 1 if $option->[0] eq 'type';
        }
        # Explicit locals have the nearest name, even if their width/options
        # still require rejection by the existing local-declaration validator.
        $local{$name} = {role => 'local',
            type_spec => $typed ? undef : _scalar_width($width)};
    }
    return record_value_scope(outer => $outer, local => \%local);
}

sub record_drive_scope {
    my %args = @_;
    _arguments(\%args, [qw(actor drive)]);
    my $outer = record_actor_scope(actor => $args{actor});
    my $drive = $args{drive};
    _require(ref($drive) eq 'HASH', 'drive must be a map');
    my %local;
    for my $name (@{$drive->{params} || []}) {
        _require(_identifier($name), 'drive parameter requires an identifier');
        # A parameter name carries no resolved type declaration. Widths inferred
        # later from a drive target are not declaration facts at this boundary.
        $local{$name} = {role => 'local', type_spec => undef};
    }
    return record_value_scope(outer => $outer, local => \%local);
}

sub _ports {
    my ($interface, $roots, $context) = @_;
    return unless defined $interface;
    _require(ref($interface) eq 'HASH', "$context interface must be a map");
    for my $pair ([inputs => 'input'], [outputs => 'output']) {
        for my $entry (@{$interface->{$pair->[0]} || []}) {
            _require(ref($entry) eq 'HASH' && _identifier($entry->{name}),
                "$context port requires a declared identifier");
            my $name = $entry->{name};
            _require(!exists($roots->{$name}), "$context has duplicate port '$name'");
            $roots->{$name} = _binding($entry, $pair->[1], "$context port '$name'");
        }
    }
}

sub _binding {
    my ($entry, $role, $context) = @_;
    my $spec = $entry->{type_spec};
    if (defined $spec) {
        _require(ref($spec) eq 'HASH' && _positive($spec->{width})
            && _positive($entry->{width}) && $spec->{width} == $entry->{width},
            "$context resolved type disagrees with declared width");
    } elsif (!exists $entry->{type}) {
        $spec = _scalar_width($entry->{width});
    }
    return {role => $role, type_spec => $spec};
}

sub _scalar_width {
    my ($width) = @_;
    return undef unless _positive($width);
    # Width-only declarations have no authored alias or state-model overlay.
    return {kind => 'bits', width => 0 + $width, signed => 0};
}
sub _identifier { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/) ? 1 : 0 }
sub _positive { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[1-9][0-9]*\z/) ? 1 : 0 }
sub _arguments {
    my ($args, $keys) = @_;
    my %allowed = map { $_ => 1 } @$keys;
    _require(!grep(!exists($args->{$_}), @$keys), 'missing scope argument');
    _require(!grep(!$allowed{$_}, keys %$args), 'unknown scope argument');
}
sub _require {
    confess "Invalid ISF declaration scope: validation requires a predicate and message\n" unless @_ == 2;
    confess "Invalid ISF declaration scope: $_[1]\n" unless $_[0];
}

1;
