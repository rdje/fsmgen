use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Adapter::ISF::Parser;
use FSM::Test::SameSourceLibraryOriginParser;
use FSM::Test::ConditionalOriginAuthority;

{
    package FSM::Test::LibraryLateTargetMutation;
    use parent 'FSM::Test::SameSourceLibraryOriginParser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        $actor->{transactions}[0]{clauses}[0][1] = 'start';
        return $result;
    }
}

my $json = JSON::PP->new->canonical;
my %bodies = (
    select => '(select seen allow datain other)',
    min => '(min seen datain other)', max => '(max seen datain other)',
    'when-bit' => '(when-bit datain 1 (sample other as captured))',
    'unless-bit' => '(unless-bit datain 1 (sample other as captured))',
    'when-field' => '(when-field datain (bits 2 1) 1 (sample other as captured))',
    'unless-field' => '(unless-field datain (bits 2 1) 1 (sample other as captured))',
    cond => '(cond (allow (sample datain as captured)) (else (sample other as saved)))',
    authored => '(when allow (sample datain as captured))',
    proc_select => '(call choose allow)', proc_cond => '(call choose allow)',
);
my @cases;
for my $family (qw(select min max when-bit unless-bit when-field unless-field cond authored proc_select proc_cond)) {
    for my $position (qw(first later)) {
        push @cases, {name => "${position}_$family", family => $family, position => $position};
    }
}
push @cases, {name => 'reused_export', family => 'proc_select', position => 'later', reuse => 1};
push @cases, {name => 'identical_export_twins', family => 'select', position => 'later', twins => 1};
is(scalar @cases, 24, 'fixed complete same-source producer cohort');
my %guards = (
    select => ['allow', ['!', 'allow']], min => [['<=','datain','other'],['!',['<=','datain','other']]],
    max => [['>=','datain','other'],['!',['>=','datain','other']]],
    'when-bit' => [['!=',['&','datain',"3'd2"],"3'd0"]],
    'unless-bit' => [['==',['&','datain',"3'd2"],"3'd0"]],
    'when-field' => [['==',['&','datain',"3'd6"],"3'd2"]],
    'unless-field' => [['!=',['&','datain',"3'd6"],"3'd2"]],
    cond => ['allow',['!','allow']], authored => ['allow'], proc_select => ['allow',['!','allow']],
);

