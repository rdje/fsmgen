use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);

# Safety qualification, not normalization delivery. The candidate that expands
# an inline cond without source intent newly admits first_samples as activation.
# Keep that source refused until SEM .5.2/.5.4.2/.5.3 qualify its branch intent.
my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/procedure-cond-normalization-20261002';
my $cases = $json->decode(read_file("$base/cases.json"));
my @names = qw(basic expression priority no_else else_only nested_cond outer_when
    outer_while outer_until outer_repeat repeat_control outer_switch nested_call multiple_calls
    direct_formal generated domain first_actions first_samples authored_entry
    unused_bad_cond empty_body else_order non_list direct_recursion mutual_recursion);
is_deeply([sort map {$_->{name}} @$cases], [sort @names], 'fixed complete inline cond source membership');
my %without_cond = map {$_ => 1} qw(repeat_control authored_entry unused_bad_cond);
my %admitted = map {$_ => 1} qw(authored_entry unused_bad_cond);
for my $case (@$cases) {
    my $name = $case->{name};
    subtest "current inline cond safety boundary $name" => sub {
        my $path = "$base/sources/$name.isf";
        my $source = read_file($path);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $before = $json->encode($actor);
        my ($tx) = grep {$_->{name} eq 'main'} @{$actor->{transactions}};
        is(!!has_cond($tx->{clauses}), !$without_cond{$name},
            'actual retained inline cond versus canonical authored/unused controls');
        if (!$case->{parse_reason}) {
            is($json->encode($actor->{procs}{choose}{body}), $json->encode($case->{definition}),
                'original reusable procedure definition remains intact');
        }
        my ($lowered, $lower_error, $ir, $private_error);
        eval {$lowered = FSM::Scheduler::ISF->new->lower($actor); 1} or $lower_error = $@;
        is($json->encode($actor), $before, 'lower preserves complete first-touch caller JSON');
        eval {
            my $a = $json->decode($before);
            my $builder = FSM::Scheduler::ISF->new->{ir};
            my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($builder, $a);
            $a = $formal->{actor} if $formal;
            $ir = $builder->build_module($a);
            if ($name eq 'domain') {
                my ($domain) = grep {$_->{name} eq 'io'} @{$ir->{domain_partition}{domains}};
                $a = _domain_actor_for_scheduled_artifact($a, $domain, 'idle');
                $ir = $builder->build_module($a);
            }
            1;
        } or $private_error = $@;
        if ($admitted{$name}) {
            ok($lowered && !defined($lower_error), 'supported authored/unused control still lowers') or diag($lower_error);
            ok($ir && !defined($private_error), 'supported control has complete private product') or diag($private_error);
            is($ir->{states}[0]{kind}, 'entry', 'authored activation entry remains');
        } else {
            my $reason = $name eq 'repeat_control' ? "unsupported '(when ...)' clause in repeat body"
                : "unsupported '(cond ...)' clause";
            ok(!defined($lowered), 'unqualified source cannot produce admitted artifacts');
            like($lower_error // '', qr/\Q$reason\E/, 'literal current source refusal');
            ok(!defined($ir), 'private preparation also refuses') or diag($private_error);
            like($private_error // '', qr/\Q$reason\E/, 'same private source boundary');
        }
        is(read_file($path), $source, 'entire supplied source stays byte exact');
        if (my $capture = $ENV{FSMGEN_PROC_COND_BOUNDARY_CAPTURE}) {
            write_file("$capture/$name.json", $json->encode(normalize_repository_paths({
                source => $source, actor => $json->decode($before), lowered => $lowered,
                lower_error => $lower_error, private_ir => $ir, private_error => $private_error,
            }, abs_path('.'))) . "\n");
        }
    };
}
done_testing;

sub has_cond {
    my ($node) = @_;
    return 0 unless ref($node) eq 'ARRAY';
    return 1 if @$node && defined($node->[0]) && !ref($node->[0]) && $node->[0] eq 'cond';
    return scalar grep {has_cond($_)} @$node;
}
sub read_file {open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
