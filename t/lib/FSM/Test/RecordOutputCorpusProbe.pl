use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort);
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_source_query_kinds);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use File::Temp qw(tempdir);

my ($mode, $destination) = @ARGV;
die "usage: probe snapshot|fixture repository-relative-destination\n"
    unless defined($destination) && $mode =~ /\A(?:snapshot|fixture)\z/
    && $destination !~ m{\A/|(?:\A|/)\.\.(?:/|\z)} && -d $destination;
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;
my $cohort = build_source_query_cohort();
if ($mode eq 'snapshot') {
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_capability_query', arguments => {section => 'all'}}};
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root)->handle_jsonrpc_request($request);
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    my @catalog = regression_corpus_entries();
    save('snapshot', {catalog => data(\@catalog), cohort => $cohort,
        query_kinds => semantic_introspection_source_query_kinds(),
        discovery => {native => $native, in_process => build_capability_manifest(),
            request => $request, api => $api, newline => $wire},
        source_sha256 => {map {$_->{source_id} => sha256_hex(read_file($_->{source_id}))} @$cohort}});
} else {
    my ($row) = grep {$_->{source_id} eq 'isf/record_output.isf'} @$cohort;
    die "maintained fixture is not catalog-owned\n" unless $row;
    for my $kind (@{$row->{query_kinds}}) {
        save($kind, run_source_query({repository_root => $root, row => $row, query_kind => $kind}));
    }
    my $actor = FSM::Adapter::ISF->new->parse_file($row->{source_id});
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($actor);
    my $work = tempdir(CLEANUP => 1);
    my %carriers;
    for my $name (sort keys %{$lowered->{files}}) {
        write_file("$work/$name", $lowered->{files}{$name});
        $carriers{$name} = capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$work/$name"]);
    }
    my %generation;
    for my $language (qw(systemverilog sv)) {
        mkdir "$work/$language" or die $!;
        my $destination = "$work/$language/record_output.sv";
        my $receipt = capture([$^X, 'bin/fsmgen', '--strict', '--language', $language,
            '-o', $destination, $row->{source_id}]);
        $generation{$language} = {receipt => $receipt,
            hdl => -f $destination ? read_file($destination) : undef};
    }
    save('carriers', {actor_before => $json->decode($before), actor_after => $actor,
        lower => $lowered, report => $json->decode($scheduler->report($actor)), carriers => \%carriers,
        generation => \%generation, source => read_file($row->{source_id}),
        source_sha256 => sha256_hex(read_file($row->{source_id}))});
}
print "record-output corpus $mode capture complete\n";

sub capture {FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '')}
sub save {write_file("$destination/$_[0].json", $json->encode(normalize_repository_paths($_[1], $root))."\n")}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}
sub data {
    my ($value) = @_;
    return $value unless ref $value;
    return {regexp => "$value"} if ref($value) eq 'Regexp';
    return [map {data($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => data($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    die 'unsupported catalog data kind '.ref($value);
}
