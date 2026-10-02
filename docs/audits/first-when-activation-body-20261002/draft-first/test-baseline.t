use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);

my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $base = 'docs/audits/first-when-activation-body-20261002';
my $cases = $json->decode(read_file("$base/cases.json"));
my $work = tempdir(CLEANUP => 1);
my $reason = "when activation body supports only '(sample port as name)' clauses";

for my $case (@$cases) {
    my $name = $case->{name};
    subtest "actual source $name" => sub {
        my $path = "$base/sources/$name.isf";
        my $source = read_file($path);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my ($lowered, $lower_error);
        eval {$lowered = $scheduler->lower($actor); 1} or $lower_error = $@;
        is($json->encode($actor), $before, 'public lower preserves complete first-touch caller JSON');
        my ($ir, $private_error);
        eval {
            my $private_actor = $json->decode($before);
            my $builder = FSM::Scheduler::ISF->new->{ir};
            my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($builder, $private_actor);
            $private_actor = $formal->{actor} if $formal;
            $ir = $builder->build_module($private_actor);
            if ($case->{module} && $case->{module} ne 'worker') {
                my ($domain) = grep {$_->{name} eq 'io'} @{$ir->{domain_partition}{domains}};
                $private_actor = _domain_actor_for_scheduled_artifact($private_actor, $domain, 'idle');
                $ir = $builder->build_module($private_actor);
            }
            1;
        } or $private_error = $@;
        if ($case->{refuse}) {
            ok(!defined($lowered), 'unsupported entry action cannot produce artifacts');
            like($lower_error // '', qr/\Q$reason\E/, 'precise entry-body refusal');
            ok(!defined($ir), 'private preparation also refuses before dropping actions');
            like($private_error // '', qr/\Q$reason\E/, 'same private source contract');
        } else {
            ok(defined($lowered) && !defined($lower_error), 'supported source lowers') or diag($lower_error);
            ok(defined($ir) && !defined($private_error), 'supported private source qualifies') or diag($private_error);
            if ($ir) {
                my $selected = ($case->{module} // '') eq 'worker' ? $ir->{children}{worker} : $ir;
                ok(ref($selected) eq 'HASH', 'actual owning module selected');
                if ($selected) {
                    my @assignments = map {@{$_->{assignments} || []}} @{$selected->{states}};
                    is_deeply([sort map {$_->{lhs}} grep {($_->{source_kind} // '') eq 'sample_capture'} @assignments],
                        [sort @{$case->{samples}}], 'literal complete captured aliases survive');
                    is_deeply([map {$_->{lhs}} grep {($_->{source_kind} // '') eq 'set'} @assignments],
                        $case->{writes}, 'literal complete source write order survives');
                    for my $sample (grep {($_->{source_kind} // '') eq 'sample_capture'} @assignments) {
                        is($sample->{op}, '<=', 'sample retains entry register-input semantics');
                    }
                    my ($entry) = grep {$_->{kind} eq 'entry'} @{$selected->{states}};
                    if (defined($case->{guard})) {
                        is($entry->{guard}{expr} // $entry->{guard}{port}, $case->{guard}, 'literal authored entry guard survives');
                    }
                    if ($name =~ /positive_branch_/) {
                        is(scalar(grep {$_->{kind} eq 'branch'} @{$selected->{states}}), 1, 'later when remains one actual branch');
                    }
                }
                for my $file (sort keys %{$lowered->{files} || {}}) {
                    my $replay = "$work/$file";
                    write_file($replay, $lowered->{files}{$file});
                    my $checked = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', $replay], '');
                    is($checked->{exit_code}, 0, 'every actual emitted carrier strictly checks') or diag($checked->{stdout}, $checked->{stderr});
                }
            }
        }
        my %queries;
        for my $kind (qw(check semantic schedule)) {
            my $actual = run_source_query({repository_root => $root, query_kind => $kind, row => {
                source_id => $path, strict => 1, language_version => undef,
                query_kinds => [qw(check semantic schedule)], search_path_relpaths => [],
            }});
            $queries{$kind} = normalize_repository_paths($actual, $root);
            is($actual->{native}{signal}, 0, "$kind actual native terminal signal");
            is($actual->{native}{exit_code}, $case->{refuse} ? 1 : 0, "$kind actual native admission");
            my $report = $actual->{native}{report};
            if ($case->{refuse}) {
                like($actual->{native}{stdout} . $actual->{native}{stderr}, qr/\Q$reason\E/, "$kind actual native reason");
            } else {
                ok($kind eq 'schedule' || $report->{success}, "$kind complete actual successful report");
            }
            my $api = $actual->{adapter_result};
            is(!!$api->{isError}, !!$case->{refuse}, "$kind actual API error classification");
            is($json->encode(normalize_repository_paths($api->{structuredContent}{report}, $root)),
                $json->encode(normalize_repository_paths($report, $root)), "$kind complete native/API report parity");
            is($actual->{stdio}{exit_code}, 0, "$kind newline transport completes");
            is($json->encode($actual->{stdio}{response}{result}), $json->encode($api), "$kind complete API/newline response parity");
            is_deeply($actual->{producer_sha256_after}, $actual->{producer_sha256_before}, "$kind named producers stay unchanged");
            is($actual->{source_sha256_after}, $actual->{source_sha256_before}, "$kind supplied source stays unchanged");
        }
        is(read_file($path), $source, 'entire original source remains byte exact');
        if (my $capture = $ENV{FSMGEN_WHEN_CAPTURE}) {
            write_file("$capture/$name.json", $json->encode(normalize_repository_paths({
                source => $source, actor => $json->decode($before), case => $case,
                private_ir => $ir, private_error => $private_error,
                lowered => $lowered, lower_error => $lower_error, queries => \%queries,
            }, $root)) . "\n");
        }
    };
}
done_testing;

sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
