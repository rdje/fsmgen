package FSM::Test::ConditionalOriginParser;

use v5.20;
use strict;
use warnings;
use parent 'FSM::Adapter::ISF::Parser';
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use Scalar::Util qw(refaddr);

# Detached observer of the real parser, never installed in the public adapter.
# References are held until freezing: a numeric refaddr must not be reused after
# a rewrite discards an old node. The serialized ledger contains no addresses.
my $json = JSON::PP->new->canonical;
my %conditional = map { $_ => 1 }
    qw(select min max cond when-bit unless-bit when-field unless-field);
my @rewrites = qw(_cond_rewrite_clause _let_rewrite_clause
    _expand_calls_in_clause _bit_test_rewrite_clause _when_field_rewrite_clause
    _compound_rewrite_clause _bit_op_rewrite_clause _set_field_rewrite_clause
    _rotate_rewrite_clause _swap_rewrite_clause _minmax_rewrite_clause
    _select_rewrite_clause _substitute_proc_body);

sub parse_source {
    my ($self, $text, $label) = @_;
    local $self->{origins} = {};
    local $self->{held_nodes} = [];
    local $self->{catalog} = [];
    local $self->{call_frames} = [];
    my $actor = $self->SUPER::parse_source($text, $label);
    my (@entries, @residuals);
    for my $i (0 .. $#{$actor->{transactions}}) {
        _walk($actor->{transactions}[$i]{clauses}, ['transactions', $i, 'clauses'], sub {
            my ($node, $path) = @_;
            my $op = $node->[0];
            return unless $op eq 'when' || $conditional{$op};
            my $origin = $self->{origins}{refaddr($node)};
            confess "conditional origin missing at " . $json->encode($path) . "\n"
                unless defined $origin;
            my $entry = {
                path => _copy($path), target => _copy($node),
                origin => _copy($origin),
            };
            push @{ $op eq 'when' ? \@entries : \@residuals }, $entry;
        });
    }
    $self->{ledger} = {
        schema_version => 1, actor_sha256 => sha256_hex($json->encode($actor)),
        source_sha256 => sha256_hex($text), catalog => _copy($self->{catalog}),
        entries => \@entries, residuals => \@residuals,
    };
    $self->validate($actor, $self->{ledger});
    return $actor;
}

sub ledger { return _copy($_[0]{ledger}) }

sub _expand_cond_loops {
    my ($self, $actor) = @_;
    for my $i (0 .. $#{$actor->{transactions}}) {
        my $tx = $actor->{transactions}[$i];
        $self->_seed($tx->{clauses}, ['transactions', $i, 'clauses'],
            { kind => 'transaction', name => $tx->{name} });
    }
    for my $name (sort keys %{$actor->{procs} || {}}) {
        $self->_seed($actor->{procs}{$name}{body}, ['procs', $name, 'body'],
            { kind => 'procedure', name => $name });
    }
    return $self->SUPER::_expand_cond_loops($actor);
}

sub _seed {
    my ($self, $clauses, $path, $owner) = @_;
    _walk($clauses, $path, sub {
        my ($node, $node_path) = @_;
        my $op = $node->[0];
        return unless $op eq 'when' || $op eq 'call' || $conditional{$op};
        my $id = scalar @{$self->{catalog}};
        push @{$self->{catalog}}, {
            owner => _copy($owner), path => _copy($node_path),
            operation => $op, source_form => _copy($node),
        };
        $self->_register($node, { catalog_id => $id, calls => [], branch_ordinal => undef });
    });
}

sub _register {
    my ($self, $node, $origin) = @_;
    confess "conditional origin target must be an array\n" unless ref($node) eq 'ARRAY';
    my $key = refaddr($node);
    if (exists $self->{origins}{$key}) {
        confess "conditional origin association was overwritten\n"
            unless $json->encode($self->{origins}{$key}) eq $json->encode($origin);
        return $node;
    }
    $self->{origins}{$key} = _copy($origin);
    push @{$self->{held_nodes}}, $node;
    return $node;
}

sub _carry {
    my ($self, $old, $new, $substitution) = @_;
    return $new unless ref($old) eq 'ARRAY' && ref($new) eq 'ARRAY';
    my $origin = $self->{origins}{refaddr($old)};
    return $new unless defined $origin;
    return $new if refaddr($old) == refaddr($new);
    $origin = _copy($origin);
    # Only substitution copies a definition into a call. Ordinary rewrites must
    # preserve that already explicit call chain rather than append it again.
    $origin->{calls} = _copy($self->{call_frames})
        if $substitution && @{$self->{call_frames}};
    return $self->_register($new, $origin);
}

