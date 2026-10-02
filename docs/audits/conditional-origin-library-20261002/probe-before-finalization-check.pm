package FSM::Test::SameSourceLibraryOriginParser;

use v5.20;
use strict;
use warnings;
use parent 'FSM::Test::ConditionalOriginParser';
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP;
use Scalar::Util qw(refaddr);

my $json = JSON::PP->new->canonical;
my %conditional = map {$_ => 1} qw(select min max cond when-bit unless-bit when-field unless-field);

# Detached producer observer. Each actual _build_actor gets its own origin
# registry. Canonical library export references select the source product;
# canonical use metadata selects the export, and the actual clone must be exact.
sub parse_source {
    my ($self, $source, $label) = @_;
    confess "library origin requires a repository-relative source label\n"
        unless defined($label) && !ref($label) && length($label)
            && !File::Spec->file_name_is_absolute($label)
            && !grep {$_ eq '..'} File::Spec->splitdir($label);
    local $self->{source_text} = $source;
    local $self->{source_label} = $label;
    local $self->{actor_products} = [];
    local $self->{actor_refs} = {};
    local $self->{held_actors} = [];
    local $self->{libraries} = [];
    local $self->{exports} = {};
    local $self->{use_edges} = [];
    local $self->{library_name} = undef;
    my $actor = FSM::Adapter::ISF::Parser::parse_source($self, $source, $label);
    my $root_id = $self->{actor_refs}{refaddr($actor)};
    confess "library origin root producer is missing\n" unless defined $root_id;
    my $root = $self->{actor_products}[$root_id];
    # Canonical source finalization follows library resolution. It may annotate
    # the root shell, but must preserve the explicitly produced clause targets.
    $root->{actor} = _copy($actor);
    $root->{ledger}{actor_sha256} = sha256_hex($json->encode($actor));
    $self->{proof} = {
        schema_version => 1, source_label => $label, source_sha256 => sha256_hex($source),
        actor_sha256 => sha256_hex($json->encode($actor)), root_actor_id => $root_id,
        actors => _copy($self->{actor_products}), libraries => _copy($self->{libraries}),
        uses => _copy($self->{use_edges}),
    };
    return $actor;
}

sub proof {return _copy($_[0]{proof})}

sub _build_actor {
    my ($self, $form, $label) = @_;
    local $self->{origins} = {};
    local $self->{held_nodes} = [];
    local $self->{catalog} = [];
    local $self->{call_frames} = [];
    local $self->{ledger} = undef;
    my $actor = $self->SUPER::_build_actor($form, $label);
    my (@entries, @residuals);
    for my $i (0 .. $#{$actor->{transactions}}) {
        FSM::Test::ConditionalOriginParser::_walk($actor->{transactions}[$i]{clauses},
            ['transactions', $i, 'clauses'], sub {
                my ($node, $path) = @_;
                return unless $node->[0] eq 'when' || $conditional{$node->[0]};
                my $origin = $self->{origins}{refaddr($node)};
                confess "library conditional origin association missing\n" unless defined $origin;
                push @{$node->[0] eq 'when' ? \@entries : \@residuals},
                    {path => _copy($path), target => _copy($node), origin => _copy($origin)};
            });
    }
    my $ledger = {
        schema_version => 1, source_sha256 => sha256_hex($self->{source_text}),
        actor_sha256 => sha256_hex($json->encode($actor)), catalog => _copy($self->{catalog}),
        entries => \@entries, residuals => \@residuals,
    };
    $self->validate($actor, $ledger);
    my $id = @{$self->{actor_products}};
    $self->{actor_refs}{refaddr($actor)} = $id;
    push @{$self->{held_actors}}, $actor;
    push @{$self->{actor_products}}, {
        actor_id => $id, source_label => $label, library => $self->{library_name},
        actor_name => $form->[1], actor => _copy($actor), ledger => $ledger,
    };
    return $actor;
}

sub _parse_imports {
    my ($self, @args) = @_;
    my $imports = $self->SUPER::_parse_imports(@args);
    confess "library origin package source authority is not qualified\n"
        if @{$imports->{packages}};
    return $imports;
}

sub _parse_library_form {
    my ($self, $form, $label) = @_;
    confess "library origin external document authority is not qualified\n"
        unless $label eq $self->{source_label};
    local $self->{library_name} = $form->[1];
    my $library = $self->SUPER::_parse_library_form($form, $label);
    my %exports;
    for my $name (sort keys %{$library->{exports}{actor}}) {
        my $id = $self->{actor_refs}{refaddr($library->{exports}{actor}{$name})};
        confess "library origin export producer is missing\n" unless defined $id;
        $exports{$name} = $id;
        $self->{exports}{$library->{name}}{$name} = $id;
    }
    push @{$self->{libraries}}, {name => $library->{name}, source_label => $label, exports => \%exports};
    return $library;
}

sub _resolve_library {
    my ($self, $name, $same_source, @args) = @_;
    confess "library origin external document authority is not qualified\n"
        unless exists $same_source->{$name};
    return $self->SUPER::_resolve_library($name, $same_source, @args);
}

sub _resolve_library_uses {
    my ($self, $actor, @args) = @_;
    my $result = $self->SUPER::_resolve_library_uses($actor, @args);
    for my $i (0 .. $#{$actor->{library_uses}}) {
        my $use = $actor->{library_uses}[$i];
        my $id = $self->{exports}{$use->{library}}{$use->{export}};
        confess "library origin selected export association missing\n" unless defined $id;
        my $produced = $self->{actor_products}[$id];
        confess "library origin canonical export clone differs\n"
            unless $json->encode($use->{actor}) eq $json->encode($produced->{actor});
        push @{$self->{use_edges}}, {
            path => ['library_uses', $i, 'actor'], actor_id => $id,
            library => $use->{library}, source_label => $use->{library_source},
            export => $use->{export}, alias => $use->{alias}, instance => $use->{instance},
            module => $use->{module}, bindings => _copy($use->{bindings}),
            parameter_overrides => _copy($use->{parameter_overrides}),
            target => _copy($use->{actor}), ledger => _copy($produced->{ledger}),
        };
    }
    return $result;
}

sub _resolve_atl_actor_type_metadata {
    my ($self, $actor, @args) = @_;
    confess "library origin ATL source authority is not qualified\n" if defined $actor->{actor_network};
    return $self->SUPER::_resolve_atl_actor_type_metadata($actor, @args);
}

sub _copy {FSM::Test::ConditionalOriginParser::_copy($_[0])}

1;
