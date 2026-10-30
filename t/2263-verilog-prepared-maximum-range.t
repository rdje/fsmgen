use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

my $class = 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($w, $x, $floor) = @_;
    my $scope = {kind => 'direct_module', owner => 'literal_source'};
    return {target_language => 'systemverilog',
        environment => {scope => $scope, declaration_order => [qw(W X)], parameters => {
            W => {value_payload => {kind => 'scalar', payload => "$w"}},
            X => {value_payload => {kind => 'scalar', payload => "$x"}}}},
        operands => [map({width => $_->[1], width_contract => {scope => {%$scope},
            expression => ['param', $_->[0]], references => [{kind => 'parameter', token => $_->[0]}]}},
            ['W', $w], ['X', $x]), {width => $floor}]};
}

# Independent interpreter of the emitted arithmetic/conditional syntax. It does
# not call the production width evaluator or decide from selected defaults.
sub expression {
    my ($tokens, $values) = @_;
    my $token = shift @$tokens;
    die 'missing token' unless defined $token;
    return 0 + $token if $token =~ /^\d+$/;
    return $values->{$token} if exists $values->{$token};
    die "unexpected token $token" unless $token eq '(';
    my $left = expression($tokens, $values);
    my $op = shift @$tokens;
    my $right = expression($tokens, $values);
    my $value;
    if ($op eq '>') {
        die 'missing conditional' unless shift(@$tokens) eq '?';
        my $yes = expression($tokens, $values);
        die 'missing alternate' unless shift(@$tokens) eq ':';
        my $no = expression($tokens, $values);
        $value = $left > $right ? $yes : $no;
    } elsif ($op eq '+') { $value = $left + $right;
    } elsif ($op eq '-') { $value = $left - $right;
    } elsif ($op eq '*') { $value = $left * $right;
    } else { die "unexpected operator $op" }
    die 'missing close' unless shift(@$tokens) eq ')';
    return $value;
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

subtest 'independent mutable contracts and floors survive selected defaults and overrides' => sub {
    ok($class->can('lower_maximum_range'), 'prepared maximum range exists') or return;
    for my $language (qw(systemverilog sv verilog v)) {
        for my $defaults ([1, 1], [8, 64], [64, 8]) {
            for my $floor (1, 9, 32, 128) {
                my $input = fixture(@$defaults, $floor);
                $input->{target_language} = $language;
                my $before = $json->encode($input);
                my $range = $class->lower_maximum_range(%$input);
                like($range, qr/\bW\b/, 'first actual mutable name remains');
                like($range, qr/\bX\b/, 'independent second mutable name remains');
                for my $override ([1, 1], [2, 7], [16, 1], [64, 8], [4, 256]) {
                    my $want = $floor;
                    $want = $_ > $want ? $_ : $want for @$override;
                    is(range_width($range, W => $override->[0], X => $override->[1]), $want,
                        'independent emitted-syntax interpreter agrees with direct maximum');
                }
                is($json->encode($input), $before, 'complete caller records and kinds conserve');
            }
        }
    }
    my $input = fixture(1, 1, 1);
    $input->{operands} = [$input->{operands}[0]];
    is($class->lower_maximum_range(%$input), '[(W - 1):0] ', 'single symbolic width at one remains a vector');
    $input->{operands} = [{width => 1}];
    is($class->lower_maximum_range(%$input), '[(1 - 1):0] ', 'fixed maximum at one retains packed rank');
    $input = fixture(1, 1, 32);
    $input->{environment}{scope}{kind} = 'composition_top';
    $_->{width_contract}{scope}{kind} = 'composition_top' for @{$input->{operands}}[0, 1];
    my $range = $class->lower_maximum_range(%$input, required_scope_kind => 'composition_top');
    is(range_width($range, W => 64, X => 1), 64, 'explicit composition scope uses the same prepared kernel');
    ok(!eval {$class->lower_maximum_range(%$input, required_scope_kind => 'direct_module'); 1},
        'narrow required scope cannot borrow a different captured scope');
};

subtest 'every branch uses canonical lookup and arithmetic checks even when dominated' => sub {
    return unless $class->can('lower_maximum_range');
    my $input = fixture(1, 1, 32);
    my $first = $input->{operands}[0];
    $first->{width} = 3;
    $first->{width_contract}{expression} = ['+', ['param', 'W'], 2];
    my $range = $class->lower_maximum_range(%$input);
    is(range_width($range, W => 64, X => 1), 66, 'prepared arithmetic remains an override-dependent term');
    for my $change (
        sub {$_[0]{operands}[0]{width} = 2},
        sub {$_[0]{operands}[0]{width_contract}{references} = []},
        sub {$_[0]{operands}[0]{width_contract}{references}[0]{token} = 'X'},
        sub {push @{$_[0]{operands}[0]{width_contract}{references}}, {kind => 'parameter', token => 'W'}},
        sub {$_[0]{operands}[0]{width_contract}{scope}{owner} = 'foreign'},
        sub {$_[0]{environment}{scope}{kind} = 'foreign'},
        sub {$_[0]{operands}[0]{width_contract}{expression} = ['/', 1, 0]},
        sub {$_[0]{operands}[0]{width_contract}{expression} = ['-', 1, 1]},
        sub {$_[0]{operands}[0]{width_contract}{expression} = ['<<', 1, 1]},
        sub {$_[0]{operands}[2]{width} = JSON::PP::true},
        sub {$_[0]{operands}[2]{width} = 0},
        sub {$_[0]{operands}[2]{width} = 'raw_hdl'},
        sub {$_[0]{operands}[2]{foreign} = 1},
        sub {$_[0]{target_language} = 'vhdl'},
    ) {
        my $bad = fixture(1, 1, 128);
        $change->($bad);
        my $before = $json->encode($bad);
        ok(!eval {$class->lower_maximum_range(%$bad); 1}, 'invalid dominated or independent branch refuses');
        like($@, qr/(?:width|Verilog-family|maximum)/i, 'contextual width refusal');
        is($json->encode($bad), $before, 'refusal leaves every input unchanged');
    }
};

subtest 'bounded repeated occurrences and plain output retain no source graph' => sub {
    return unless $class->can('lower_maximum_range');
    my $input = fixture(1, 1, 32);
    $input->{operands} = [map {{%{$input->{operands}[0]}}} 1..32];
    my $range = $class->lower_maximum_range(%$input);
    is(range_width($range, W => 64), 64, 'balanced repeated maximum retains all branches');
    push @{$input->{operands}}, {width => 1};
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'over-bound maximum refuses');
    $input->{operands} = [];
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'empty maximum refuses');
    $input = fixture(1, 1, 32);
    my $cycle = []; push @$cycle, $cycle;
    $input->{operands}[0]{width_contract}{expression} = $cycle;
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'cyclic prepared graph refuses');
    $input = fixture(1, 1, 32);
    my $deep = ['param', 'W']; $deep = [$deep] for 1..40;
    $input->{operands}[0]{width_contract}{expression} = $deep;
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'over-depth graph refuses');
    $input = fixture(1, 1, 32);
    $input->{operands}[0]{width_contract}{expression} = '1' x 4097;
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'oversized scalar refuses before integer evaluation');
    for my $payload ([(1) x 4097], [('x' x 4096) x 33]) {
        $input = fixture(1, 1, 32);
        $input->{environment}{extra} = $payload;
        ok(!eval {$class->lower_maximum_range(%$input); 1}, 'aggregate input node/byte budget refuses');
        like($@, qr/bounded prepared width inputs/, 'input budget is the actual refusing boundary');
    }
    $input = fixture(1, 1, 32);
    my $term = $input->{operands}[0];
    $term->{width} = ('1' x 99) . '2';
    $term->{width_contract}{expression} = ['+', ['param', 'W'], '1' x 100];
    $input->{operands} = [($term) x 32];
    ok(!eval {$class->lower_maximum_range(%$input); 1}, 'bounded inputs cannot expand to oversized target text');
    like($@, qr/bounded rendered width text/, 'output budget is the actual refusing boundary');
    my ($weak, $held);
    {my $f = fixture(1, 1, 32); $weak = $f->{environment}; weaken($weak);
        $held = $class->lower_maximum_range(%$f);}
    ok(!defined($weak), 'successful result retains no environment');
    is(range_width($held, W => 1, X => 64), 64, 'escaped text remains usable');
};

done_testing();