sub _expand_one_call {
    my ($self, $clause, $procs, $stack, $ctx) = @_;
    my $origin = $self->{origins}{refaddr($clause)};
    confess "conditional origin call association missing\n" unless defined $origin;
    local $self->{call_frames} = [ @{$self->{call_frames}}, {
        catalog_id => $origin->{catalog_id}, procedure => $clause->[1], context => $ctx,
    } ];
    return $self->SUPER::_expand_one_call($clause, $procs, $stack, $ctx);
}

sub _for_rewrite_clause {
    my ($self, $old, @args) = @_;
    my ($new, $hoisted) = $self->SUPER::_for_rewrite_clause($old, @args);
    return ($self->_carry($old, $new, 0), $hoisted);
}

# The wrappers execute the canonical producers; no copied desugaring algorithm
# or clause-shape matching decides origin. Each method explicitly transports
# the old node's association to the new root it actually produced.
{
    no strict 'refs';
    for my $method (@rewrites) {
        my $producer = FSM::Adapter::ISF::Parser->can($method)
            or die "missing canonical parser rewrite $method";
        *{__PACKAGE__ . "::$method"} = sub {
            my ($self, $old, @args) = @_;
            my $new = $producer->($self, $old, @args);
            return $self->_carry($old, $new, $method eq '_substitute_proc_body');
        };
    }
    for my $method (qw(_desugar_cond _desugar_select _desugar_minmax
            _desugar_bit_test _desugar_when_field)) {
        my $producer = FSM::Adapter::ISF::Parser->can($method)
            or die "missing canonical parser producer $method";
        *{__PACKAGE__ . "::$method"} = sub {
            my ($self, $old, @args) = @_;
            my $result = $producer->($self, $old, @args);
            my $origin = $self->{origins}{refaddr($old)};
            confess "conditional origin producer association missing for $method\n"
                unless defined $origin;
            my @nodes = $method eq '_desugar_cond' || $method eq '_desugar_select'
                ? @$result : ($result);
            for my $i (0 .. $#nodes) {
                my $copy = _copy($origin);
                $copy->{branch_ordinal} = $i unless $method eq '_desugar_minmax';
                $self->_register($nodes[$i], $copy);
            }
            return $result;
        };
    }
}

