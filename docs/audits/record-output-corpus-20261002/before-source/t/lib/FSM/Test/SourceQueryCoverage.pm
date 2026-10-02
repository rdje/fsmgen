package FSM::Test::SourceQueryCoverage;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_source_query_kinds);

our @EXPORT_OK = qw(build_source_query_cohort select_source_query_cohort vial_source_versions);

sub vial_source_versions {
    die "VIAL source version mapping accepts no arguments\n" if @_;
    return {
        'vial/ahb_subordinate_base_output_arbitration.vial' => 1,
        'vial/ahb_subordinate_base_output_arbitration_v2.vial' => 2,
        'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial' => 2,
    };
}

sub build_source_query_cohort {
    my ($args) = @_;
    $args = {} unless @_;
    die "cohort requires at most one unblessed options hash\n"
        unless @_ <= 1 && _hash($args);
    _closed($args, [qw(entries query_kinds vial_versions)], 'cohort');
    my $entries = exists($args->{entries}) ? $args->{entries} : [regression_corpus_entries()];
    my $queries = exists($args->{query_kinds}) ? $args->{query_kinds} : semantic_introspection_source_query_kinds();
    my $versions = exists($args->{vial_versions}) ? $args->{vial_versions} : vial_source_versions();
    die "catalog entries must be a nonempty array\n" unless ref($entries) eq 'ARRAY' && @$entries;
    die "VIAL version mapping must be an unblessed hash\n" unless _hash($versions);
    _validate_queries($queries);
    for my $source (sort keys %$versions) {
        die "VIAL version mapping requires relative VIAL source identities\n"
            unless _relative($source) && $source =~ /\.vial\z/;
        die "VIAL version must be explicitly 1 or 2 for '$source'\n"
            unless _scalar($versions->{$source}) && $versions->{$source} =~ /\A[12]\z/;
    }

    my (%ids, %by_source, %constraints, %seen_vial);
    my @sources;
    for my $entry (@$entries) {
        die "catalog entry must be an unblessed hash\n" unless _hash($entry);
        my $id = $entry->{id};
        die "catalog ID must be a nonempty string\n" unless _scalar($id) && length($id);
        die "duplicate catalog ID '$id'\n" if $ids{$id}++;
        my $classification = $entry->{classification};
        die "unknown catalog classification for '$id'\n"
            unless _scalar($classification) && $classification =~ /\A(?:supported_smoke|expected_failure|legacy_out_of_scope)\z/;
        next unless $classification eq 'supported_smoke';
        my $source = $entry->{relpath};
        die "catalog '$id' requires a relative source identity\n" unless _relative($source);
        my ($suffix) = $source =~ /\.([^.\/]+)\z/;
        die "unaccounted source suffix for '$source'\n" unless defined($suffix) && exists($queries->{$suffix});
        my %kinds = (
            fsm => {map {$_ => 1} qw(fsm dt composition)}, isf => {isf => 1}, ppif => {ppif => 1},
            (map {$_ => {ial2_profile_alias => 1}} qw(axi apb ahb)), vial => {vial => 1},
        );
        my $kind = $entry->{source_kind};
        die "unaccounted source kind for '$id'\n"
            unless _scalar($kind) && $kinds{$suffix}{$kind};
        my $strict = $entry->{strict_supported};
        die "catalog '$id' requires an explicit strict admission flag\n"
            unless _scalar($strict) && $strict =~ /\A[01]\z/;
        die "hardware source '$source' lacks strict support\n" if $suffix ne 'vial' && !$strict;
        die "VIAL source '$source' uses versioned admission, not a strict flag\n" if $suffix eq 'vial' && $strict;
        for my $key (qw(family coverage)) {
            die "catalog '$id' requires $key\n" unless _scalar($entry->{$key}) && length($entry->{$key});
        }
        my $version;
        if ($suffix eq 'vial') {
            die "unmapped VIAL source '$source'\n" unless exists $versions->{$source};
            $version = 0 + $versions->{$source};
            $seen_vial{$source} = 1;
        }
        if (!exists $by_source{$source}) {
            push @sources, $source;
            $by_source{$source} = {
                source_id => $source, file_kind => $suffix, source_kind => $kind,
                language_version => $version, strict => $strict ? JSON::PP::true : JSON::PP::false,
                query_kinds => [@{$queries->{$suffix}}], catalog_entries => [],
                search_path_relpaths => [], expectations => {},
            };
        }
        my $row = $by_source{$source};
        die "conflicting source kind for '$source'\n" unless $row->{source_kind} eq $kind;
        for my $key (qw(expected_module_name expected_top_name expected_semantic_source_root_kind)) {
            next unless exists $entry->{$key};
            my $value = $entry->{$key};
            die "catalog '$id' requires scalar $key\n" unless _scalar($value) && length($value);
            die "conflicting $key for '$source'\n"
                if exists($row->{expectations}{$key}) && $row->{expectations}{$key} ne $value;
            $row->{expectations}{$key} = $value;
        }
        if (exists $entry->{search_path_relpaths}) {
            my $paths = _strings($entry->{search_path_relpaths}, 'search paths');
            die "catalog '$id' has an unsafe relative search path\n"
                if grep { $_ ne '.' && !_relative($_) } @$paths;
            my $encoded = JSON::PP->new->canonical->encode($paths);
            die "conflicting search_path_relpaths for '$source'\n"
                if exists($constraints{$source}) && $constraints{$source} ne $encoded;
            $constraints{$source} = $encoded;
            $row->{search_path_relpaths} = [@$paths];
        }
        push @{$row->{catalog_entries}}, {
            id => $id, family => $entry->{family}, coverage => $entry->{coverage},
            map { $_ => _strings(exists($entry->{$_}) ? $entry->{$_} : [], $_) }
                qw(required_capabilities supported_phases explicit_nonclaims),
        };
    }
    die "cohort has no supported sources\n" unless @sources;
    for my $source (sort keys %$versions) {
        die "unaccounted VIAL version mapping '$source'\n" unless $seen_vial{$source};
    }
    for my $source (@sources) {
        my %coverage = map {$_->{coverage} => 1} @{$by_source{$source}{catalog_entries}};
        $by_source{$source}{coverage_buckets} = [sort keys %coverage];
    }
    return _clone([map {$by_source{$_}} @sources]);
}

