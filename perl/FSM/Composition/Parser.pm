package FSM::Composition::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::Instance;
use FSM::Composition::PortsBlock;
use FSM::Composition::TopLink;

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub parse_source ($self, $raw_ast) {
    my $top_ast = $self->find_top_root($raw_ast);
    confess "Expected composition source containing '?top:name'" unless $top_ast;

    my $top = $self->parse_top($top_ast);
    my $embedded_fsm_sources = $self->collect_embedded_fsm_sources($raw_ast);

    return FSM::Composition::Spec->new(
        top => $top,
        embedded_fsm_sources => $embedded_fsm_sources,
        raw_ast => $raw_ast,
    );
}

sub find_top_root ($self, $raw_ast) {
    return undef unless ref($raw_ast) eq 'ARRAY';

    if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?top:/) {
        return $raw_ast;
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        return $ast_node if $ast_node->[0] =~ /^\?top:/;
    }

    return undef;
}

sub parse_top ($self, $top_ast) {
    my ($header, $children) = @$top_ast;
    my ($top_name) = ($header // '') =~ /^\?top:(\w+)/;
    confess "Composition top root must be shaped like '?top:name'" unless $top_name;

    $children ||= [];
    confess "Composition top '$top_name' must contain a child list" unless ref($children) eq 'ARRAY';

    my @instances;
    my @ports_blocks;
    my @toplinks;
    my @inline_top_items;

    for my $child (@$children) {
        if (!ref($child)) {
            push @inline_top_items, $child;
            next;
        }

        confess "Composition top '$top_name' contains a non-list child item" unless ref($child) eq 'ARRAY';
        my ($kind, $parsed_child) = $self->parse_top_child($top_name, $child);

        if ($kind eq 'instance') {
            push @instances, $parsed_child;
        } elsif ($kind eq 'ports') {
            push @ports_blocks, $parsed_child;
        } elsif ($kind eq 'toplink') {
            push @toplinks, $parsed_child;
        } else {
            confess "Internal error: unknown parsed composition child kind '$kind'";
        }
    }

    if (@inline_top_items) {
        my $rendered = join ', ', @inline_top_items;
        confess
            "Composition top '$top_name' uses legacy inline top-port shorthand ($rendered), ".
            "but the active R6 composition parser only supports explicit '?ports' blocks";
    }

    return FSM::Composition::Top->new(
        name => $top_name,
        instances => \@instances,
        ports_blocks => \@ports_blocks,
        toplinks => \@toplinks,
        raw_ast => $top_ast,
    );
}

sub parse_top_child ($self, $top_name, $child_ast) {
    confess "Composition child in top '$top_name' is empty" unless @$child_ast;
    my $header = $child_ast->[0];
    confess "Composition child in top '$top_name' is missing a string header" if ref($header);

    my $items = $child_ast->[1] || [];
    confess "Composition child '$header' in top '$top_name' must contain an item list" unless ref($items) eq 'ARRAY';

    if ($header =~ /^\?fsmc(?::(\w*))?$/) {
        my $child_name = defined($1) && length($1) ? $1 : undef;
        return ('instance', $self->parse_fsmc_child($top_name, $child_ast, $child_name, $items));
    }
    if ($header =~ /^\?rtl:(\w+)$/) {
        return ('instance', FSM::Composition::Instance->new(
            kind => 'rtl',
            module_name => $1,
            raw_items => $items,
            raw_ast => $child_ast,
        ));
    }
    if ($header =~ /^\?ports(?::(\w*))?$/) {
        my $block_name = defined($1) && length($1) ? $1 : undef;
        return ('ports', FSM::Composition::PortsBlock->new(
            name => $block_name,
            raw_items => $items,
            raw_ast => $child_ast,
        ));
    }
    if ($header =~ /^\?toplink:(\w+)$/) {
        return ('toplink', FSM::Composition::TopLink->new(
            name => $1,
            raw_items => $items,
            raw_ast => $child_ast,
        ));
    }
    if ($header =~ /^\?top:/) {
        confess
            "Composition top '$top_name' contains nested top '$header', ".
            "but nested '?top:name' blocks are outside the first active R6 composition lane";
    }

    confess
        "Composition top '$top_name' contains unsupported child '$header'. ".
        "The active R6 parser currently accepts only '?fsmc', '?rtl', '?ports', and '?toplink'";
}

sub parse_fsmc_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " using nested option structures, but the first active R6 lane only supports a single FSM source name";
    }

    if (@scalar_items != 1) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " with $count FSM source names, but the first active R6 lane requires exactly one source name per '?fsmc'";
    }

    return FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => $child_name,
        source_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub collect_embedded_fsm_sources ($self, $raw_ast) {
    my %embedded_fsm_sources;
    return \%embedded_fsm_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        my ($fsm_name) = $ast_node->[0] =~ /^\?fsm:(\w+)/;
        next unless $fsm_name;
        $embedded_fsm_sources{$fsm_name} = $ast_node;
    }

    return \%embedded_fsm_sources;
}

1;
