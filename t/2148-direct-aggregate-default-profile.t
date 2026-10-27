use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Backend::VerilogFamily::ParameterBindingEmitter;

my $renderer = 'FSM::Backend::VerilogFamily::ParameterBindingEmitter';
ok($renderer->can('lower_default'), 'direct aggregate default profile exists') or do {
    done_testing(); exit;
};
my $json = JSON::PP->new->canonical;
my $text = q{
(?fsm:aggregate_default_profile
  (+constants
    (PAIR (8'hA5 8'h3C))
    (SMALL (8'h01 8'h02))
    (RECORD ((mode 2'b10) (flag 1'b1))))
  (+params
    (W 16) (ALIAS W)
    (ITEMS (8'hA5 8'h3C))
    (FRAME ((mode 2'b10) (data (4'hA 4'h3))))
    (STATIC PAIR) (STATIC_RECORD RECORD) (SUM (+ PAIR SMALL)) (INVERT (~ PAIR))
    (MATCH (== PAIR PAIR)) (DIFFERENT (!= PAIR SMALL))
    (STATIC_PATH PAIR[1])
    (MIXED (+ (== PAIR PAIR) W))
    (COPY ITEMS) (LEAF ITEMS[1]) (COMPARE (== ITEMS ITEMS))
    (MUTABLE_LIST (W 8'h02))
    (MUTABLE_MAP ((data ITEMS) (mode 2'b10)))))
};
my $raw = Lispish::multi(\$text);
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw);
my $bindings = $module->parameter_default_bindings;
my $environment = {scope => {kind => 'direct_module', owner => 'aggregate_default_profile'},
    declaration_order => [sort keys %{$module->parameters}], parameters => $module->parameters};
my $before = $json->encode([$raw, $environment, $bindings]);
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
sub lower {
    return $renderer->lower_default(binding => $_[0], environment => $_[1] // $environment,
        target_language => $_[2] // 'systemverilog');
}

subtest 'immutable aggregates fold from captured meaning and scalar relationships survive' => sub {
    my %expected = (
        ITEMS => ["16'b1010010100111100", []],
        FRAME => ["10'b1010100011", []],
        STATIC => ["16'b1010010100111100", []],
        STATIC_RECORD => ["3'b101", []],
        SUM => ["16'b1010011000111110", []],
        INVERT => ["16'b0101101011000011", []],
        MATCH => ["1'b1", []], DIFFERENT => ["1'b1", []],
        STATIC_PATH => ["8'h3C", []],
        MIXED => ["(1'b1 + W)", ['W']], ALIAS => ['W', ['W']], W => ['16', []],
    );
    for my $language (qw(systemverilog verilog)) {
        for my $name (sort keys %expected) {
            my $actual = lower($bindings->{$name}, undef, $language);
            is($json->encode($actual), $json->encode({text => $expected{$name}[0],
                parameter_references => $expected{$name}[1]}), "$language $name has independently expected bits and names");
            $capture{results}{$language}{$name} = $actual;
        }
    }
    my $changed = copy($environment);
    $changed->{parameters}{STATIC}{value_text} = "16'b0";
    $changed->{parameters}{STATIC}{value_payload}{items}[0]{payload} = "8'h00";
    is(lower($bindings->{STATIC}, $changed)->{text}, "16'b1010010100111100", 'selected caches cannot replace captured static meaning');
    my $intervened = copy($bindings->{STATIC});
    $intervened->{value_payload}{items}[0]{payload} = "8'h00";
    is(lower($intervened)->{text}, "16'b0000000000111100", 'changed actual captured input changes emitted bits');
    is($json->encode([$raw, $environment, $bindings]), $before, 'complete caller values and JSON kinds are conserved');
    my $result = lower($bindings->{MIXED}); $result->{parameter_references}[0] = 'WRONG';
    is_deeply(lower($bindings->{MIXED})->{parameter_references}, ['W'], 'returned dependency lists are detached');
};

subtest 'mutable aggregate defaults refuse including scalar comparison results' => sub {
    is($environment->{parameters}{COMPARE}{value_kind}, 'scalar', 'actual comparison is a scalar result with aggregate operands');
    for my $name (qw(COPY LEAF COMPARE MUTABLE_LIST MUTABLE_MAP)) {
        my $ok = eval {lower($bindings->{$name}); 1}; my $error = $@;
        ok(!$ok, "$name cannot silently freeze mutable relationships");
        like($error, qr/(?:aggregate|selection).*mutable parameter|mutable parameter.*(?:aggregate|selection)/i,
            "$name names the unsupported mutable aggregate profile");
        like($error, qr/(?:ITEMS|W)/, "$name names the actual declared dependency");
        $capture{refusals}{$name} = $error;
    }
    is($json->encode([$raw, $environment, $bindings]), $before, 'refusals preserve complete callers');
};

subtest 'malformed static and canonical structures refuse without trusting cached values' => sub {
    for my $case (
        ['foreign static scope', sub {$_[0]{STATIC}{scope}{owner} = 'other'}, 'STATIC', qr/scope/],
        ['missing ordered map member', sub {pop @{$_[0]{FRAME}{member_order}}}, 'FRAME', qr/map.*member|member.*map/],
        ['duplicate ordered map member', sub {push @{$_[0]{FRAME}{member_order}}, 'mode'}, 'FRAME', qr/map.*member|member.*map/],
        ['empty list', sub {$_[0]{ITEMS}{items} = []}, 'ITEMS', qr/list.*items|non-empty/],
        ['raw nested static text', sub {$_[0]{STATIC}{value_payload}{items}[0] = {kind => 'scalar_expr', payload => '(W + 1)'}}, 'STATIC', qr/scalar_expr|literal payload/],
        ['inconsistent source operator', sub {$_[0]{SUM}{source_operator} = '-'}, 'SUM', qr/operator/],
        ['unknown nested kind', sub {$_[0]{FRAME}{members}{mode}{kind} = 'raw_hdl'}, 'FRAME', qr/canonical kind/],
        ['incomplete static map order', sub {pop @{$_[0]{STATIC_RECORD}{value_payload}{member_order}}}, 'STATIC_RECORD', qr/map.*member|member.*map/],
        ['inconsistent mutable path token', sub {$_[0]{LEAF}{token} = 'OTHER[1]'}, 'LEAF', qr/token|selection/],
    ) {
        my ($label, $change, $name, $reason) = @$case;
        my $input = copy($bindings); $change->($input); my $old = $json->encode($input);
        my $ok = eval {lower($input->{$name}); 1}; my $error = $@;
        ok(!$ok, "$label refuses"); like($error, $reason, "$label identifies its boundary");
        is($json->encode($input), $old, "$label preserves caller JSON kinds");
        $capture{malformed}{$label} = $error;
    }
    my $composition = copy($environment); $composition->{scope}{kind} = 'composition_top';
    my $ok = eval {lower($bindings->{ITEMS}, $composition); 1};
    ok(!$ok, 'direct profile does not admit composition scope'); like($@, qr/direct.module scope/, 'scope boundary is explicit');
    $ok = eval {lower($bindings->{ITEMS}, undef, 'vhdl'); 1};
    ok(!$ok, 'unsupported target refuses'); like($@, qr/Verilog-family/, 'target boundary is explicit');
    for my $cycle (
        {kind => 'list', items => []},
        {kind => 'payload', value => {kind => 'list', items => []}},
    ) {
        my $payload = $cycle->{kind} eq 'payload' ? $cycle->{value} : $cycle;
        push @{$payload->{items}}, $payload;
        $ok = eval {lower($cycle); 1}; my $error = $@;
        ok(!$ok, 'recursive binding or payload refuses'); like($error, qr/cyclic/, 'cycle identifies its cause');
        $payload->{items} = [];
    }
};

if (my $path = $ENV{FSMGEN_AGGREGATE_DEFAULT_PROFILE_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode({%capture, bindings => $bindings, environment => $environment}), "\n" or die $!;
    close $out or die $!;
}
done_testing();
