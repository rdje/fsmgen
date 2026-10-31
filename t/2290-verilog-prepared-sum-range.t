use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Digest::SHA qw(sha256_hex);
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

my $class = 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
my $path = 'perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm';
open my $source, '<', $path or die "$path: $!";
{local $/; diag('loaded ' . $path . ' sha256=' . sha256_hex(<$source>))}
close $source;
my $json = JSON::PP->new->canonical;
my $available = $class->can('lower_sum_range');
ok($available, 'separate prepared sum kernel exists');

sub fixture {
    my ($w, $x) = @_;
    my $scope = {kind => 'direct_module', owner => 'sum_source'};
    my $term = sub {
        my ($name, $width) = @_;
        return {width => $width, width_contract => {scope => {%$scope},
            expression => ['param', $name], references => [{kind => 'parameter', token => $name}]}};
    };
    return {target_language => 'systemverilog',
        environment => {scope => $scope, declaration_order => [qw(W X)], parameters => {
            W => {value_payload => {kind => 'scalar', payload => "$w"}},
            X => {value_payload => {kind => 'scalar', payload => "$x"}}}},
        operands => [$term->('W', $w), {width => 3}, $term->('X', $x), $term->('W', $w)]};
}

# Interpret actual emitted syntax independently of production lookup/evaluation.
# The golden widths below come from explicit source-slot multiplicities, not
# prepared operands or the compiler's selected numeric sum.
sub expression {
    my ($tokens, $values) = @_;
    my $token = shift @$tokens;
    die 'missing token' unless defined $token;
    return 0 + $token if $token =~ /^\d+$/;
    return $values->{$token} if exists $values->{$token};
    die "unexpected token $token" unless $token eq '(';
    my $left = expression($tokens, $values);
    my $operator = shift @$tokens;
    my $right = expression($tokens, $values);
    if ($operator eq '>') {
        die 'missing conditional' unless shift(@$tokens) eq '?';
        my $yes = expression($tokens, $values);
        die 'missing alternate' unless shift(@$tokens) eq ':';
        my $no = expression($tokens, $values);
        die 'missing close' unless shift(@$tokens) eq ')';
        return $left > $right ? $yes : $no;
    }
    die 'missing close' unless shift(@$tokens) eq ')';
    return $left + $right if $operator eq '+';
    return $left - $right if $operator eq '-';
    return $left * $right if $operator eq '*';
    die "unexpected operator $operator";
}
sub range_width {
    my ($range, %values) = @_;
    die 'not a packed range' unless $range =~ /^\[(.*):0\] $/;
    my $body = $1;
    my @tokens = $body =~ /(\d+|[A-Z]\w*|[()>?:+*\-])/g;
    (my $compact = $body) =~ s/\s//g;
    die 'unrecognized text' unless join('', @tokens) eq $compact;
    my $high = expression(\@tokens, \%values);
    die 'unconsumed text' if @tokens;
    return $high + 1;
}

subtest 'independent equal-default parameters, fixed summands and repeated slots' => sub {
    plan skip_all => 'sum kernel absent' unless $available;
    for my $language (qw(systemverilog sv verilog v)) {
        for my $defaults ([1, 1], [8, 64], [64, 8]) {
            my $input = fixture(@$defaults);
            $input->{target_language} = $language;
            my $before = $json->encode($input);
            my $range = $class->lower_sum_range(%$input);
            is($range, '[((((W + 3) + X) + W) - 1):0] ', 'original slot order and multiplicity retain');
            for my $override ([1, 1], [2, 7], [16, 1], [64, 8], [4, 256]) {
                is(range_width($range, W => $override->[0], X => $override->[1]),
                    2 * $override->[0] + $override->[1] + 3,
                    'emitted syntax matches independent slot-weight oracle under distinguishing override');
            }
            is($json->encode($input), $before, 'complete caller bytes and scalar kinds preserve');
        }
    }
    my $input = fixture(1, 1);
    $input->{operands} = [$input->{operands}[0]];
    is($class->lower_sum_range(%$input), '[(W - 1):0] ', 'single mutable width-one retains vector rank');
    $input->{operands} = [{width => 1}];
    is($class->lower_sum_range(%$input), '[(1 - 1):0] ', 'single fixed width-one retains packed rank');
    $input->{operands} = [{width => 2}, {width => 3}, {width => 2}];
    is($class->lower_sum_range(%$input), '[(7 - 1):0] ', 'fixed widths are summands, not floors or a maximum');
    $input->{operands} = [{width => '999999999999999999999999999999'}, {width => 1}];
    is($class->lower_sum_range(%$input), '[(1000000000000000000000000000000 - 1):0] ',
        'canonical arbitrary precision addition avoids native numeric overflow');
    $input = fixture(1, 1);
    $input->{environment}{scope}{kind} = 'composition_top';
    $_->{width_contract}{scope}{kind} = 'composition_top' for @{$input->{operands}}[0, 2, 3];
    is(range_width($class->lower_sum_range(%$input, required_scope_kind => 'composition_top'), W => 2, X => 7),
        14, 'explicit composition scope shares canonical sum arithmetic');
    ok(!eval {$class->lower_sum_range(%$input, required_scope_kind => 'direct_module'); 1},
        'narrow wrapper cannot borrow a different scope');
};

