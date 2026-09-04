package FSM::VIAL::SemanticIR;

use strict;
use warnings;

use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyContract qw(
    validate_vial_semantic_family_collection
);

my @TOP_LEVEL_KEYS_V1 = qw(
    schema_version
    language
    language_version
    profile
    root_source
    sources
    packages
    required_capabilities
    provenance
);
my @TOP_LEVEL_KEYS_V2 = ('schema', @TOP_LEVEL_KEYS_V1);

sub _new_validated {
    my ($class, $data) = @_;
    my $caller = caller;
    die "FSM::VIAL::SemanticIR->_new_validated is private\n"
        unless $caller eq 'FSM::VIAL::SemanticBuilder'
            || $caller eq 'FSM::VIAL::SemanticBuilderV2'
            || $caller eq __PACKAGE__;
    die "VIALSemanticIR data must be an unblessed hash\n"
        unless ref($data) eq 'HASH' && !blessed($data);

    my $version = $data->{schema_version};
    my @top_level_keys = defined($version) && $version == 2
        ? @TOP_LEVEL_KEYS_V2 : @TOP_LEVEL_KEYS_V1;
    my %expected = map { $_ => 1 } @top_level_keys;
    my @actual = sort keys %{$data};
    my @unknown = grep { !$expected{$_} } @actual;
    my @missing = grep { !exists $data->{$_} } @top_level_keys;
    die "VIALSemanticIR has unknown top-level key '$unknown[0]'\n" if @unknown;
    die "VIALSemanticIR is missing top-level key '$missing[0]'\n" if @missing;
    die "VIALSemanticIR schema_version must be 1 or 2\n"
        unless $data->{schema_version} == 1 || $data->{schema_version} == 2;
    die "VIALSemanticIR language must be vial\n" unless $data->{language} eq 'vial';
    die "VIALSemanticIR language version must match its schema version\n"
        unless $data->{language_version} == $data->{schema_version};
    if ($data->{schema_version} == 1) {
        die "VIALSemanticIR profile is invalid\n"
            unless $data->{profile} eq 'core_directed_single_clock_v1';
    }
    else {
        die "VIALSemanticIR schema is invalid\n"
            unless $data->{schema} eq 'fsmgen.vial_semantic_ir.v2';
        die "VIALSemanticIR profile is invalid\n"
            unless $data->{profile} eq 'core_directed_single_clock_v2';
        for my $index (0 .. $#{$data->{packages}}) {
            die "VIALSemanticIR v2 package $index is missing intent_families\n"
                unless ref($data->{packages}[$index]{intent_families}) eq 'ARRAY';
            validate_vial_semantic_family_collection(
                'semantic_family', $data->{packages}[$index]{intent_families},
            );
        }
    }

    _assert_plain_data($data, '$');
    return bless({ data => _clone($data) }, $class);
}

sub schema_version {
    my ($self) = @_;
    return 0 + $self->{data}{schema_version};
}

sub language_version {
    my ($self) = @_;
    return 0 + $self->{data}{language_version};
}

sub profile {
    my ($self) = @_;
    return $self->{data}{profile};
}

sub sources {
    my ($self) = @_;
    return _clone($self->{data}{sources});
}

sub packages {
    my ($self) = @_;
    return _clone($self->{data}{packages});
}

sub provenance {
    my ($self) = @_;
    return _clone($self->{data}{provenance});
}

sub source_location_for {
    my ($self, $semantic_path) = @_;
    return undef unless defined($semantic_path) && !ref($semantic_path);
    return _clone($self->{data}{provenance}{$semantic_path})
        if exists $self->{data}{provenance}{$semantic_path};

    my $candidate = $semantic_path;
    while ($candidate ne '') {
        $candidate =~ s{/[^/]*\z}{};
        $candidate = '/' if $candidate eq '';
        return _clone($self->{data}{provenance}{$candidate})
            if exists $self->{data}{provenance}{$candidate};
        last if $candidate eq '/';
    }
    return undef;
}

sub as_hashref {
    my ($self) = @_;
    return _clone($self->{data});
}

sub _v1_base_projection {
    my ($self) = @_;
    die "VIALSemanticIR v1 base projection is private\n"
        unless caller eq 'FSM::VIAL::ExecutionBuilderV2';
    die "VIALSemanticIR v1 base projection requires exact v2 SemanticIR\n"
        unless ref($self) eq __PACKAGE__ && $self->{data}{schema_version} == 2;
    my $data = $self->as_hashref;
    for my $package (@{$data->{packages}}) {
        die "VIALSemanticIR v1 base projection requires empty intent families\n"
            if @{$package->{intent_families}};
        delete $package->{intent_families};
    }
    delete $data->{provenance}{$_}
        for grep { m{/intent_families(?:/|\z)} } keys %{$data->{provenance}};
    delete $data->{schema};
    $data->{schema_version} = 1;
    $data->{language_version} = 1;
    $data->{profile} = 'core_directed_single_clock_v1';
    $data->{required_capabilities} = [qw(
        vial.profile.core_directed_single_clock_v1
        vial.semantic_ir.v1
        vial.source.v1
    )];
    return __PACKAGE__->_new_validated($data);
}

sub _assert_plain_data {
    my ($value, $path) = @_;
    return unless ref($value);

    die "VIALSemanticIR contains blessed data at $path\n" if blessed($value);
    my $type = reftype($value) || '';
    if ($type eq 'HASH') {
        for my $key (sort keys %{$value}) {
            die "VIALSemanticIR contains a reference key at $path\n" if ref($key);
            _assert_plain_data($value->{$key}, "$path/$key");
        }
        return;
    }
    if ($type eq 'ARRAY') {
        for my $index (0 .. $#{$value}) {
            _assert_plain_data($value->[$index], "$path/$index");
        }
        return;
    }
    die "VIALSemanticIR contains unsupported reference type '$type' at $path\n";
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
