use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use Cwd qw(abs_path);

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/procedure-cond-normalization-20261002';
my $cases = $json->decode(read_file("$base/cases.json"));
my @names = qw(basic expression priority no_else else_only nested_cond outer_when
    outer_while outer_until outer_repeat repeat_control outer_switch nested_call multiple_calls
    direct_formal generated domain first_actions first_samples authored_entry
    unused_bad_cond empty_body else_order non_list direct_recursion mutual_recursion);
is_deeply([sort map {$_->{name}} @$cases], [sort @names], 'fixed complete inline normalization source membership');

for my $case (@$cases) {
    my $name = $case->{name};
    subtest $name => sub {
        my $path = "$base/sources/$name.isf";
        my $source = read_file($path);
        my ($actor, $error, $lowered, $lower_error, $ir, $private_error);
        eval {$actor = FSM::Adapter::ISF->new->parse_file($path); 1} or $error = $@;
        if ($case->{parse_reason}) {
            ok(!defined($actor), 'invalid reached cond/call refuses during normalization');
            like($error // '', qr/\Q$case->{parse_reason}\E/, 'literal canonical producer reason');
        } else {
            ok($actor && !defined($error), 'authored source parses') or diag($error);
            if ($actor) {
                my $before = $json->encode($actor);
                my $tx = (grep {$_->{name} eq ($case->{transaction} // 'main')} @{$actor->{transactions}})[0];
                is($json->encode($tx->{clauses}), $json->encode($case->{clauses}),
                    'complete normalized clauses match independent literal source intent');
                my $proc = $actor->{procs}{choose};
                if ($proc) {
                    is($json->encode($proc->{body}), $json->encode($case->{definition}),
                        'original reusable procedure body remains unchanged');
                }
                eval {$lowered = FSM::Scheduler::ISF->new->lower($actor); 1} or $lower_error = $@;
                is($json->encode($actor), $before, 'complete first-touch caller JSON unchanged by lower');
                eval {
                    my $private_actor = $json->decode($before);
                    my $builder = FSM::Scheduler::ISF->new->{ir};
                    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($builder, $private_actor);
                    $private_actor = $formal->{actor} if $formal;
                    $ir = $builder->build_module($private_actor);
                    1;
                } or $private_error = $@;
                if ($case->{lower_reason}) {
                    ok(!defined($lowered), 'unsupported normalized context remains closed');
                    like($lower_error // '', qr/\Q$case->{lower_reason}\E/, 'precise context refusal remains');
                    ok(!defined($ir), 'private lowering shares the refusal');
                } else {
                    ok($lowered && !defined($lower_error), 'normalized source lowers') or diag($lower_error);
                    ok($ir && !defined($private_error), 'complete private preparation lowers') or diag($private_error);
                    if ($ir && $case->{entry_kind}) {
                        is($ir->{states}[0]{kind}, $case->{entry_kind}, 'documented first-entry meaning remains');
                    }
                    if ($ir && $name eq 'basic') {
                        my @branches = grep {$_->{kind} eq 'branch'} @{$ir->{states}};
                        is_deeply([map {$_->{condition}} @branches], ['allow', ['!', 'allow']],
                            'independent literal branch guards survive actual scheduling');
                        my @writes = map {grep {($_->{source_kind} // '') eq 'set'} @{$_->{assignments} || []}} @{$ir->{states}};
                        is_deeply([map {[$_->{lhs}, $_->{op}, $_->{rhs}]} @writes],
                            [['seen', '<-', 'datain'], ['seen', '<-', 'other']], 'complete ordered branch effects survive');
                    }
                }
            }
        }
        is(read_file($path), $source, 'entire supplied source stays byte exact');
        if (my $capture = $ENV{FSMGEN_PROC_COND_CAPTURE}) {
            write_file("$capture/$name.json", $json->encode(normalize_repository_paths({
                source => $source, actor => $actor, parse_error => $error,
                lowered => $lowered, lower_error => $lower_error,
                private_ir => $ir, private_error => $private_error,
            }, abs_path('.'))) . "\n");
        }
    };
}
done_testing;

sub read_file {open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