for my $case (@cases) {
    subtest "canonical library origin $case->{name}" => sub {
        my $source = source_for($case);
        my $label = "$case->{name}.isf";
        my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($source, $label);
        my $before = $json->encode($ordinary);
        my $parser = FSM::Test::SameSourceLibraryOriginParser->new;
        my $actor = $parser->parse_source($source, $label);
        my $proof = $parser->proof;
        is($json->encode($actor), $before, 'complete real ordinary actor and original JSON kinds unchanged');
        is($proof->{source_sha256}, sha256_hex($source), 'whole original document identity');
        is($proof->{source_label}, $label, 'original relative source label');
        is($proof->{actor_sha256}, sha256_hex($before), 'complete final actor identity');
        is($proof->{root_actor_id}, 0, 'actual root producer precedes library constructors');
        is(scalar @{$proof->{actors}}, 3, 'literal complete root plus two actual actor products');
        my $root = $proof->{actors}[0];
        is($root->{actor_name}, 'library_top', 'authored root identity');
        is($root->{library}, undef, 'root has no invented library namespace');
        is_deeply([map {$root->{ledger}{catalog}[$_->{origin}{catalog_id}]{operation}} @{$root->{ledger}{entries}}],
            ['when'], 'root authored when remains separate from child macros');
        is(scalar @{$proof->{uses}}, 2, 'literal complete canonical clone edges');
        is_deeply([map {$_->{instance}} @{$proof->{uses}}], ['first','second'], 'authored distinct use identities');
        is_deeply([map {$_->{module}} @{$proof->{uses}}], ['library_top__first','library_top__second'],
            'literal canonical clone modules retained without interpreting names');
        is_deeply([map {$_->{parameter_overrides}} @{$proof->{uses}}],
            [[{name => 'WIDTH', value => '2'}],[{name => 'WIDTH', value => '3'}]], 'actual independent use parameters');
        for my $i (0 .. 1) {
            my $edge = $proof->{uses}[$i];
            my $record = $proof->{actors}[$edge->{actor_id}];
            my $actual = $actor->{library_uses}[$i];
            is($json->encode([map {$_->{width}} @{$actual->{actor}{interface}{inputs}}]), '[1,1,"3","3"]',
                'literal original private input kinds retain defaults and authored width tokens');
            is_deeply($edge->{path}, ['library_uses',$i,'actor'], 'literal actual whole-clone path');
            is($edge->{source_label}, $label, 'canonical selected library retains original document');
            is($record->{source_label}, $label, 'original actor producer document matches selected export');
            is($record->{library}, $edge->{library}, 'canonical export reference retains declared library');
            is($record->{actor_name}, $edge->{export}, 'canonical export reference retains declared actor');
            is($json->encode($edge->{target}), $json->encode($actual->{actor}), 'whole actual clone retained');
            is($json->encode($record->{actor}), $json->encode($actual->{actor}), 'complete original actor survives canonical cloning');
            is($json->encode($edge->{ledger}), $json->encode($record->{ledger}), 'whole plain source ledger follows selected export');
            my $family = $case->{twins} && $i == 1 ? 'twin_authored' : $case->{family};
            my $ledger = $edge->{ledger};
            my $op = $family eq 'authored' || $family eq 'twin_authored' ? 'when'
                : $family eq 'proc_select' ? 'select' : $family eq 'proc_cond' ? 'cond' : $family;
            my $count = $op =~ /\A(?:select|min|max|cond)\z/ ? 2 : $family eq 'twin_authored' ? 2 : 1;
            my $entries = $family eq 'proc_cond' ? $ledger->{residuals} : $ledger->{entries};
            $count = 1 if $family eq 'proc_cond';
            is_deeply([map {$ledger->{catalog}[$_->{origin}{catalog_id}]{operation}} @$entries],
                [($op) x $count], 'independent original source family, not normalized-body inference');
            is_deeply([map {$ledger->{catalog}[$_->{origin}{catalog_id}]{owner}{kind}} @$entries],
                [(($family =~ /proc/ ? 'procedure' : 'transaction')) x $count], 'literal original owner kind');
            if ($family ne 'proc_cond') {
                my $expected = $family eq 'twin_authored' ? ['allow',['!','allow']] : $guards{$family};
                is_deeply([map {$_->{target}[1]} @$entries], $expected, 'independent complete literal normalized guards');
            }
            for my $entry (@$entries) {
                my $node = $actual->{actor};
                $node = ref($node) eq 'HASH' ? $node->{$_} : $node->[$_] for @{$entry->{path}};
                is($json->encode($node), $json->encode($entry->{target}), 'complete actual cloned conditional target resolves');
                is(scalar @{$entry->{origin}{calls}}, $family =~ /proc/ ? 1 : 0, 'literal real inline call depth');
            }
            ok(FSM::Test::ConditionalOriginParser->new->validate($actual->{actor}, $ledger),
                'complete cloned normalized path coverage validates structurally, without authentication claim');
        }
        if ($case->{reuse}) {
            is($proof->{uses}[0]{actor_id}, $proof->{uses}[1]{actor_id}, 'two actual clones select one original export producer');
            isnt($proof->{uses}[0]{instance}, $proof->{uses}[1]{instance}, 'reused export preserves distinct actual instances');
        }
        if ($case->{twins}) {
            is($json->encode($proof->{uses}[0]{target}), $json->encode($proof->{uses}[1]{target}),
                'distinct libraries have identical complete exported actors');
            isnt($proof->{uses}[0]{library}, $proof->{uses}[1]{library}, 'declared libraries retain distinct producer namespaces');
            isnt($proof->{uses}[0]{actor_id}, $proof->{uses}[1]{actor_id}, 'identical names/bodies cannot merge actual source producers');
        }
        my $copy = $parser->proof;
        $copy->{uses}[0]{instance} = 'forged';
        is($json->encode($parser->proof), $json->encode($proof), 'returned proof detached from producer');
        is($json->encode($json->decode($json->encode($proof))), $json->encode($proof), 'full proof survives opaque JSON cloning');
        is($json->encode($ordinary), $before, 'original complete ordinary product untouched');
        if (my $capture = $ENV{FSMGEN_LIBRARY_ORIGIN_CAPTURE}) {
            write_file("$capture/$case->{name}.json", $json->encode({case => $case, source => $source, label => $label,
                ordinary => $ordinary, instrumented => $actor, proof => $proof}) . "\n");
        }
    };
}

