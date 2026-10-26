use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir tempfile);
use Lispish;
use FSM::Adapter::ISF;
use FSM::Adapter::FSMGenFull;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::Emitter::FSM;

my $json = JSON::PP->new->canonical;
my $actor = FSM::Adapter::ISF->new->parse_file('t/data/isf-width-symbols/bindings.isf');
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $ir = $scheduler->{ir}->build_module($actor);
my $products = {actor => $actor, ir => $ir, files => $scheduler->lower($actor)->{files},
    report => $scheduler->report($actor)};
my $capture = $json->encode($products);
my $child = $ir->{children}{worker};
my $plan = $child->{_width_symbols};

subtest 'final module namespaces determine target names without replacing source identities' => sub {
    ok(ref($plan) eq 'HASH', 'actual child constructor has a private target symbol plan');
    return unless ref($plan) eq 'HASH';
    is_deeply($plan->{widths}, {data => ['param', 'LOCAL_ALIAS'], response => ['param', 'BASE'],
        fixed => ['+', 'FIXED', '0']}, 'parameters are explicit and a static width bypasses the same-named type');
    is_deeply($plan->{capture_parameters}, [{name => 'isf_width_capture_5', value => '8',
        source => {kind => 'capture', scope => {kind => 'actor', owner => 'width_symbols'}, token => 'ACTOR_ALIAS'}}],
        'port, type, enum and actual parameter names are reserved before capture allocation');
    is_deeply([map {[$_->{name}, $_->{value}, $_->{source}{kind}, $_->{source}{token}]} @{$plan->{constants}}], [
        ['isf_width_static_4', 8, 'enum_member', 'mode.EIGHT'],
        ['isf_width_static_5', 8, 'enum_member', 'shared.mode.EIGHT'],
        ['isf_width_static_6', 8, 'package_constant', 'shared.WIDTH']],
        'only ambiguous static defaults acquire immutable aliases with selected identities');
    my $defaults = $plan->{parameter_defaults};
    is_deeply({map {$_ => $defaults->{$_}} qw(LOCAL_ALIAS A C P E PE SHADOW_ALIAS)}, {
        LOCAL_ALIAS => 'BASE', A => 'isf_width_capture_5',
        C => 'FIXED', P => 'isf_width_static_6', E => 'isf_width_static_4',
        PE => 'isf_width_static_5', SHADOW_ALIAS => 'SHADOW'}, 'default graph preserves real aliases and static/local shadowing');
    is_deeply($defaults->{LANES}, ['BASE', 'isf_width_capture_5', 'FIXED', 'isf_width_static_6',
        'isf_width_static_4', ['8', 'SHADOW']], 'nested default lists retain shape and token kinds');
    is($json->encode($actor), $before, 'complete source caller is unchanged');
    unlike($products->{report}, qr/"_width_symbols"\s*:/, 'symbol plan remains private');
};

subtest 'selected plans use existing canonical IAL0 declarations and expression grammar' => sub {
    unless (ref($plan) eq 'HASH') {fail('target plan is required'); return}
    my $module = $json->decode($json->encode($child));
    $_->{value} = $plan->{parameter_defaults}{$_->{name}} for @{$module->{params}};
    push @{$module->{params}}, map {{name => $_->{name}, value => $_->{value}}} @{$plan->{capture_parameters}};
    push @{$module->{constants}}, map {{name => $_->{name}, value => $_->{value}}} @{$plan->{constants}};
    for my $port (@{$module->{ports}}) {
        $port->{type} = format_value($plan->{widths}{$port->{name}}) if exists $plan->{widths}{$port->{name}};
    }
    my $source = FSM::Scheduler::ISF::Emitter::FSM->new->emit($module);
    my $dir = tempdir(DIR => '.artifacts', CLEANUP => 1);
    my ($fh, $path) = tempfile(DIR => $dir, SUFFIX => '.fsm');
    print {$fh} $source; close $fh or die $!;
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $raw = Lispish::multi($path);
    my $core = eval {$adapter->parse_fsm($raw)};
    ok($core, 'actual selected declarations parse through the canonical frontend') or diag($@);
    return unless $core;
    for my $name (qw(data response)) {is($adapter->{signal_manager}->get_signal($name)->width, 4, "$name keeps its local default")}
    is($adapter->{signal_manager}->get_signal('fixed')->width, 8, 'static source wins over equal-name type width four');
    for my $name (qw(A C P E PE)) {
        is($adapter->{signal_manager}->resolve_declared_parameter_payload($name)->{payload}, '8', "$name keeps its selected actor/static default");
    }
    is($adapter->{signal_manager}->resolve_declared_parameter_payload('SHADOW_ALIAS')->{payload}, '4', 'real local alias stays local');
};

subtest 'fresh plans remain detached and physical renames cannot supply lexical ancestry' => sub {
    unless (ref($plan) eq 'HASH') {fail('target plan is required'); return}
    my $saved = $json->encode($plan);
    my $renamed = $json->decode($before); $renamed->{actor_name} = 'renamed_width_symbols';
    my $fresh = $scheduler->{ir}->build_module($renamed)->{children}{worker}{_width_symbols};
    is($json->encode($fresh), $saved, 'physical rename preserves the complete selected child target plan');
    $plan->{capture_parameters}[0]{source}{scope}{owner} = 'WRONG';
    $plan->{parameter_defaults}{LANES}[5][0] = 'WRONG';
    is($child->{_width_bindings}{captures}[0]{scope}{owner}, 'width_symbols', 'capture source stays detached from binding graph');
    is($child->{_width_scopes}{transactions}{worker}{parameter_default_sources}[-1]{value}[5][0], '8', 'nested source default stays detached');
    is($json->encode($fresh), $saved, 'sibling/fresh result stays detached');
    is($json->encode($actor), $before, 'complete source remains unchanged after nested result mutations');
};

if (my $path = $ENV{FSMGEN_WIDTH_SYMBOL_CAPTURE}) {
    open my $out, '>', $path or die $!; print {$out} $capture, "\n" or die $!; close $out or die $!;
}
done_testing();

sub format_value {my ($v) = @_; return ref($v) eq 'ARRAY' ? '(' . join(' ', map {format_value($_)} @$v) . ')' : $v}
