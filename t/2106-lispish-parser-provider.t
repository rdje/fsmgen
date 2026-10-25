use strict;
use warnings;
use Test::More;
use JSON::PP;
use FSM::Test::LispishProviderRuntime qw(run_provider_case);

my $json = JSON::PP->new->canonical;
my $actor = ['actor', ['parser_contract', ['clock', ['clk']]]];
my $multiple = [['first', ['a']], ['second', ['b']]];
my $expected = [
    [$actor], [['only', undef]], [[undef]],
    [['node', ['two words', 'x[3]', 'a + b']]],
    [['node', ['007', '-2', '0x2']]], $multiple,
];
for my $case (qw(api absolute relative missing outside syntax)) {
    subtest $case => sub {
        my $run = run_provider_case($case);
        ok($run->{cleanup}{leader_reaped}, 'child reaped');
        ok($run->{cleanup}{group_gone}, 'owned group settled');
        ok($run->{fixture_retired}, 'settled private fixture retired');
        if ($case eq 'syntax') {
            is($run->{exit_code}, 1, 'unexpected close retains failure status');
            is($run->{stdout}, "(Lispish) -E- Syntax Error\n", 'literal existing diagnostic');
            is($run->{stderr}, '', 'no additional error');
            return;
        }
        ok($run->{ok}, 'fixed child completes') or diag($run->{diagnostic} // '', $run->{stderr} // '');
        is($run->{stderr}, '', 'no import/discovery or other diagnostic');
        my $product = eval { $json->decode($run->{stdout}) };
        ok(ref($product) eq 'HASH', 'complete JSON product') or return;
        is_deeply($product->{legacy_loaded}, [], 'no PPlugin, Global or HUtils import');
        if ($case eq 'missing' || $case eq 'outside') {
            is($product->{parser_ok}, 0, 'canonical resource failure refuses without fallback');
            like($product->{error}, qr/\Aspecs\/Lispish\.spec: /, 'failure names owned relative resource');
            unlike($product->{error}, qr/Forbidden|INVALID CWD DECOY/, 'no discovery or decoy compilation');
            return;
        }
        is_deeply($product->{forms}, $expected, 'all independently declared literal ASTs');
        is($json->encode($product->{forms}), $json->encode($expected), 'JSON wire kinds retain numeric tokens as strings');
        is_deeply($product->{single}, [@$multiple, undef], 'single consumes successive forms then ends');
        is_deeply($product->{list}, $multiple, 'list-context multi');
        is_deeply($product->{file}, $multiple, 'file-input multi');
        is_deeply($product->{before}, $actor, 'direct parser before competing grammar');
        is_deeply($product->{after}, $actor, 'direct parser survives competing grammar');
        is_deeply($product->{cached_after}, $actor, 'cached Lispish parser survives competing grammar');
    };
}
eval { run_provider_case('unowned-command') };
like($@, qr/unknown Lispish provider case/, 'unknown case refused before execution');
done_testing;
