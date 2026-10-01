package FSM::Scheduler::ISF::PhysicalWriteDeclarations;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Package::AggregatePathSupport;
use FSM::Scheduler::ISF::PhysicalWriteTargets;

# Detached companion to Emitter::FSM::_emit_size. A known expression width is
# not necessarily an emitted declaration. Keep implicit targets visible for
# the subsequent inference/ownership pass instead of assigning guessed widths.
sub collect {
    my ($class, $ir) = @_;
    confess "Physical write declarations require a module IR\n"
        unless ref($ir) eq 'HASH' && _identifier($ir->{actor_name});
    my $module = $ir->{actor_name};
    my %declarations;
    my $types = _map($ir, 'signal_type_refs');
    my $add = sub {
        my ($name, $width, $origin, $entry) = @_;
        confess "Physical write declaration has an invalid signal name\n"
            unless _identifier($name);
        # Same precedence as emitted +size: ports, storage, counters, assembly.
        return if exists $declarations{$name};
        $entry ||= {};
        my $token = $entry->{type} // $types->{$name} // $width;
        # The emitter preserves actor-local and package-qualified type aliases.
        # Signal/module names remain bare identifiers; only the type token may
        # carry the single package qualifier accepted by the source resolver.
        confess "Physical write declaration '$name' has an invalid width token\n"
            unless defined($token) && !ref($token)
                && ($token =~ /\A[1-9][0-9]*\z/ || _identifier($token)
                    || $token =~ /\A[A-Za-z_]\w*\.[A-Za-z_]\w*\z/);
        my $declaration = {width => $width, width_token => $token, origin => $origin};
        $declaration->{type_spec} = FSM::Package::AggregatePathSupport->clone_structured_value($entry->{type_spec})
            if exists $entry->{type_spec};
        FSM::Scheduler::ISF::PhysicalWriteTargets->resolve($module, {$name => $declaration}, $name);
        $declarations{$name} = $declaration;
    };
    for my $port (@{_records($ir, 'ports')}) {
        $add->($port->{name}, $port->{width}, 'port', $port);
    }
    for my $storage (@{_records($ir, 'declared_storage')}) {
        for my $signal (@{_records($storage, 'signals')}) {
            $add->($signal->{name}, $signal->{width}, 'storage', $signal);
        }
    }
    my $counters = _map($ir, 'counters');
    $add->($_, $counters->{$_}, 'counter') for sort keys %$counters;
    my $widths = _map($ir, 'signal_widths');
    my %static = map {$_->{name} => 1}
        (@{_records($ir, 'constants')}, @{_records($ir, 'params')});
    for my $state (@{_records($ir, 'states')}) {
        my $names = $state->{assembly_signals} // [];
        confess "Physical write declarations require an assembly signal list\n"
            unless ref($names) eq 'ARRAY';
        for my $name (@$names) {
            next unless _identifier($name);
            next if exists($declarations{$name}) || $static{$name};
            next unless defined($widths->{$name}) && !ref($widths->{$name})
                && $widths->{$name} =~ /\A[1-9][0-9]*\z/;
            $add->($name, $widths->{$name}, 'assembly');
        }
    }
    my %unresolved;
    for my $container (@{_records($ir, 'states')}, @{_records($ir, 'dt_blocks')}) {
        for my $assignment (@{_records($container, 'assignments')}) {
            my $target = $assignment->{lhs};
            confess "Physical write declarations require scalar assignment targets\n"
                unless defined($target) && !ref($target) && $target =~ /\A([A-Za-z_]\w*)(.*)\z/;
            my $root = $1;
            if (exists $declarations{$root}) {
                FSM::Scheduler::ISF::PhysicalWriteTargets->resolve($module, \%declarations, $target);
            } else {
                $unresolved{$target} = {root => $root, target => $target};
            }
        }
    }
    return {module => $module, declarations => \%declarations,
        unresolved_targets => [map {$unresolved{$_}} sort keys %unresolved]};
}

# Return one detached overlap contract per actual assignment spelling. Explicit
# declarations provide packed ranges; an undeclared bare LHS covers its entire
# root without pretending that its downstream inferred width is known here.
sub target_contracts {
    my ($class, $ir) = @_;
    my $collection = $class->collect($ir);
    my %targets;
    for my $container (@{_records($ir, 'states')}, @{_records($ir, 'dt_blocks')}) {
        for my $assignment (@{_records($container, 'assignments')}) {
            my $target = $assignment->{lhs};
            next if exists $targets{$target};
            $target =~ /\A([A-Za-z_]\w*)/; # collect already validates every LHS.
            my $root = $1;
            $targets{$target} = exists($collection->{declarations}{$root})
                ? FSM::Scheduler::ISF::PhysicalWriteTargets->resolve(
                    $collection->{module}, $collection->{declarations}, $target)
                : FSM::Scheduler::ISF::PhysicalWriteTargets->whole_root($collection->{module}, $target);
        }
    }
    return \%targets;
}

sub _records {
    my ($record, $key) = @_;
    my $value = $record->{$key} // [];
    confess "Physical write declarations require '$key' records\n"
        unless ref($value) eq 'ARRAY' && !grep {ref($_) ne 'HASH'} @$value;
    return $value;
}
sub _map {
    my ($record, $key) = @_;
    my $value = $record->{$key} // {};
    confess "Physical write declarations require a '$key' map\n" unless ref($value) eq 'HASH';
    return $value;
}
sub _identifier {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/}

1;
