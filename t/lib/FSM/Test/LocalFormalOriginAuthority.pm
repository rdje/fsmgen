package FSM::Test::LocalFormalOriginAuthority;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::Test::ConditionalOriginAuthority;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;

# Private qualification observer. All transformations remain canonical. Seed
# references come only from a complete independently supplied source authority;
# subsequent associations follow the references returned by the actual clones
# and resolver. Neither equal bodies nor physical signal names assign origin.
sub from_source {
    my ($class, $source, $label) = @_;
    my $authority = FSM::Test::ConditionalOriginAuthority->from_source($source, $label);
    my ($actor, $ledger) = ($authority->actor, $authority->ledger);
    confess "local formal origin residual normalization is not qualified\n"
        if @{$ledger->{residuals}};
    confess "local formal origin reusable/network scope is not qualified\n"
        if @{$actor->{library_uses} || []} || defined $actor->{actor_network}
            || keys %{$actor->{_atl_actor_type_resolutions} || {}};
    confess "local formal origin domain scope is not qualified\n"
        if defined $actor->{clock_domains}
            || grep {defined $_->{domain}} @{$actor->{transactions}};
    my $self = bless {associations => {}, held => [], resolved => {},
        source_actor => $actor, ledger => $ledger}, $class;
    for my $i (0 .. $#{$actor->{transactions}}) {
        $self->_register($actor->{transactions}[$i], {transaction => $i, lineage => []});
    }
    for my $i (0 .. $#{$ledger->{entries}}) {
        my $entry = $ledger->{entries}[$i];
        my $node = _at($actor, $entry->{path});
        confess "local formal origin authenticated path differs\n"
            unless $json->encode($node) eq $json->encode($entry->{target});
        $self->_register($node, {entry => $i, lineage => []});
    }
    my $before = $json->encode($actor);
    my $context = $self->_prepare($actor);
    confess "local formal origin requires an unprojected direct formal\n" unless $context;
    confess "local formal origin generated specialization is not qualified\n"
        if keys %{$context->{prepared}{generated_children}};
    confess "local formal origin source mutated during preparation\n"
        unless $json->encode($actor) eq $before;
    my @entries;
    for my $i (0 .. $#{$ledger->{entries}}) {
        my $record = $self->{resolved}{$i};
        confess "local formal origin final coverage missing entry $i\n" unless $record;
        my $actual = _at($context->{actor}, $record->{physical_path});
        confess "local formal origin final producer reference differs\n"
            unless ref($actual) && refaddr($actual) == refaddr($record->{returned});
        my %view = %$record;
        delete $view{returned};
        push @entries, \%view;
    }
    my $proof = {model => 'private_local_formal_origin_v1', source_ledger => $ledger,
        entries => \@entries};
    $self->{context_json} = $json->encode($context);
    $self->{proof_json} = $json->encode($proof);
    # The reference table is needed only while the real producers execute.
    delete @{$self}{qw(associations held resolved source_actor ledger current_transaction)};
    return $self;
}

sub _prepare {
    my ($self, $actor) = @_;
    my $clone = FSM::Scheduler::ISF::LoweringIR->can('_clone_isf_value');
    my $storable = \&FSM::Scheduler::ISF::FormalLowering::dclone;
    my $transaction = FSM::Scheduler::ISF::FormalClauseResolver->can('transaction');
    my $clause = FSM::Scheduler::ISF::FormalClauseResolver->can('_clause');
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::_clone_isf_value = sub {
        my ($old) = @_;
        my $new = $clone->(@_);
        $self->_carry_clone($old, $new, 'lowering_ir');
        return $new;
    };
    local *FSM::Scheduler::ISF::FormalLowering::dclone = sub {
        my ($old) = @_;
        my $new = $storable->(@_);
        $self->_pair_clone($old, $new);
        return $new;
    };
    local *FSM::Scheduler::ISF::FormalClauseResolver::transaction = sub {
        my ($producer, $tx, @args) = @_;
        my $association = $self->_association($tx);
        confess "local formal origin transaction clone association missing\n"
            unless $association && exists $association->{transaction};
        local $self->{current_transaction} = $association->{transaction};
        return $transaction->($producer, $tx, @args);
    };
    local *FSM::Scheduler::ISF::FormalClauseResolver::_clause = sub {
        my ($resolver, $node, $path) = @_;
        my $new = $clause->(@_);
        if (ref($node) eq 'ARRAY' && @$node && $node->[0] eq 'when') {
            $self->_resolved($resolver, $node, $new, $path);
        }
        return $new;
    };
    my $scheduler = FSM::Scheduler::ISF->new;
    return FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
}