subtest 'each independent operand retains canonical lookup, scope and arithmetic validation' => sub {
    plan skip_all => 'sum kernel absent' unless $available;
    my $input = fixture(1, 1);
    $input->{operands}[0]{width} = 5;
    $input->{operands}[0]{width_contract}{expression} = ['+', ['*', ['param', 'W'], 3], ['param', 'X'], 1];
    push @{$input->{operands}[0]{width_contract}{references}}, {kind => 'parameter', token => 'X'};
    is(range_width($class->lower_sum_range(%$input), W => 2, X => 7), 26,
        'nested arithmetic and each ordered lookup retain separately');
    for my $change (
        sub {$_[0]{operands}[3]{width} = 2},
        sub {$_[0]{operands}[3]{width_contract}{references} = []},
        sub {$_[0]{operands}[3]{width_contract}{references}[0]{token} = 'X'},
        sub {push @{$_[0]{operands}[3]{width_contract}{references}}, {kind => 'parameter', token => 'W'}},
        sub {$_[0]{operands}[3]{width_contract}{scope}{owner} = 'foreign'},
        sub {$_[0]{environment}{scope}{kind} = 'foreign'},
        sub {$_[0]{operands}[3]{width_contract}{expression} = ['/', 1, 0]},
        sub {$_[0]{operands}[3]{width_contract}{expression} = ['-', 1, 1]},
        sub {$_[0]{operands}[3]{width_contract}{expression} = ['<<', 1, 1]},
        sub {$_[0]{operands}[1]{width} = JSON::PP::true},
        sub {$_[0]{operands}[1]{width} = 0},
        sub {$_[0]{operands}[1]{width} = 'raw_hdl'},
        sub {$_[0]{operands}[1]{foreign} = 1},
        sub {$_[0]{target_language} = 'vhdl'},
    ) {
        my $bad = fixture(1, 1);
        $change->($bad);
        my $before = $json->encode($bad);
        ok(!eval {$class->lower_sum_range(%$bad); 1}, 'invalid independent operand refuses');
        like($@, qr/(?:width|Verilog-family|sum)/i, 'contextual refusal');
        is($json->encode($bad), $before, 'refusal preserves complete caller data');
    }
};

subtest 'bounded complete inputs and escaped text lifetime' => sub {
    plan skip_all => 'sum kernel absent' unless $available;
    my $input = fixture(1, 1);
    $input->{operands} = [($input->{operands}[0]) x 32];
    my $range = $class->lower_sum_range(%$input);
    is(range_width($range, W => 7), 224, 'all 32 repeated occurrences contribute');
    push @{$input->{operands}}, {width => 1};
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'over-bound arity refuses');
    $input->{operands} = [];
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'empty sum refuses');
    $input = fixture(1, 1);
    my $cycle = []; push @$cycle, $cycle;
    $input->{operands}[0]{width_contract}{expression} = $cycle;
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'cycle refuses before semantic evaluation');
    $input = fixture(1, 1);
    my $deep = ['param', 'W']; $deep = [$deep] for 1..40;
    $input->{operands}[0]{width_contract}{expression} = $deep;
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'over-depth expression refuses');
    $input = fixture(1, 1);
    $input->{operands}[0]{width_contract}{expression} = '1' x 4097;
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'oversized scalar refuses');
    for my $payload ([(1) x 4097], [('x' x 4096) x 33]) {
        $input = fixture(1, 1);
        $input->{environment}{extra} = $payload;
        ok(!eval {$class->lower_sum_range(%$input); 1}, 'complete input occurrence/byte budget refuses');
        like($@, qr/bounded prepared width inputs/, 'actual bounded input boundary');
    }
    $input = fixture(1, 1);
    my $term = $input->{operands}[0];
    $term->{width} = ('1' x 1099) . '2';
    $term->{width_contract}{expression} = ['+', ['param', 'W'], '1' x 1100];
    $input->{operands} = [($term) x 32];
    ok(!eval {$class->lower_sum_range(%$input); 1}, 'oversized rendered sum refuses');
    like($@, qr/bounded rendered width text/, 'actual bounded output boundary');
    my ($weak, $held);
    {my $f = fixture(1, 1); $weak = $f->{environment}; weaken($weak);
        $held = $class->lower_sum_range(%$f)}
    ok(!defined($weak), 'escaped range retains no environment');
    is(range_width($held, W => 2, X => 7), 14, 'detached text remains usable');
};

done_testing();
