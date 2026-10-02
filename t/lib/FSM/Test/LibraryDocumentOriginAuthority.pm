package FSM::Test::LibraryDocumentOriginAuthority;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;

my $json = JSON::PP->new->canonical;

# Independently supplied bytes are the authority, never the submitted proof's
# file names or digests. Canonical resolution still reads the actual files.
sub from_documents {
    my ($class, $root_label, $documents, $search_roots) = @_;
    confess "library origin independent document set required\n"
        unless ref($documents) eq 'HASH' && exists $documents->{$root_label // ''}
            && ref($search_roots) eq 'ARRAY';
    _relative($_) for $root_label, keys %$documents, @$search_roots;
    for my $source (values %$documents) {
        confess "library origin complete source bytes required\n"
            unless defined($source) && !ref($source) && length($source);
    }
    my $snapshot = $json->decode($json->encode($documents));
    local $ENV{FSMLIB} = join ':', @$search_roots;
    my $parser = FSM::Test::LibraryDocumentOriginAuthority::Parser->new;
    my $actor = $parser->parse_documents($root_label, $snapshot);
    return bless {actor_json => $json->encode($actor), proof_json => $json->encode($parser->proof)}, $class;
}

sub validate {
    my ($self, $actor, $proof) = @_;
    confess "library origin independent document set required\n"
        unless defined($self->{actor_json}) && defined($self->{proof_json});
    confess "library origin actor differs from authoritative document set\n"
        unless $json->encode($actor) eq $self->{actor_json};
    confess "library origin proof differs from authoritative document set\n"
        unless $json->encode($proof) eq $self->{proof_json};
    return 1;
}
sub actor { $json->decode($_[0]{actor_json}) }
sub proof { $json->decode($_[0]{proof_json}) }

sub _relative {
    my ($label) = @_;
    confess "library origin repository-relative document identity required\n"
        unless defined($label) && !ref($label) && length($label)
            && $label !~ m{\A/|(?:\A|/)\.\.(?:/|\z)|[:\\]};
}

package FSM::Test::LibraryDocumentOriginAuthority::Parser;
use parent 'FSM::Test::SameSourceLibraryOriginParser';
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(refaddr);
use Lispish;

sub parse_documents {
    my ($self, $root_label, $documents) = @_;
    local $self->{document_sources} = $documents;
    local $self->{used_documents} = {$root_label => 1};
    local $self->{resolutions} = [];
    my $actor = $self->SUPER::parse_source($documents->{$root_label}, $root_label);
    # Canonical finalization follows use resolution. Check the entire retained
    # edge projection against the final actor before publishing any proof.
    my $uses = $actor->{library_uses} || [];
    confess "library origin final use coverage differs\n"
        unless @$uses == @{$self->{proof}{uses}};
    for my $i (0 .. $#$uses) {
        my $use = $uses->[$i];
        my $edge = $self->{proof}{uses}[$i];
        my %retained = %$edge;
        delete @retained{qw(actor_id ledger)};
        my $final = {
            path => ['library_uses', $i, 'actor'], source_label => $use->{library_source},
            target => $use->{actor}, map {$_ => $use->{$_}}
                qw(library export alias instance module bindings parameter_overrides),
        };
        confess "library origin final use target or identity differs\n"
            unless $json->encode(\%retained) eq $json->encode($final);
    }
    confess "library origin authoritative document membership differs\n"
        unless $json->encode([sort keys %$documents]) eq $json->encode([sort keys %{$self->{used_documents}}]);
    $self->{proof}{documents} = [map {{source_label => $_, source_sha256 => sha256_hex($documents->{$_})}}
        sort keys %$documents];
    $self->{proof}{resolutions} = $self->{resolutions};
    return $actor;
}

sub _parse_library_form {
    my ($self, $form, $label) = @_;
    FSM::Test::LibraryDocumentOriginAuthority::_relative($label);
    my $source = $self->{document_sources}{$label};
    confess "library origin selected document authority missing\n" unless defined $source;
    if ($label ne $self->{source_label}) {
        open my $file, '<:raw', $label or confess "library origin selected source unreadable\n";
        my $actual = do {local $/; <$file>};
        close $file or confess "library origin selected source close failed\n";
        confess "library origin selected source bytes differ from authority\n" unless $actual eq $source;
    }
    my $raw = Lispish::multi(\$source);
    confess "library origin authoritative source syntax invalid\n" unless ref($raw) eq 'ARRAY';
    my $forms = $self->{adapter}->normalize_multi($raw);
    my @matching = grep {ref($_) eq 'ARRAY' && $_->[0] eq 'library' && $_->[1] eq $form->[1]} @$forms;
    confess "library origin actual selected form differs from authority\n"
        unless @matching == 1 && $json->encode($matching[0]) eq $json->encode($form);
    $self->{used_documents}{$label} = 1;
    local $self->{source_text} = $source;
    local $self->{library_name} = $form->[1];
    my $library = FSM::Adapter::ISF::Parser::_parse_library_form($self, $form, $label);
    my $exports = $self->_export_ids($library);
    push @{$self->{libraries}}, {name => $library->{name}, source_label => $label, exports => $exports};
    return $library;
}

sub _export_ids {
    my ($self, $library) = @_;
    my %exports;
    for my $name (sort keys %{$library->{exports}{actor}}) {
        my $id = $self->{actor_refs}{refaddr($library->{exports}{actor}{$name})};
        confess "library origin exact export producer missing\n" unless defined $id;
        $exports{$name} = $id;
    }
    return \%exports;
}

sub _resolve_library {
    my ($self, @args) = @_;
    my $library = FSM::Adapter::ISF::Parser::_resolve_library($self, @args);
    push @{$self->{resolution_records}}, {
        library => $library->{name}, source_label => $library->{source}, exports => $self->_export_ids($library),
    };
    return $library;
}

sub _resolve_library_uses {
    my ($self, $actor, @args) = @_;
    local $self->{resolution_records} = [];
    my $result = FSM::Adapter::ISF::Parser::_resolve_library_uses($self, $actor, @args);
    my %by_alias;
    for my $i (0 .. $#{$self->{resolution_records}}) {
        my $record = $self->{resolution_records}[$i];
        my $import = $actor->{imports}[$i];
        confess "library origin declared import association differs\n"
            unless $import && $import->{library} eq $record->{library};
        $record->{alias} = $import->{alias};
        $by_alias{$record->{alias}} = $record;
        push @{$self->{resolutions}}, $record;
    }
    for my $i (0 .. $#{$actor->{library_uses}}) {
        my $use = $actor->{library_uses}[$i];
        my $resolution = $by_alias{$use->{alias}};
        my $id = $resolution ? $resolution->{exports}{$use->{export}} : undef;
        confess "library origin exact selected export association missing\n" unless defined $id;
        my $producer = $self->{actor_products}[$id];
        confess "library origin actual clone or document differs\n"
            unless $resolution->{library} eq $use->{library} && $resolution->{source_label} eq $use->{library_source}
                && $json->encode($producer->{actor}) eq $json->encode($use->{actor});
        push @{$self->{use_edges}}, {
            path => ['library_uses', $i, 'actor'], actor_id => $id,
            library => $use->{library}, source_label => $use->{library_source}, export => $use->{export},
            alias => $use->{alias}, instance => $use->{instance}, module => $use->{module},
            bindings => FSM::Test::ConditionalOriginParser::_copy($use->{bindings}),
            parameter_overrides => FSM::Test::ConditionalOriginParser::_copy($use->{parameter_overrides}),
            target => FSM::Test::ConditionalOriginParser::_copy($use->{actor}),
            ledger => FSM::Test::ConditionalOriginParser::_copy($producer->{ledger}),
        };
    }
    return $result;
}

1;
