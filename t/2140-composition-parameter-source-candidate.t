use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::PlanBuilder;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
my $method = FSM::Composition::PlanBuilder->can('assert_parameter_source_candidate');
ok($method, 'bounded parameter-source candidate check exists');
unless ($method) { done_testing; exit }

sub resolved_top {
    my ($body) = @_;
    my $text = "(?top:candidate (+import shared) $body) (?pkg:shared (+constants (BASE 8)))";
    my $raw = Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $spec = FSM::Composition::Parser->new->parse_source($raw);
    FSM::Composition::PackageImportResolver->resolve_imports(
        composition_spec => $spec,
        fsm_file => 't/2140-composition-parameter-source-candidate.t',
        source_path_resolver => FSM::SourcePathResolver->new);
    is($json->encode($raw), $before, 'source caller remains unchanged');
    return $spec->top;
}
sub candidate {
    FSM::Composition::PlanBuilder->assert_parameter_source_candidate(top => $_[0]);
}

subtest 'actual scalar declarations and immutable widths are candidates only' => sub {
    for my $body (
        '(+params (COPY W) (W shared.BASE) (SAME 8)) (?rtl:child (params (COUNT COPY)))',
        '(+params (W 8)) (?ports (input data (width (+ shared.BASE 1)))) (?rtl:child)',
        '(+params (W 8)) (?ports data<8) (?rtl:left) (?rtl:right)',
    ) {
        my $top = resolved_top($body);
        my $before = $json->encode($top->parameter_environment);
        ok(candidate($top), 'actual fixed-interface RTL source is a candidate');
        is($json->encode($top->parameter_environment), $before, 'candidate check cannot change environment kinds or values');
    }
    my $empty = resolved_top('(+params (W 8))');
    ok(candidate($empty), 'existing lane checks still own missing children');
};

subtest 'source dependencies distinguish equal defaults and unsupported shapes' => sub {
    for my $case (
        ['generated FSM', '(+params (W 8)) (?fsmc:child leaf)', qr/generated child 'child'.*generic interface preservation/],
        ['generated DT', '(+params (W 8)) (?dtc:child leaf)', qr/generated child 'child'.*generic interface preservation/],
        ['mixed children', '(+params (W 8)) (?rtl:external) (?fsmc:child leaf)', qr/generated child 'child'/],
        ['aggregate default', q{(+params (LANES (8'hA5 8'h3C))) (?rtl:child)}, qr/parameter 'LANES'.*scalar top defaults/],
        ['parameter width', '(+params (W 8)) (?ports (input data (width (param W)))) (?rtl:child)', qr/port 'data'.*parameter-dependent width/],
        ['alias width', '(+params (COPY W) (W 8)) (?ports (input data (width (param COPY)))) (?rtl:child)', qr/port 'data'.*parameter-dependent width/],
        ['nested width', '(+params (W 8)) (?ports (input data (width (+ shared.BASE (param W))))) (?rtl:child)', qr/port 'data'.*parameter-dependent width/],
    ) {
        my ($label, $body, $pattern) = @$case;
        my $top = resolved_top($body);
        my $before = $json->encode($top->parameter_environment);
        my $ok = eval {candidate($top); 1}; my $error = $@;
        ok(!$ok, "$label refuses");
        like($error, qr/Composition top 'candidate' top parameter lowering is blocked because/, "$label retains classified diagnostic prefix");
        like($error, $pattern, "$label names the unresolved interface or declaration");
        is($json->encode($top->parameter_environment), $before, "$label preserves environment kinds and values");
    }
};

subtest 'static lanes and unresolved parameter environments retain their owners' => sub {
    my $static = resolved_top('(?fsmc:child leaf)');
    ok(candidate($static), 'ordinary static generated source bypasses parameter gate');
    my $text = '(?top:unresolved (+params (W 8)) (?rtl:child))';
    my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi(\$text));
    my $ok = eval {candidate($spec->top); 1};
    ok(!$ok, 'unresolved actual source cannot borrow a numeric default');
    like($@, qr/requires resolved defaults and bindings/, 'actual environment producer identifies missing resolution');
};

done_testing;
