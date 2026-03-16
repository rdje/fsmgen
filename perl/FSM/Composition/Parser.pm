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
use FSM::Composition::Port;
use FSM::Composition::Link;
use FSM::Composition::PortsBlock;
use FSM::Composition::TopLink;

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub scope_docs_suffix ($self) {
    return " See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md";
}

sub parse_source ($self, $raw_ast) {
    my $top_ast = $self->find_top_root($raw_ast);
    confess "Expected composition source containing '?top:name'" unless $top_ast;

    my $top = $self->parse_top($top_ast);
    my $embedded_fsm_sources = $self->collect_embedded_fsm_sources($raw_ast);
    my $embedded_dt_sources = $self->collect_embedded_dt_sources($raw_ast);

    return FSM::Composition::Spec->new(
        top => $top,
        embedded_fsm_sources => $embedded_fsm_sources,
        embedded_dt_sources => $embedded_dt_sources,
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
    my $top_name = $self->decode_top_name($header);

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
            "but the active R6 composition parser only supports explicit '?ports' blocks.".
            $self->scope_docs_suffix;
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
    if ($header =~ /^\?dtc(?::(\w*))?$/) {
        my $child_name = defined($1) && length($1) ? $1 : undef;
        return ('instance', $self->parse_dtc_child($top_name, $child_ast, $child_name, $items));
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
        return ('ports', $self->parse_ports_block($top_name, $child_ast, $block_name, $items));
    }
    if ($header =~ /^\?toplink:(\w+)$/) {
        return ('toplink', $self->parse_toplink_block($top_name, $child_ast, $1, $items));
    }
    if ($header =~ /^\?&/) {
        confess
            "Composition top '$top_name' contains legacy macro/plugin child '$header', ".
            "but macro/plugin-oriented composition constructs are outside the active R6 composition scope.".
            $self->scope_docs_suffix;
    }
    if ($header =~ /^\?top:/) {
        confess
            "Composition top '$top_name' contains nested top '$header', ".
            "but nested '?top:name' blocks are outside the first active R6 composition lane.".
            $self->scope_docs_suffix;
    }

    confess
        "Composition top '$top_name' contains unsupported child '$header'. ".
        "The active R6 parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', and '?toplink'.".
        $self->scope_docs_suffix;
}

sub parse_fsmc_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " using nested option structures, but the first active R6 lane only supports a single FSM source name.".
            $self->scope_docs_suffix;
    }

    if (@scalar_items != 1) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " with $count FSM source names, but the first active R6 lane requires exactly one source name per '?fsmc'.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => $child_name,
        source_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub parse_dtc_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?dtc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " using nested option structures, but the active generated-child lane only supports a single standalone-DT source name.".
            $self->scope_docs_suffix;
    }

    if (@scalar_items != 1) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?dtc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " with $count standalone-DT source names, but the active generated-child lane requires exactly one source name per '?dtc'.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Instance->new(
        kind => 'dtc',
        name => $child_name,
        source_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub parse_ports_block ($self, $top_name, $child_ast, $block_name, $items) {
    my @ports;

    for my $item (@$items) {
        confess "Composition top '$top_name' contains a nested '?ports' item, but the first active R6 lane only supports flat explicit port tokens.".
            $self->scope_docs_suffix
            if ref($item);

        if ($item =~ m{^/} || $item =~ /^\{/) {
            confess
                "Composition top '$top_name' contains '?ports' mapping directive '$item', ".
                "but the first active R6 realization lane only supports explicit top-port declarations inside '?ports'.".
                $self->scope_docs_suffix;
        }

        push @ports, $self->parse_port_token($top_name, $item);
    }

    return FSM::Composition::PortsBlock->new(
        name => $block_name,
        ports => \@ports,
        raw_ast => $child_ast,
    );
}

sub parse_port_token ($self, $top_name, $token) {
    $token =~ /^(?<binding>=)?(?<port>\w+)(?:(?<direction>[<>])(?<size>\d+)?(?:[:](?<type>\w+))?)?$/o;
    my ($binding, $port, $direction, $size, $type) = @+{qw/binding port direction size type/};

    confess "Composition top '$top_name' contains invalid '?ports' token '$token'.".$self->scope_docs_suffix unless $port;
    confess "Composition top '$top_name' contains non-positive port width in token '$token'.".$self->scope_docs_suffix if defined($size) && $size < 1;

    return FSM::Composition::Port->new(
        name => $port,
        direction => defined($direction) ? ($direction eq '<' ? 'input' : 'output') : 'input',
        width => $size // 1,
        type => $type,
        binding_mode => defined($binding) ? 'connect_by_name' : 'explicit',
        raw_token => $token,
    );
}

sub parse_toplink_block ($self, $top_name, $child_ast, $block_name, $items) {
    my @links;

    for my $item (@$items) {
        confess "Composition top '$top_name' contains a nested '?toplink' item, but the first active R6 lane only supports flat '/source/target/' link tokens.".
            $self->scope_docs_suffix
            if ref($item);

        if ($item =~ m{^/([^/]+)/([^/]+)/$}) {
            push @links, FSM::Composition::Link->new(
                source => $1,
                target => $2,
                raw_token => $item,
            );
            next;
        }

        confess
            "Composition top '$top_name' contains unsupported '?toplink' token '$item'. ".
            "The current parser only accepts simple '/source/target/' link forms.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::TopLink->new(
        name => $block_name,
        links => \@links,
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
        next unless $ast_node->[0] =~ /^\?fsm:/;
        my $fsm_name = $self->decode_embedded_fsm_source_name($ast_node->[0]);
        next unless $fsm_name;
        $embedded_fsm_sources{$fsm_name} = $ast_node;
    }

    return \%embedded_fsm_sources;
}

sub collect_embedded_dt_sources ($self, $raw_ast) {
    my %embedded_dt_sources;
    return \%embedded_dt_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] =~ /^\?dt:/;
        my $dt_name = $self->decode_embedded_dt_source_name($ast_node->[0]);
        next unless $dt_name;
        $embedded_dt_sources{$dt_name} = $ast_node;
    }

    return \%embedded_dt_sources;
}

sub decode_top_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?top:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed composition top root '$display'. ".
        "The active contract expects '?top:top_name' with an HDL-identifier-compatible top name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub decode_embedded_fsm_source_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?fsm:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed embedded FSM source '$display'. ".
        "The active composition contract expects embedded child sources shaped like '?fsm:source_name' with an HDL-identifier-compatible source name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub decode_embedded_dt_source_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?dt:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed embedded DT source '$display'. ".
        "The active composition contract expects embedded standalone-DT child sources shaped like '?dt:source_name' with an HDL-identifier-compatible source name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

1;
