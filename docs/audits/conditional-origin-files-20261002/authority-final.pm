package FSM::Test::FileDocumentOriginAuthority;

use v5.20;
use strict;
use warnings;
use parent 'FSM::Test::ATLDocumentOriginAuthority';
use Carp qw(confess);
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP;

my $json = JSON::PP->new->canonical;

# Private qualification only. The current, independently chosen workspace root
# supplies runtime coordinates. Complete supplied bytes authenticate identities;
# neither an embedded digest nor a candidate's spelling supplies authority.
sub from_files {
    my ($class, $label, $documents, $search_roots) = @_;
    confess "file origin independent document set required\n"
        unless ref($documents) eq 'HASH' && exists $documents->{$label // ''}
            && ref($search_roots) eq 'ARRAY';
    _identity($_) for $label, keys %$documents;
    for my $root (@$search_roots) {
        _identity($root) unless defined($root) && !ref($root) && $root eq '.';
    }
    for my $source (values %$documents) {
        confess "file origin complete source bytes required\n"
            unless defined($source) && !ref($source) && length($source);
    }
    my $parser = FSM::Test::FileDocumentOriginAuthority::Parser->new;
    $parser->{file_root} = abs_path(getcwd());
    $parser->{file_documents} = $json->decode($json->encode($documents));
    local $ENV{FSMLIB} = join ':', @$search_roots;
    # Execute the actual public file-reading entry, including its source label.
    my $actor = $parser->parse_file($label);
    my $portable_actor = project_actor($actor, sub {$parser->document_identity($_[0])});
    my $proof = project_proof($parser->proof, sub {$parser->document_identity($_[0])});
    return bless {actor_json => $json->encode($portable_actor), proof_json => $json->encode($proof)}, $class;
}

sub _identity {
    my ($label) = @_;
    confess "file origin canonical relative identity required\n"
        unless defined($label) && !ref($label) && length($label)
            && $label !~ m{\A/|[:\\]}
            && !grep {$_ eq '' || $_ eq '.' || $_ eq '..'} split(m{/}, $label, -1);
}

# Enumerate contract-bearing source fields explicitly. Never rewrite arbitrary
# strings, authored clauses, identifiers or source forms by prefix matching.
sub project_actor {
    my ($actor, $identity) = @_;
    my $copy = $json->decode($json->encode($actor));
    for my $use (@{$copy->{library_uses} || []}) {
        $use->{library_source} = $identity->($use->{library_source});
        $use->{actor} = project_actor($use->{actor}, $identity);
    }
    for my $resolution (values %{$copy->{_atl_actor_type_resolutions} || {}}) {
        $resolution->{library_source} = $identity->($resolution->{library_source});
        $resolution->{actor} = project_actor($resolution->{actor}, $identity);
    }
    return $copy;
}

sub project_proof {
    my ($proof, $identity) = @_;
    my $copy = $json->decode($json->encode($proof));
    $copy->{source_label} = $identity->($copy->{source_label});
    for my $name (qw(documents libraries resolutions atl_resolutions)) {
        $_->{source_label} = $identity->($_->{source_label}) for @{$copy->{$name}};
    }
    for my $producer (@{$copy->{actors}}) {
        $producer->{source_label} = $identity->($producer->{source_label});
        $producer->{actor} = project_actor($producer->{actor}, $identity);
        $producer->{ledger}{actor_sha256} = sha256_hex($json->encode($producer->{actor}));
    }
    for my $use (@{$copy->{uses}}) {
        $use->{source_label} = $identity->($use->{source_label});
        $use->{target} = project_actor($use->{target}, $identity);
        $use->{ledger}{actor_sha256} = sha256_hex($json->encode($use->{target}));
    }
    for my $edge (@{$copy->{atl}}) {
        $edge->{resolution}{library_source} = $identity->($edge->{resolution}{library_source});
        $edge->{resolution}{actor} = project_actor($edge->{resolution}{actor}, $identity);
        $edge->{ledger}{actor_sha256} = sha256_hex($json->encode($edge->{resolution}{actor}));
    }
    $copy->{actor_sha256} = $copy->{actors}[$copy->{root_actor_id}]{ledger}{actor_sha256};
    return $copy;
}

package FSM::Test::FileDocumentOriginAuthority::Parser;
use parent -norequire, 'FSM::Test::ATLDocumentOriginAuthority::Parser';
use Carp qw(confess);
use Cwd qw(abs_path);
use File::Spec;
use Lispish;
use Scalar::Util qw(refaddr);

sub document_identity {
    my ($self, $candidate) = @_;
    confess "file origin runtime candidate required\n" unless defined($candidate) && !ref($candidate);
    my $absolute = File::Spec->rel2abs($candidate);
    my $relative = File::Spec->abs2rel($absolute, $self->{file_root});
    FSM::Test::FileDocumentOriginAuthority::_identity($relative);
    # Reject symlink aliases, escaped paths and noncanonical spelling. A moved
    # root is supported; an alias of a declared file is a different contract.
    confess "file origin selected file is missing or aliased\n"
        unless -f $absolute && defined(abs_path($absolute)) && abs_path($absolute) eq $absolute;
    confess "file origin selected document authority missing\n"
        unless exists $self->{file_documents}{$relative};
    return $relative;
}

sub parse_source {
    my ($self, $actual, $label) = @_;
    my $identity = $self->document_identity($label);
    confess "file origin root bytes differ from authority\n"
        unless $actual eq $self->{file_documents}{$identity};
    local $self->{file_forms} = {};
    return $self->SUPER::parse_documents($label, $self->{file_documents});
}

sub _parse_library_form {
    my ($self, $form, $label) = @_;
    my $identity = $self->document_identity($label);
    my $source = $self->{file_documents}{$identity};
    open my $file, '<:raw', $label or confess "file origin selected source unreadable\n";
    my $actual = do {local $/; <$file>};
    close $file or confess "file origin selected source close failed\n";
    confess "file origin selected source bytes differ from authority\n" unless $actual eq $source;
    my $raw = Lispish::multi(\$source);
    confess "file origin authoritative source syntax invalid\n" unless ref($raw) eq 'ARRAY';
    my $forms = $self->{adapter}->normalize_multi($raw);
    my @matching = grep {ref($_) eq 'ARRAY' && $_->[0] eq 'library' && $_->[1] eq $form->[1]} @$forms;
    my $key = refaddr($form);
    my $previous = $self->{file_forms}{$key};
    confess "file origin actual selected form differs from authority\n"
        unless @matching == 1 && ($previous
            ? $previous->{identity} eq $identity && $previous->{library} eq $form->[1]
                && $previous->{after_json} eq $json->encode($form)
            : $json->encode($matching[0]) eq $json->encode($form));
    $self->{used_documents}{$identity} = 1;
    local $self->{source_text} = $source;
    local $self->{library_name} = $form->[1];
    my $library = FSM::Adapter::ISF::Parser::_parse_library_form($self, $form, $label);
    $self->{file_forms}{$key} = {form => $form, identity => $identity,
        library => $form->[1], after_json => $json->encode($form)};
    push @{$self->{libraries}}, {name => $library->{name}, source_label => $label,
        exports => $self->_export_ids($library)};
    return $library;
}

1;
