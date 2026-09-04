package FSM::VIAL::SourceMigration;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;

my @RESULT_KEYS = qw(
    schema schema_version source_language_version target_language_version
    input_style output_style sources compatibility_projection_sha256 diagnostics
);
my @SOURCE_KEYS = qw(
    source_name input_sha256 output_sha256 formatted_source source_map
);
my @MAP_KEYS = qw(semantic_path input_location output_location);

sub migrate_v1_to_v2 {
    my ($class, $args) = @_;
    die "VIAL source migration requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    _require_exact_keys(
        $args,
        [qw(text source_name source_catalog output_style)],
        'VIAL source migration',
    );
    die "VIAL source migration text must be scalar\n"
        unless defined($args->{text}) && !ref($args->{text});
    die "VIAL source migration source_name must be scalar\n"
        unless defined($args->{source_name}) && !ref($args->{source_name});
    die "VIAL source migration source_catalog must be one unblessed hash\n"
        unless ref($args->{source_catalog}) eq 'HASH'
            && !blessed($args->{source_catalog});
    die "VIAL source migration output_style must be null, normal, or terse\n"
        if defined($args->{output_style})
            && (ref($args->{output_style})
                || $args->{output_style} !~ /\A(?:normal|terse)\z/);

    my $input_ir = FSM::VIAL::Parser->parse_source({
        text => $args->{text},
        source_name => $args->{source_name},
        source_catalog => $args->{source_catalog},
    });
    die "VIAL source migration accepts only language version 1\n"
        unless $input_ir->language_version == 1;
    my $input_data = $input_ir->as_hashref;
    my %input_text = (
        %{$args->{source_catalog}},
        $args->{source_name} => $args->{text},
    );
    my @ordered_source_names = map { $_->{source_name} } @{$input_data->{sources}};
    my %output_text;
    my %input_style;
    for my $source_name (@ordered_source_names) {
        die "VIAL source migration catalog is missing '$source_name'\n"
            unless exists $input_text{$source_name};
        my $style = FSM::VIAL::SourceProjection->source_style({
            text => $input_text{$source_name},
            source_name => $source_name,
        });
        $input_style{$source_name} = $style;
        my $target_style = $args->{output_style} // $style;
        my $canonical_v1 = FSM::VIAL::SourceProjection->format_source({
            text => $input_text{$source_name},
            source_name => $source_name,
            output_style => $target_style,
        })->{text};
        my $promoted = _promote_canonical_source(
            $canonical_v1, $target_style, $source_name,
        );
        my $canonical_v2 = FSM::VIAL::SourceProjection->format_source({
            text => $promoted,
            source_name => $source_name,
            output_style => $target_style,
        })->{text};
        $output_text{$source_name} = $canonical_v2;
    }

    my %output_catalog = %output_text;
    my $output_root = delete $output_catalog{$args->{source_name}};
    my $output_ir = FSM::VIAL::Parser->parse_source({
        text => $output_root,
        source_name => $args->{source_name},
        source_catalog => \%output_catalog,
    });
    die "VIAL source migration did not produce language version 2\n"
        unless $output_ir->language_version == 2;
    my $input_digest =
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($input_ir);
    my $output_digest =
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($output_ir);
    die "VIAL source migration did not preserve the compatibility projection\n"
        unless $input_digest eq $output_digest;

    my $output_data = $output_ir->as_hashref;
    my @sources;
    for my $source_name (@ordered_source_names) {
        my @source_map;
        for my $semantic_path (sort keys %{$input_data->{provenance}}) {
            my $input_location = $input_data->{provenance}{$semantic_path};
            next unless $input_location->{source_name} eq $source_name;
            my $output_location = $output_data->{provenance}{$semantic_path};
            die "VIAL source migration lost semantic path '$semantic_path'\n"
                unless defined($output_location)
                    && $output_location->{source_name} eq $source_name;
            push @source_map, {
                semantic_path => $semantic_path,
                input_location => _clone($input_location),
                output_location => _clone($output_location),
            };
        }
        die "VIAL source migration produced an empty source map for '$source_name'\n"
            unless @source_map;
        my $source_record = {
            source_name => $source_name,
            input_sha256 => sha256_hex($input_text{$source_name}),
            output_sha256 => sha256_hex($output_text{$source_name}),
            formatted_source => $output_text{$source_name},
            source_map => \@source_map,
        };
        _require_exact_keys($source_record, \@SOURCE_KEYS, 'migration source');
        _require_exact_keys($_, \@MAP_KEYS, 'migration source-map entry')
            for @source_map;
        push @sources, $source_record;
    }

    my $root_input_style = $input_style{$args->{source_name}} . '_v1';
    my $result = {
        schema => 'fsmgen.vial_source_migration.v1',
        schema_version => 1,
        source_language_version => 1,
        target_language_version => 2,
        input_style => $root_input_style,
        output_style => defined($args->{output_style})
            ? $args->{output_style} . '_v2' : 'preserve_v2',
        sources => \@sources,
        compatibility_projection_sha256 => $input_digest,
        diagnostics => [],
    };
    _require_exact_keys($result, \@RESULT_KEYS, 'migration result');
    return _clone($result);
}

sub empty_failure_result {
    my ($class, $args) = @_;
    die "VIAL migration failure requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    _require_exact_keys($args, [qw(input_style output_style diagnostics)],
        'VIAL migration failure');
    die "VIAL migration failure diagnostics must be a non-empty array\n"
        unless ref($args->{diagnostics}) eq 'ARRAY' && @{$args->{diagnostics}};
    my $result = {
        schema => 'fsmgen.vial_source_migration.v1',
        schema_version => 1,
        source_language_version => 1,
        target_language_version => 2,
        input_style => $args->{input_style},
        output_style => $args->{output_style},
        sources => [],
        compatibility_projection_sha256 => undef,
        diagnostics => _clone($args->{diagnostics}),
    };
    _require_exact_keys($result, \@RESULT_KEYS, 'migration result');
    return _clone($result);
}

sub _promote_canonical_source {
    my ($source, $style, $source_name) = @_;
    my $promoted = $source;
    if ($style eq 'normal') {
        my $versions = ($promoted =~ s/\(version 1\)/\(version 2\)/g);
        die "normal VIAL v1 source '$source_name' has no exact version selector\n"
            unless $versions == 1;
        my $fixtures = ($promoted =~ s/^    \(fixtures/    (intents)\n    (fixtures/mg);
        die "normal VIAL v1 source '$source_name' has no exact fixtures section\n"
            unless $fixtures == 1;
    }
    else {
        my $versions = ($promoted =~ s/\A\(vial 1\n/\(vial 2\n/);
        die "terse VIAL v1 source '$source_name' has no exact version selector\n"
            unless $versions == 1;
    }
    return $promoted;
}

sub _require_exact_keys {
    my ($value, $keys, $label) = @_;
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists $value->{$_} } @$keys;
    die "$label has unknown key '$unknown[0]'\n" if @unknown;
    die "$label is missing key '$missing[0]'\n" if @missing;
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return JSON::PP::true
        if blessed($value) && blessed($value)->isa('JSON::PP::Boolean') && $value;
    return JSON::PP::false
        if blessed($value) && blessed($value)->isa('JSON::PP::Boolean');
    return { map { $_ => _clone($value->{$_}) } sort keys %$value }
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
