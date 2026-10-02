use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Adapter::ISF::Parser;
use FSM::Test::ConditionalOriginParser;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/conditional-macro-intent-20261002';
my $cases = $json->decode(read_file("$base/cases.json"));
my @families = qw(select min max when_bit unless_bit when_field unless_field cond);
my @names = ((map {("first_$_", "later_$_")} @families),
    (map {("first_${_}_sample", "later_${_}_sample")} qw(when_bit unless_bit when_field unless_field cond)),
    (map {("first_proc_$_", "later_proc_$_")} qw(select when_bit cond)));
push @names, qw(first_proc_when_sample first_when_sample first_select_zero first_bit_sample_zero
    initialized_select nested_select domain_first_select domain_later_select domain_first_sample
    first_generated_select later_generated_select);
is_deeply([sort map {$_->{name}} @$cases], [sort @names], 'fixed full predecessor source membership');
for my $case (@$cases) {
    my $name = $case->{name};
    subtest "explicit actual parser origin $name" => sub {
        my $path = "$base/sources/$name.isf";
        my ($actor, $ledger, $parser) = qualify($name, read_file($path), $path);
        my $op = $case->{family};
        $op =~ tr/_/-/;
        $op = 'when' if $case->{family} eq 'authored_when';
        my @ops = map {$ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @{$ledger->{entries}};
        if ($name eq 'first_proc_cond' || $name eq 'later_proc_cond') {
            is_deeply(\@ops, [], 'inline cond remains unnormalized, never relabeled as activation');
            is_deeply([map {$ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @{$ledger->{residuals}}],
                ['cond'], 'actual unsupported inline cond has explicit residual origin');
        } else {
            my $count = $op =~ /\A(?:select|min|max|cond)\z/ ? 2 : 1;
            my @expected = (($op) x $count);
            unshift @expected, 'when' if $name eq 'nested_select';
            is_deeply(\@ops, \@expected, 'literal authored family survives all canonical rewrites');
            is_deeply($ledger->{residuals}, [], 'supported normalization has no residual conditional');
            my @ordinals = map {$_->{origin}{branch_ordinal}} @{$ledger->{entries}};
            my @expected_ordinals = $op eq 'when' ? (undef) : $count == 2 ? (0, 1) : (0);
            unshift @expected_ordinals, undef if $name eq 'nested_select';
            is_deeply(\@ordinals, \@expected_ordinals, 'literal full expansion ordinal association');
        }
        for my $entry (@{$ledger->{entries}}, @{$ledger->{residuals}}) {
            my $origin = $entry->{origin};
            my $record = $ledger->{catalog}[$origin->{catalog_id}];
            is($record->{owner}{kind}, $name =~ /proc/ ? 'procedure' : 'transaction',
                'literal original owner kind');
            is(scalar(@{$origin->{calls}}), $name =~ /proc/ ? 1 : 0, 'literal inline call depth');
        }
        mutation_controls($actor, $ledger, $parser) if @{$ledger->{entries}};
    };
}

my $header = '(actor origin_probe (interface (input start) (input allow) (input datain (width 3))'
    . ' (input other (width 3)) (output done)) (storage (var seen (width 3))) ';
my $select_source = $header . '(transaction main (on start) (select seen allow datain other) (complete done)))';
my $authored_source = $header . '(transaction main (on start) (when allow (set seen datain))'
    . ' (when (! allow) (set seen other)) (complete done)))';
subtest 'identical normalized clauses retain different source intent' => sub {
    my ($macro_actor, $macro_ledger) = qualify('twin_macro', $select_source, 'twin.isf');
    my ($authored_actor, $authored_ledger) = qualify('twin_authored', $authored_source, 'twin.isf');
    is($json->encode($macro_actor), $json->encode($authored_actor), 'complete normalized actors are identical');
    is_deeply([map {$macro_ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @{$macro_ledger->{entries}}],
        ['select', 'select'], 'macro ledger comes from actual select producer');
    is_deeply([map {$authored_ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @{$authored_ledger->{entries}}],
        ['when', 'when'], 'authored ledger comes from original when clauses');
};

my @extra = (
    ['let_select', '(transaction main (let pick allow) (select seen pick datain other) (complete done))', ['select','select'], [0,0]],
    ['for_select', '(transaction main (for (i 2) (select seen allow datain other)) (complete done))', ['select','select'], [0,0]],
    ['while_field', '(transaction main (while allow (when-field datain (bits 2 1) 1 (sample other as captured))) (complete done))', ['when-field'], [0]],
    ['repeat_bit', '(transaction main (repeat 2 (unless-bit datain 1 (sample other as captured))) (complete done))', ['unless-bit'], [0]],
    ['switch_cond', '(transaction main (switch datain (0 (cond (allow (set seen datain)) (else (set seen other))))) (complete done))', ['cond','cond'], [0,0]],
    ['nested_calls', '(proc inner (params (c)) (select seen c datain other)) (proc outer (params (c)) (call inner c)) (transaction main (call outer allow) (complete done))', ['select','select'], [2,2]],
    ['reused_calls', '(proc choose (params (c)) (when c (sample datain as captured))) (transaction main (call choose allow) (call choose start) (complete done))', ['when','when'], [1,1]],
    ['nested_cond', '(transaction main (cond (allow (cond (start (set seen datain)) (else (set seen other)))) (else (set seen 0))) (complete done))', ['cond','cond','cond','cond'], [0,0,0,0]],
);
my %extra_guards = (
    let_select => ['allow', ['!', 'allow']],
    for_select => ['allow', ['!', 'allow']],
    while_field => [['==', ['&', 'datain', "3'd6"], "3'd2"]],
    repeat_bit => [['==', ['&', 'datain', "3'd2"], "3'd0"]],
    switch_cond => ['allow', ['!', 'allow']],
    nested_calls => ['allow', ['!', 'allow']],
    reused_calls => ['allow', 'start'],
    nested_cond => ['allow', 'start', ['!', 'start'], ['!', 'allow']],
);
for my $extra (@extra) {
    my ($name, $body, $ops, $depths) = @$extra;
    subtest "source context $name" => sub {
        my ($actor, $ledger) = qualify($name, $header . $body . ')', "$name.isf");
        is_deeply([map {$ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @{$ledger->{entries}}], $ops,
            'independent exact operation order');
        is_deeply([map {scalar @{$_->{origin}{calls}}} @{$ledger->{entries}}], $depths,
            'independent exact call depths');
        is_deeply([map {$_->{target}[1]} @{$ledger->{entries}}], $extra_guards{$name},
            'independent complete normalized guard values');
        if ($name eq 'nested_calls') {
            is_deeply([map {$_->{procedure}} @{$ledger->{entries}[0]{origin}{calls}}],
                ['outer', 'inner'], 'full literal ordered nested call chain');
            is_deeply([map {$_->{context}} @{$ledger->{entries}[0]{origin}{calls}}],
                ["transaction 'main'", "transaction 'main' -> proc 'outer'"],
                'full literal actual call contexts');
        }
        if ($name eq 'reused_calls') {
            isnt($ledger->{entries}[0]{origin}{calls}[0]{catalog_id},
                $ledger->{entries}[1]{origin}{calls}[0]{catalog_id},
                'same definition retains two distinct actual source call sites');
            is_deeply([map {$_->{target}[1]} @{$ledger->{entries}}], ['allow','start'],
                'each substituted guard remains bound to its own caller');
        }
        for my $entry (@{$ledger->{entries}}) {
            my $target = $actor;
            $target = ref($target) eq 'HASH' ? $target->{$_} : $target->[$_] for @{$entry->{path}};
            is($json->encode($target), $json->encode($entry->{target}), 'direct actual-offset path resolves complete target');
        }
    };
}

subtest 'first sample-procedure cond stays publicly closed' => sub {
    my $path = 'docs/audits/procedure-cond-normalization-20261002/sources/first_samples.isf';
    my ($actor, $ledger) = qualify('first_samples', read_file($path), $path);
    is_deeply($ledger->{entries}, [], 'no fabricated when association');
    is(scalar @{$ledger->{residuals}}, 1, 'whole original cond remains explicit residual');
    my $before = $json->encode($actor);
    my $result = eval {FSM::Scheduler::ISF->new->lower($actor)};
    ok(!defined($result), 'detached ledger creates no public admission');
    ok(diagnostic_cause_matches($@, "Transaction 'main': unsupported '(cond ...)' clause in transaction body"), 'same precise committed source refusal');
    is($json->encode($actor), $before, 'failed lower preserves full actual actor');
};
done_testing;

sub qualify {
    my ($name, $source, $label) = @_;
    my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($source, $label);
    my $before = $json->encode($ordinary);
    my $parser = FSM::Test::ConditionalOriginParser->new;
    my $actor = $parser->parse_source($source, $label);
    is($json->encode($actor), $before, 'complete actual actor and primitive JSON kinds unchanged');
    my $ledger = $parser->ledger;
    ok($parser->validate($actor, $ledger), 'complete explicit association validates');
    ok($parser->validate($json->decode($before), $json->decode($json->encode($ledger))),
        'full actor/ledger JSON cloning retains association');
    is($ledger->{source_sha256}, sha256_hex($source), 'whole supplied source identity retained');
    is($json->encode($ordinary), $before, 'ordinary original actor untouched');
    my $snapshot = $json->encode($ledger);
    my $detached = $parser->ledger;
    $detached->{schema_version} = 9;
    is($json->encode($parser->ledger), $snapshot, 'returned ledger is detached from producer authority');
    if (my $capture = $ENV{FSMGEN_CONDITIONAL_ORIGIN_CAPTURE}) {
        write_file("$capture/$name.json", $json->encode({source => $source, label => $label,
            ordinary => $ordinary, instrumented => $actor, ledger => $ledger}) . "\n");
    }
    return ($actor, $ledger, $parser);
}
sub mutation_controls {
    my ($actor, $ledger, $parser) = @_;
    my %expected = (
        omission => 'conditional origin incomplete coverage',
        duplicate => 'conditional origin missing, extra or duplicate path',
        wrong_path => 'conditional origin missing, extra or duplicate path',
        changed_target => 'conditional origin target identity mismatch',
        forged_origin => 'conditional origin differs from the actual producer result',
        source_identity => 'conditional origin differs from the actual producer result',
        unknown_field => 'conditional origin unknown or missing fields',
        schema_kind => 'conditional origin schema mismatch',
    );
    for my $name (qw(omission duplicate wrong_path changed_target forged_origin source_identity unknown_field schema_kind)) {
        my $bad = $json->decode($json->encode($ledger));
        if ($name eq 'omission') {shift @{$bad->{entries}}}
        elsif ($name eq 'duplicate') {push @{$bad->{entries}}, $bad->{entries}[0]}
        elsif ($name eq 'wrong_path') {$bad->{entries}[0]{path}[-1] = 9999}
        elsif ($name eq 'changed_target') {$bad->{entries}[0]{target}[1] = 'other'}
        elsif ($name eq 'forged_origin') {$bad->{entries}[0]{origin}{calls} = [];
            $bad->{catalog}[$bad->{entries}[0]{origin}{catalog_id}]{owner}{name} = 'forged'}
        elsif ($name eq 'source_identity') {$bad->{source_sha256} = '0' x 64}
        elsif ($name eq 'unknown_field') {$bad->{entries}[0]{extra} = 1}
        else {$bad->{schema_version} = '1'}
        ok(!eval {$parser->validate($actor, $bad); 1}, "$name is actually rejected");
        ok(diagnostic_cause_matches($@, $expected{$name}), 'complete mutation-specific association cause');
    }
}
sub read_file {open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
