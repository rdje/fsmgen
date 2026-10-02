use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Cwd qw(abs_path);
use JSON::PP;
use Storable qw(dclone);
use FSM::Test::ProjectDataLocality;
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Test::RecordOutputCorpusOracle qw(record_output_ports record_output_type record_output_catalog);
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort);
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);
use FSM::Test::SourceQueryOracle qw(source_query_semantic_errors source_query_envelope_errors);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;
my $source = 'isf/record_output.isf';
my ($row) = grep {$_->{source_id} eq $source} @{build_source_query_cohort()};
my %args;

subtest 'maintained representative has exact ownership, applicable phases and explicit nonclaims' => sub {
    my @entries = grep {$_->{relpath} eq $source} regression_corpus_entries();
    is(scalar @entries, 1, 'one exact owner, no conflicting catalog allocation');
    same($entries[0], record_output_catalog(), 'complete independently literal catalog metadata');
    ok($row, 'actual source-query cohort owns the maintained representative');
    same($row->{query_kinds}, [qw(check semantic schedule)], 'all applicable source queries selected');
    same($row->{catalog_entries}[0]{supported_phases}, record_output_catalog()->{supported_phases}, 'complete phase identity');
    same($row->{catalog_entries}[0]{explicit_nonclaims}, record_output_catalog()->{explicit_nonclaims}, 'complete nonclaim identity');
    my $actor = FSM::Adapter::ISF->new->parse_file($source);
    my $before = $json->encode($actor);
    same($actor->{interface_port_metadata}, record_output_ports(), 'inputs then outputs retain authored role order');
    my ($output) = grep {$_->{name} eq 'packet'} @{$actor->{interface}{outputs}};
    same($output->{type_spec}, record_output_type(), 'complete recursive output identity');
    my $scheduler = FSM::Scheduler::ISF->new;
    same($json->decode($scheduler->report($actor))->{interface_ports}, record_output_ports(), 'first-touch schedule agrees');
    is($json->encode($actor), $before, 'complete actor JSON kinds and data remain unchanged');
};

for my $kind (qw(check semantic schedule)) {
    subtest "actual maintained $kind native API and newline products" => sub {
        my $r = run_source_query({repository_root => $root, row => $row, query_kind => $kind});
        for my $transport (qw(native stdio)) {
            is($r->{$transport}{exit_code}, 0, "$transport terminal success");
            is($r->{$transport}{signal}, 0, "$transport no signal");
            is($r->{$transport}{stderr}, '', "$transport clean stderr");
        }
        my $report = normalize_repository_paths($r->{native}{report}, $root);
        my $api = $r->{adapter_result};
        same($api->{structuredContent}{report}, $report, 'complete typed native/API equality');
        same($json->decode($api->{content}[0]{text}), $api->{structuredContent}, 'complete text/structured equality');
        same($r->{stdio}{response}, {jsonrpc => '2.0', id => 1, result => $api}, 'complete actual API/newline envelope equality');
        is($r->{source_sha256_before}, $r->{source_sha256_after}, 'exact maintained source bytes preserved');
        same($r->{producer_sha256_after}, $r->{producer_sha256_before}, 'all producer fingerprints preserved');
        same(source_query_envelope_errors({row => $row, query_kind => $kind, result => $api}), [], 'independent public envelope');
        $args{$kind} = {row => $row, query_kind => $kind, report => $report};
        same(source_query_semantic_errors($args{$kind}), [], 'independent literal declaration and semantic witnesses');
    };
}

subtest 'consistent missing or corrupted transport data cannot pass the authored oracle' => sub {
    for my $kind (qw(check semantic schedule)) {
        for my $mutation (
            sub {delete $_[0]{interface_ports}},
            sub {$_[0]{interface_ports} = []},
            sub {$_[0]{interface_ports}[2]{direction} = 'input'},
            sub {$_[0]{interface_ports}[2]{fields}[1]{signed} = '1'},
            sub {$_[0]{interface_ports}[2]{fields}[1]{lsb} = 2},
            sub {$_[0]{interface_ports}[2]{fields}[1]{state_model} = 'two_state'},
            sub {$_[0]{interface_ports}[2]{fields}[2]{state_model} = 'two_state'},
            sub {pop @{$_[0]{interface_ports}[2]{fields}}},
        ) {
            my $bad = dclone($args{$kind});
            $mutation->($kind eq 'schedule' ? $bad->{report} : $bad->{report}{source});
            my @shared = map {dclone($bad->{report})} 1..3;
            same($shared[0], $shared[1], 'native/API corrupted parity still passes');
            same($shared[1], $shared[2], 'API/newline corrupted parity still passes');
            my $before = $json->encode($bad);
            ok(@{source_query_semantic_errors($bad)}, 'independent oracle rejects shared loss/kind/layout/role/state corruption');
            is($json->encode($bad), $before, 'oracle never repairs evidence');
        }
    }
    my $bad = dclone($args{semantic});
    my ($packet) = grep {$_->{name} eq 'packet'} @{$bad->{report}{semantic}{forward_ir}{intent_hir}{signal_analysis}{outputs}};
    $packet->{declared_type_spec}{members}{payload}{members}{data}{signed} = 0;
    ok(@{source_query_semantic_errors($bad)}, 'complete recursive semantic type corruption is independently rejected');
};

done_testing;
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