sub _resolved {
    my ($self, $resolver, $node, $new, $path) = @_;
    my $association = $self->_association($node);
    confess "local formal origin conditional clone association missing\n"
        unless $association && exists $association->{entry};
    my $i = $association->{entry};
    confess "local formal origin duplicate resolver association\n" if exists $self->{resolved}{$i};
    my $ordinal = $self->{current_transaction};
    my $source = $self->{ledger}{entries}[$i];
    my $physical_path = ['transactions', $ordinal, @$path];
    confess "local formal origin source/resolver scope differs\n"
        unless $json->encode($physical_path) eq $json->encode($source->{path});
    my $owner = $self->{source_actor}{transactions}[$ordinal]{name};
    confess "local formal origin explicit resolver owner differs\n"
        unless $resolver->{operands}{transaction} eq $owner;
    my $plan = $resolver->{operands}{plan};
    $self->{resolved}{$i} = {
        source_entry => $i, source_path => _copy($source->{path}),
        origin => _copy($source->{origin}), transaction => $owner,
        physical_path => $physical_path, before => _copy($node), after => _copy($new),
        lineage => _copy($association->{lineage}),
        formals => _copy($plan->{formals}{$owner} || {}), returned => $new,
    };
    push @{$self->{held}}, $new;
}

sub _association {
    my ($self, $node) = @_;
    return ref($node) ? $self->{associations}{refaddr($node)} : undef;
}

sub _register {
    my ($self, $node, $association) = @_;
    confess "local formal origin producer returned a non-reference\n" unless ref($node);
    my $key = refaddr($node);
    confess "local formal origin producer association overwritten\n"
        if exists $self->{associations}{$key}
            && $json->encode($self->{associations}{$key}) ne $json->encode($association);
    $self->{associations}{$key} = _copy($association);
    push @{$self->{held}}, $node;
}

sub _carry_clone {
    my ($self, $old, $new, $stage) = @_;
    my $association = $self->_association($old) or return;
    confess "local formal origin canonical clone changed a producer value\n"
        unless $json->encode($old) eq $json->encode($new);
    my $next = _copy($association);
    push @{$next->{lineage}}, $stage;
    $self->_register($new, $next);
}

# Storable is a whole-object producer: pair only its actual input/output
# coordinates, after verifying complete clone equality. These coordinates
# transport an already authenticated association; they never create one.
sub _pair_clone {
    my ($self, $old, $new) = @_;
    confess "local formal origin canonical Storable clone changed a value\n"
        unless $json->encode($old) eq $json->encode($new);
    $self->_pair_clone_nodes($old, $new);
}

sub _pair_clone_nodes {
    my ($self, $old, $new) = @_;
    $self->_carry_clone($old, $new, 'storable');
    if (ref($old) eq 'HASH') {
        $self->_pair_clone_nodes($old->{$_}, $new->{$_}) for sort keys %$old;
    } elsif (ref($old) eq 'ARRAY') {
        $self->_pair_clone_nodes($old->[$_], $new->[$_]) for 0 .. $#$old;
    }
}

sub validate {
    my ($self, $context, $proof) = @_;
    $self->_authenticate($context, $proof);
    return 1;
}

sub _authenticate {
    my ($self, $context, $proof) = @_;
    confess "local formal origin context differs from authoritative source\n"
        unless $json->encode($context) eq $self->{context_json};
    confess "local formal origin proof differs from authoritative source\n"
        unless $json->encode($proof) eq $self->{proof_json};
}

sub context { $json->decode($_[0]{context_json}) }
sub proof { $json->decode($_[0]{proof_json}) }
sub _copy { $json->decode($json->encode($_[0])) }
sub _at {
    my ($value, $path) = @_;
    for my $part (@$path) {
        $value = ref($value) eq 'HASH' ? $value->{$part}
            : ref($value) eq 'ARRAY' ? $value->[$part] : undef;
    }
    return $value;
}

1;