subtest 'unqualified authorities stay explicitly closed' => sub {
    for my $case (
        ['external', '(actor closed (clock clk) (interface (input start) (output done)) (imports (library missing.lib as lib)) (use lib.worker as child (bind (clock clk) (input start start) (output done done))))', qr/external document authority is not qualified/],
        ['package', '(actor closed (imports (package pkg)))', qr/package source authority is not qualified/],
        ['ATL', '(actor closed (instance child of Worker))', qr/ATL source authority is not qualified/],
    ) {
        my ($name, $source, $reason) = @$case;
        ok(!eval {FSM::Test::SameSourceLibraryOriginParser->new->parse_source($source, 'closed.isf'); 1}, "$name authority remains closed");
        like($@, $reason, 'precise private boundary');
    }
    ok(!eval {FSM::Test::ConditionalOriginAuthority->from_source(source_for($cases[0]), 'closed.isf'); 1},
        'local reload consumer still refuses imports despite detached producer qualification');
    like($@, qr/imported source authority is not qualified/, 'no accidental adoption');
    for my $label ('/foreign/probe.isf', '../probe.isf') {
        ok(!eval {FSM::Test::SameSourceLibraryOriginParser->new->parse_source(source_for($cases[0]), $label); 1},
            'non-repository-relative source identity refuses');
        like($@, qr/repository-relative source label/, 'precise relative-identity boundary');
    }
};
subtest 'canonical finalization cannot leave stale root clause origins' => sub {
    ok(!eval {FSM::Test::LibraryLateTargetMutation->new->parse_source(source_for($cases[0]), 'late.isf'); 1},
        'actual changed target refuses before frozen proof publication');
    like($@, qr/conditional origin target identity mismatch/, 'precise complete target identity boundary');
};
done_testing;

sub source_for {
    my ($case) = @_;
    my $prefix = $case->{position} eq 'later' ? '(on start)' : '';
    my $body = $bodies{$case->{family}};
    my $proc = $case->{family} eq 'proc_select' ? '(proc choose (params (c)) (select seen c datain other))'
        : $case->{family} eq 'proc_cond' ? '(proc choose (params (c)) (cond (c (sample datain as captured)) (else (sample other as saved))))' : '';
    my $actor = sub {
        my ($name, $clauses, $procedure) = @_;
        return "(actor $name (params (WIDTH 1)) (clock clk)"
            . ' (interface (input start) (input allow) (input datain (width 3)) (input other (width 3)) (output done))'
            . " (storage (var seen (width 3))) $procedure (transaction main $prefix $clauses (complete done)))";
    };
    my $library = '(library common.choice (exports (actor worker) (actor mirror)) '
        . $actor->('worker', $body, $proc) . ' ' . $actor->('mirror', $body, $proc) . ')';
    my $second = $case->{reuse} ? 'lib.worker' : 'lib.mirror';
    my $imports = '(library common.choice as lib)';
    if ($case->{twins}) {
        my $authored = '(when allow (set seen datain)) (when (! allow) (set seen other))';
        $library = '(library common.choice (exports (actor worker)) ' . $actor->('worker', $body, '') . ')'
            . ' (library common.second (exports (actor worker)) ' . $actor->('worker', $authored, '') . ')';
        $imports .= ' (library common.second as other_lib)';
        $second = 'other_lib.worker';
    }
    my $bind = '(clock clk) (input start start) (input allow allow) (input datain datain) (input other other)';
    return '(actor library_top (clock clk)'
        . ' (interface (input start) (input allow) (input datain (width 3)) (input other (width 3))'
        . ' (output first_done) (output second_done) (output parent_done))'
        . " (imports $imports)"
        . " (use lib.worker as first (params (WIDTH 2)) (bind $bind (output done first_done)))"
        . " (use $second as second (params (WIDTH 3)) (bind $bind (output done second_done)))"
        . ' (transaction main (when allow (sample datain as captured_parent)) (complete parent_done))) '
        . $library;
}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
