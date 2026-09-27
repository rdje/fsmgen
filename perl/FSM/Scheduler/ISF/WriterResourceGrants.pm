package FSM::Scheduler::ISF::WriterResourceGrants;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Scheduler::ISF::SourceWriterOwners;

# Detached declaration/producer correspondence, not an arbitration proof.
# In particular, a round-robin "higher" list names peers, not fixed winners.
sub collect {
    my ($class, $ir, $actor) = @_;
    _require(ref($ir) eq 'HASH' && ref($actor) eq 'HASH', 'requires a module and actor');
    _require(_text($ir->{actor_name}) && _text($actor->{actor_name})
        && $ir->{actor_name} eq $actor->{actor_name}, 'requires matching module and actor identities');
    _require((($ir->{domain_partition} || {})->{kind} // '') ne 'multi_domain',
        'requires an actual clock-domain module');
    my $arbitration = $ir->{resource_arbitration};
    _keys($arbitration, [qw(grants issues)], 'module arbitration');
    _require(ref($arbitration->{grants}) eq 'ARRAY' && ref($arbitration->{issues}) eq 'ARRAY'
        && !@{$arbitration->{issues}}, 'requires complete successful arbitration records');
    _require(ref($ir->{dt_blocks}) eq 'ARRAY', 'requires explicit DT records');
    my $resources = $actor->{resources} // [];
    _require(ref($resources) eq 'ARRAY', 'requires resource declarations');

    my (%declarations, %expected, %owners, %mirrors);
    for my $resource (@$resources) {
        _require(ref($resource) eq 'HASH' && _text($resource->{name}), 'has an unnamed resource declaration');
        my $name = $resource->{name};
        _require(!exists($declarations{$name}), 'has duplicate resource declarations');
        $declarations{$name} = $resource;
        my $users = _names($resource->{users} // [], 'declared resource users');
        next unless @$users;  # Unbound declarations have no executable grant.
        _require(_text($resource->{kind}) && $resource->{kind} =~ /\A(?:rule_slot|output_bundle|transaction_start|storage_port)\z/
            && _text($resource->{arbiter}) && $resource->{arbiter} =~ /\A(?:priority|round_robin)\z/,
            'has an unsupported bound resource policy');
        _names($resource->{members} // [], 'declared resource members');
        $expected{$name}{$_} = 1 for @$users;
    }
    for my $dt (@{$ir->{dt_blocks}}) {
        _require(ref($dt) eq 'HASH', 'requires structured DT records');
        if (($dt->{kind} // '') ne 'rule') {
            _require(!exists($dt->{resource_grants}), 'has grants on a non-rule DT');
            next;
        }
        my $owner = FSM::Scheduler::ISF::SourceWriterOwners->resolve($ir, $actor, 'dt', $dt);
        my $user = $owner->{source_name};
        _require(!exists($owners{$user}), 'has duplicate rule DT ownership');
        $owners{$user} = $owner;
        my $grants = $dt->{resource_grants} // [];
        _require(ref($grants) eq 'ARRAY', 'requires DT grant arrays');
        for my $grant (@$grants) {
            _keys($grant, [qw(resource higher)], 'DT grant');
            _require(_text($grant->{resource}), 'has an unnamed DT grant');
            my $name = $grant->{resource};
            _names($grant->{higher}, 'DT suppressor names');
            _require(exists($expected{$name}) && exists($expected{$name}{$user}),
                'has an undeclared DT grant');
            _require(!exists($mirrors{$user}{$name}), 'has duplicate DT grants');
            $mirrors{$user}{$name} = $grant;
        }
    }

    my (%seen, @records);
    for my $grant (@{$arbitration->{grants}}) {
        _keys($grant, [qw(resource kind arbiter user higher members)], 'module grant');
        _require(!(grep {!_text($grant->{$_})} qw(resource kind arbiter user)), 'has an incomplete module grant');
        my ($name, $user) = @{$grant}{qw(resource user)};
        _require(exists($expected{$name}) && exists($expected{$name}{$user}), 'has an undeclared module grant');
        _require(!$seen{$name}{$user}++, 'has duplicate module grants');
        _require(exists($owners{$user}), 'has a grant without its rule DT');
        my $resource = $declarations{$name};
        _require($grant->{kind} eq $resource->{kind} && $grant->{arbiter} eq $resource->{arbiter},
            'has a grant policy inconsistent with its declaration');
        my $members = _names($grant->{members}, 'module grant members');
        _same_names($members, $resource->{members} // [], 'has inconsistent resource members');
        my $higher = _names($grant->{higher}, 'module suppressor names');
        _require(!(grep {$_ eq $user || !exists($expected{$name}{$_})} @$higher),
            'has unknown or self suppressors');
        if ($grant->{arbiter} eq 'round_robin') {
            _same_names($higher, [grep {$_ ne $user} @{$resource->{users}}], 'has incomplete round-robin peers');
        } else {
            _same_names($higher, [sort @$higher], 'has noncanonical priority suppressor ordering');
        }
        my $mirror = $mirrors{$user}{$name};
        _require(defined($mirror), 'has a missing DT grant mirror');
        _same_names($higher, $mirror->{higher}, 'has inconsistent DT suppressor names');
        push @records, {
            map({$_ => $grant->{$_}} qw(resource kind arbiter user)),
            higher => [@$higher], members => [@$members],
            source_owner => {%{$owners{$user}}},
        };
    }
    for my $name (keys %expected) {
        for my $user (keys %{$expected{$name}}) {
            _require($seen{$name}{$user}, 'has a missing declared resource/user grant');
        }
    }
    return \@records;
}

sub _keys {
    my ($record, $keys, $label) = @_;
    _require(ref($record) eq 'HASH' && join(',', sort keys %$record) eq join(',', sort @$keys),
        "has malformed $label fields");
}

sub _names {
    my ($names, $label) = @_;
    _require(ref($names) eq 'ARRAY', "requires $label as an array");
    my %seen;
    _require(!(grep {!_text($_) || $seen{$_}++} @$names), "has invalid or duplicate $label");
    return $names;
}

sub _same_names {
    my ($left, $right, $message) = @_;
    _require(@$left == @$right && !(grep {$left->[$_] ne $right->[$_]} 0 .. $#$left), $message);
}

sub _text { defined($_[0]) && !ref($_[0]) && length($_[0]) }
sub _require { confess "Writer resource grants $_[1]\n" unless $_[0] }

1;
