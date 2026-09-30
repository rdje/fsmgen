package FSM::Support::ISFRecordPortScopes;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Storable qw(dclone);
use FSM::Support::ISFRecordPortValues qw(record_value_scope);

our @EXPORT_OK = qw(record_actor_scope record_transaction_scope record_drive_scope
    record_context_scope record_reference_root_kind);

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

# One detached declaration projection for value, aggregate, enum and rule
# consumers. This does not resolve enum/package members or admit source forms.
sub record_context_scope {
    my %args = @_;
    _arguments(\%args, [qw(actor)], [qw(transaction drive)]);
    _require(!(exists($args{transaction}) && exists($args{drive})),
        'context cannot select both transaction and drive');
    my $actor = $args{actor};
    my $outer = record_actor_scope(actor => $actor);
    my $roots = exists($args{transaction})
        ? record_transaction_scope(actor => $actor, transaction => $args{transaction})
        : exists($args{drive}) ? record_drive_scope(actor => $actor, drive => $args{drive}) : $outer;
    my $enums = $actor->{enum_symbols} || {};
    my $constants = $actor->{constant_symbols} || {};
    my %namespaces = map {$_ => 1} (keys %{$enums->{local} || {}},
        keys %{$enums->{packages} || {}}, keys %{$constants->{packages} || {}});
    my %aggregates = map {$_ => dclone($roots->{$_}{type_spec})}
        grep {_aggregate($roots->{$_}{type_spec})} keys %$roots;
    my %exclusions = map {$_ => 1} keys %aggregates;
    # A scalar/unresolved formal masking an actor record must not let an enum
    # namespace lend it that record's missing layout.
    $exclusions{$_} = 1 for grep {_aggregate($outer->{$_}{type_spec})} keys %$outer;
    my %declared = map {$_ => 1} keys %$outer;
    for my $entry (@{$actor->{storage} || []}) {
        _name(\%declared, $_->{name}) for @{$entry->{signals} || []};
    }
    _name(\%declared, $_->{name}) for @{$actor->{params} || []}, @{$actor->{constants} || []};
    for my $timing ($actor, @{($actor->{clock_domains} || {})->{domains} || []}) {
        _name(\%declared, $timing->{clock});
        _name(\%declared, $timing->{reset}{name}) if ref($timing->{reset}) eq 'HASH';
    }
    return {roots => $roots, aggregate_roots => \%aggregates,
        enum_exclusion_roots => \%exclusions, namespaces => \%namespaces,
        rule_declared_roots => \%declared};
}

sub record_reference_root_kind {
    my %args = @_;
    _arguments(\%args, [qw(context token)]);
    my ($context, $token) = @args{qw(context token)};
    _require(ref($context) eq 'HASH' && ref($context->{roots}) eq 'HASH'
        && ref($context->{namespaces}) eq 'HASH' && ref($context->{enum_exclusion_roots}) eq 'HASH',
        'reference classification requires declaration context');
    return undef unless defined($token) && !ref($token) && $token =~ /\A([A-Za-z_]\w*)(.*)\z/s;
    my ($root, $suffix) = ($1, $2);
    return 'namespace' if $suffix =~ /\A\./ && $context->{namespaces}{$root}
        && !$context->{enum_exclusion_roots}{$root};
    return undef unless exists $context->{roots}{$root};
    return 'declaration';
}

sub _name {
    my ($names, $name) = @_;
    $names->{$name} = 1 if defined($name) && !ref($name) && length($name);
}
sub _aggregate {
    my ($spec) = @_;
    return (ref($spec) eq 'HASH' && ($spec->{kind} eq 'record' || $spec->{kind} eq 'list')) ? 1 : 0;
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
    $entry = dclone($entry);
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
    my ($args, $keys, $optional) = @_;
    my %allowed = map { $_ => 1 } (@$keys, @{$optional || []});
    _require(!grep(!exists($args->{$_}), @$keys), 'missing scope argument');
    _require(!grep(!$allowed{$_}, keys %$args), 'unknown scope argument');
}
sub _require {
    confess "Invalid ISF declaration scope: validation requires a predicate and message\n" unless @_ == 2;
    confess "Invalid ISF declaration scope: $_[1]\n" unless $_[0];
}

1;
