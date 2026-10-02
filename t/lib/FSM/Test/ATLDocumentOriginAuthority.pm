package FSM::Test::ATLDocumentOriginAuthority;

use v5.20;
use strict;
use warnings;
use parent 'FSM::Test::LibraryDocumentOriginAuthority';
use Carp qw(confess);
use JSON::PP;

my $json = JSON::PP->new->canonical;

# Keep the qualified library-only provider immutable. This distinct observer
# adds only exact canonical resolved-static ATL producer and clone provenance.
sub from_documents {
    my ($class, $label, $documents, $search_roots) = @_;
    confess "ATL origin independent document set required\n"
        unless ref($documents) eq 'HASH' && exists $documents->{$label // ''} && ref($search_roots) eq 'ARRAY';
    FSM::Test::LibraryDocumentOriginAuthority::_relative($_) for $label, keys %$documents, @$search_roots;
    for my $source (values %$documents) {
        confess "ATL origin complete source bytes required\n"
            unless defined($source) && !ref($source) && length($source);
    }
    my $snapshot = $json->decode($json->encode($documents));
    local $ENV{FSMLIB} = join ':', @$search_roots;
    my $parser = FSM::Test::ATLDocumentOriginAuthority::Parser->new;
    my $actor = $parser->parse_documents($label, $snapshot);
    return bless {actor_json => $json->encode($actor), proof_json => $json->encode($parser->proof)}, $class;
}

package FSM::Test::ATLDocumentOriginAuthority::Parser;
use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
use Carp qw(confess);

sub parse_documents {
    my ($self, @args) = @_;
    local $self->{atl_edges} = [];
    local $self->{atl_resolutions} = [];
    my $actor = $self->SUPER::parse_documents(@args);
    my $resolutions = $actor->{_atl_actor_type_resolutions} || {};
    confess "ATL origin final resolved actor coverage differs\n"
        unless $json->encode([sort keys %$resolutions]) eq $json->encode([sort map {$_->{instance}} @{$self->{atl_edges}}]);
    for my $edge (@{$self->{atl_edges}}) {
        my $current = $resolutions->{$edge->{instance}};
        my $instance = $actor->{actor_network}{instances}[$edge->{instance_ordinal}];
        confess "ATL origin final target or instance identity differs\n"
            unless $current && $instance
                && $json->encode($current) eq $json->encode($edge->{resolution})
                && $json->encode($instance) eq $json->encode($edge->{declaration});
    }
    $self->{proof}{atl} = FSM::Test::ConditionalOriginParser::_copy($self->{atl_edges});
    $self->{proof}{atl_resolutions} = FSM::Test::ConditionalOriginParser::_copy($self->{atl_resolutions});
    return $actor;
}

sub _resolve_atl_actor_type_metadata {
    my ($self, $actor, @args) = @_;
    local $self->{resolution_records} = [];
    my $network = $actor->{actor_network} || {};
    confess "ATL origin group source authority is not qualified\n"
        if @{$network->{groups} || []};
    my $result = FSM::Adapter::ISF::Parser::_resolve_atl_actor_type_metadata($self, $actor, @args);
    my %by_alias;
    for my $i (0 .. $#{$self->{resolution_records}}) {
        my $record = $self->{resolution_records}[$i];
        my $import = $actor->{imports}[$i];
        confess "ATL origin declared import association differs\n"
            unless $import && $import->{library} eq $record->{library};
        $record->{alias} = $import->{alias};
        $by_alias{$record->{alias}} = $record;
        push @{$self->{atl_resolutions}}, $record;
    }
    my $instances = $network->{instances} || [];
    for my $i (0 .. $#$instances) {
        my $instance = $instances->[$i];
        confess "ATL origin unresolved external actor authority is not qualified\n"
            unless ($instance->{type_resolution} || '') eq 'library_actor_export';
        my $resolved = $actor->{_atl_actor_type_resolutions}{$instance->{name}};
        my $selected = $by_alias{$instance->{alias}};
        my $id = $selected ? $selected->{exports}{$instance->{export}} : undef;
        confess "ATL origin exact selected export association missing\n" unless defined $id;
        my $producer = $self->{actor_products}[$id];
        confess "ATL origin selected clone or source differs\n"
            unless $resolved && $selected->{library} eq $resolved->{library}
                && $selected->{source_label} eq $resolved->{library_source}
                && $json->encode($producer->{actor}) eq $json->encode($resolved->{actor});
        push @{$self->{atl_edges}}, {
            path => ['_atl_actor_type_resolutions', $instance->{name}, 'actor'],
            actor_id => $id, instance => $instance->{name}, instance_ordinal => $i,
            declaration => FSM::Test::ConditionalOriginParser::_copy($instance),
            resolution => FSM::Test::ConditionalOriginParser::_copy($resolved),
            ledger => FSM::Test::ConditionalOriginParser::_copy($producer->{ledger}),
        };
    }
    return $result;
}

1;