sub select_source_query_cohort {
    my ($args) = @_;
    die "cohort focus requires exactly one unblessed options hash\n" unless @_ == 1 && _hash($args);
    _closed($args, [qw(cohort source_ids)], 'cohort focus');
    my $rows = $args->{cohort};
    die "cohort focus requires a nonempty cohort array\n" unless ref($rows) eq 'ARRAY' && @$rows;
    my %known;
    for my $row (@$rows) {
        die "cohort focus requires distinct relative source identities\n"
            unless _hash($row) && _relative($row->{source_id}) && !$known{$row->{source_id}}++;
    }
    return _clone($rows) unless exists $args->{source_ids};
    my $ids = _strings($args->{source_ids}, 'focus source IDs');
    die "cohort focus cannot be empty\n" unless @$ids;
    my %selected;
    for my $id (@$ids) {
        die "unknown focus source '$id'\n" unless $known{$id};
        die "repeated focus source '$id'\n" if $selected{$id}++;
    }
    return _clone([grep {$selected{$_->{source_id}}} @$rows]);
}

sub _validate_queries {
    my ($queries) = @_;
    die "query applicability must be an unblessed hash\n" unless _hash($queries);
    my %expected = (fsm => [qw(check semantic)], vial => [qw(check semantic inspection)],
        map {$_ => [qw(check semantic schedule)]} qw(isf ppif axi apb ahb));
    for my $kind (keys %$queries) {
        die "unaccounted source kind '$kind' in query applicability\n" unless exists $expected{$kind};
    }
    for my $kind (sort keys %expected) {
        my $actual = $queries->{$kind};
        die "query applicability for '$kind' is missing or unaccounted\n"
            unless ref($actual) eq 'ARRAY' && @$actual == @{$expected{$kind}}
                && !grep { !_scalar($actual->[$_]) || $actual->[$_] ne $expected{$kind}[$_] } 0..$#$actual;
    }
}
sub _strings {
    my ($value, $label) = @_;
    die "$label must be an array of nonempty strings\n"
        unless ref($value) eq 'ARRAY' && !grep {!_scalar($_) || !length($_)} @$value;
    return [@$value];
}
sub _relative {
    my ($value) = @_;
    return _scalar($value) && $value =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\z/
        && !grep {$_ eq '' || $_ eq '.' || $_ eq '..'} split m{/}, $value, -1;
}
sub _scalar {defined($_[0]) && !ref($_[0])}
sub _hash {ref($_[0]) eq 'HASH' && !blessed($_[0])}
sub _closed {
    my ($args, $keys, $label) = @_;
    my %allowed = map {$_ => 1} @$keys;
    die "$label received an unknown option\n" if grep {!$allowed{$_}} keys %$args;
}
sub _clone {JSON::PP->new->decode(JSON::PP->new->canonical->encode($_[0]))}
1;