sub validate {
    my ($self, $actor, $ledger) = @_;
    _keys($ledger, qw(schema_version actor_sha256 source_sha256 catalog entries residuals));
    my $submitted = $json->encode($ledger);
    confess "conditional origin schema mismatch\n"
        unless $json->encode([$ledger->{schema_version}]) eq '[1]';
    confess "conditional origin actor identity mismatch\n"
        unless $ledger->{actor_sha256} eq sha256_hex($json->encode($actor));
    confess "conditional origin source identity mismatch\n"
        unless defined($ledger->{source_sha256}) && !ref($ledger->{source_sha256})
            && $ledger->{source_sha256} =~ /\A[0-9a-f]{64}\z/;
    for my $key (qw(catalog entries residuals)) {
        confess "conditional origin $key must be an array\n" unless ref($ledger->{$key}) eq 'ARRAY';
    }
    for my $record (@{$ledger->{catalog}}) {
        _keys($record, qw(owner path operation source_form));
        _keys($record->{owner}, qw(kind name));
        confess "conditional origin invalid owner\n"
            unless ($record->{owner}{kind} // '') =~ /\A(?:transaction|procedure)\z/
                && defined($record->{owner}{name}) && !ref($record->{owner}{name});
        confess "conditional origin invalid original operation\n"
            unless defined($record->{operation}) && !ref($record->{operation})
                && ($record->{operation} eq 'when' || $record->{operation} eq 'call'
                    || $conditional{$record->{operation}})
                && ref($record->{source_form}) eq 'ARRAY'
                && ($record->{source_form}[0] // '') eq $record->{operation};
        _path($record->{path});
    }
    my %wanted;
    for my $i (0 .. $#{$actor->{transactions}}) {
        _walk($actor->{transactions}[$i]{clauses}, ['transactions', $i, 'clauses'], sub {
            my ($node, $path) = @_;
            $wanted{$json->encode($path)} = $node
                if $node->[0] eq 'when' || $conditional{$node->[0]};
        });
    }
    for my $group (qw(entries residuals)) {
        for my $entry (@{$ledger->{$group}}) {
            _keys($entry, qw(path target origin));
            _path($entry->{path});
            my $target = delete $wanted{$json->encode($entry->{path})};
            confess "conditional origin missing, extra or duplicate path\n" unless defined $target;
            confess "conditional origin target identity mismatch\n"
                unless $json->encode($entry->{target}) eq $json->encode($target);
            confess "conditional origin wrong target category\n"
                unless ($group eq 'entries') == ($target->[0] eq 'when');
            my $origin = $entry->{origin};
            _keys($origin, qw(catalog_id calls branch_ordinal));
            my $id = $origin->{catalog_id};
            confess "conditional origin invalid catalog reference\n"
                unless _index($id) && $id < @{$ledger->{catalog}};
            my $op = $ledger->{catalog}[$id]{operation};
            confess "conditional origin invalid association\n"
                unless $target->[0] eq 'when' ? ($op eq 'when' || $conditional{$op})
                    : $op eq $target->[0];
            confess "conditional origin invalid branch ordinal\n"
                unless $op eq 'when' || $group eq 'residuals'
                    ? !defined($origin->{branch_ordinal}) : _index($origin->{branch_ordinal});
            confess "conditional origin calls must be an array\n" unless ref($origin->{calls}) eq 'ARRAY';
            for my $frame (@{$origin->{calls}}) {
                _keys($frame, qw(catalog_id procedure context));
                my $call_id = $frame->{catalog_id};
                confess "conditional origin invalid call association\n"
                    unless _index($call_id) && $call_id < @{$ledger->{catalog}}
                        && $ledger->{catalog}[$call_id]{operation} eq 'call'
                        && defined($frame->{procedure}) && !ref($frame->{procedure})
                        && ($ledger->{catalog}[$call_id]{source_form}[1] // '') eq $frame->{procedure}
                        && defined($frame->{context}) && !ref($frame->{context});
            }
        }
    }
    confess "conditional origin incomplete coverage\n" if keys %wanted;
    # A detached parser instance retains its trusted producer result. The
    # consumer contract for independently loaded ledgers is deliberately not
    # adopted here: .5.2.2 must earn its source/preparation authenticity route.
    confess "conditional origin differs from the actual producer result\n"
        if defined($self->{ledger}) && $submitted ne $json->encode($self->{ledger});
    return 1;
}

sub _walk {
    my ($clauses, $path, $visit) = @_;
    return unless ref($clauses) eq 'ARRAY';
    for my $i (0 .. $#$clauses) {
        my $node = $clauses->[$i];
        next unless ref($node) eq 'ARRAY' && @$node && defined($node->[0]) && !ref($node->[0]);
        _walk_node($node, [@$path, $i], $visit);
    }
}

sub _walk_node {
    my ($node, $path, $visit) = @_;
    return unless ref($node) eq 'ARRAY' && @$node && defined($node->[0]) && !ref($node->[0]);
    $visit->($node, $path);
    my $op = $node->[0];
    my $start = $op =~ /\A(?:when|while|until|repeat|for)\z/ ? 2
        : $op =~ /\A(?:when-bit|unless-bit)\z/ ? 3
        : $op =~ /\A(?:when-field|unless-field)\z/ ? 4 : undef;
    if (defined $start) {
        _walk_node($node->[$_], [@$path, $_], $visit) for $start .. $#$node;
    } elsif ($op eq 'cond' || $op eq 'switch') {
        my $first = $op eq 'cond' ? 1 : 2;
        for my $i ($first .. $#$node) {
            my $branch = $node->[$i];
            next unless ref($branch) eq 'ARRAY';
            _walk_node($branch->[$_], [@$path, $i, $_], $visit) for 1 .. $#$branch;
        }
    }
}

sub _copy {
    my ($node) = @_;
    return [map {_copy($_)} @$node] if ref($node) eq 'ARRAY';
    return {map {$_ => _copy($node->{$_})} keys %$node} if ref($node) eq 'HASH';
    confess "conditional origin unsupported reference\n" if ref($node);
    return $node;
}
sub _keys {
    my ($value, @keys) = @_;
    confess "conditional origin malformed record\n" unless ref($value) eq 'HASH';
    confess "conditional origin unknown or missing fields\n"
        unless join("\0", sort keys %$value) eq join("\0", sort @keys);
}
sub _index { defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/ }
sub _path {
    my ($path) = @_;
    confess "conditional origin invalid path\n"
        unless ref($path) eq 'ARRAY' && @$path
            && !grep {!defined($_) || ref($_) || !length($_)} @$path;
}

1;
