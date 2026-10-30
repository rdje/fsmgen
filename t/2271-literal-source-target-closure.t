use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $json = JSON::PP->new->canonical;

# Interpret only emitted packed-range arithmetic. Neither the production width
# evaluator nor its captured declaration/event records supply this oracle.
sub expression {
    my ($tokens, $values) = @_;
    my $token = shift @$tokens;
    die 'missing range token' unless defined $token;
    return 0 + $token if $token =~ /^\d+$/;
    return $values->{$token} if exists $values->{$token};
    die "unexpected range token $token" unless $token eq '(';
    my $left = expression($tokens, $values);
    my $operator = shift @$tokens;
    my $right = expression($tokens, $values);
    my $result;
    if ($operator eq '>') {
        die 'missing conditional' unless shift(@$tokens) eq '?';
        my $yes = expression($tokens, $values);
        die 'missing alternate' unless shift(@$tokens) eq ':';
        my $no = expression($tokens, $values);
        $result = $left > $right ? $yes : $no;
    } elsif ($operator eq '-') {
        $result = $left - $right;
    } else {
        die "unexpected range operator $operator";
    }
    die 'missing range close' unless shift(@$tokens) eq ')';
    return $result;
}

sub range_width {
    my ($range, %values) = @_;
    return 1 if $range eq '';
    die 'not a packed range' unless $range =~ /^\[(.*):0\]$/;
    my $body = $1;
    my @tokens = $body =~ /(\d+|[A-Z]\w*|[()>?:\-])/g;
    (my $compact = $body) =~ s/\s//g;
    die 'unrecognized range text' unless join('', @tokens) eq $compact;
    my $high = expression(\@tokens, \%values);
    die 'unconsumed range text' if @tokens;
    return $high + 1;
}

sub maximum {
    my $max = shift;
    $max = $_ > $max ? $_ : $max for @_;
    return $max;
}

sub source_state {
    my ($module) = @_;
    return $json->encode({map {$_ => {
        width => $module->signals->{$_}{_width},
        literal => $module->signals->{$_}{_source_literal_width_allocation},
        declared => $module->signals->{$_}{attributes}{width_declared},
    }} sort keys %{$module->signals}});
}

subtest 'ordinary original and nested literal HDL agrees with source algebra' => sub {
    my @cases = (
        {shape => 'original', w => 1, x => 1},
        {shape => 'original', w => 8, x => 8},
        {shape => 'original', w => 64, x => 128},
        {shape => 'original', w => 8, x => 64, fixed => 1},
        {shape => 'nested', w => 1, x => 1},
        {shape => 'nested', w => 64, x => 128},
        {shape => 'nested', w => 8, x => 64, fixed => 1},
        {shape => 'nested', w => 1, x => 1, sized => 1},
        {shape => 'nested', w => 8, x => 64, fixed => 1, sized => 1},
        {shape => 'nested', w => 1, x => 1, scalar => 1},
    );
    for my $case (@cases) {
        my ($w, $x) = @{$case}{qw(w x)};
        my $params = $case->{fixed} ? '' : "(+params (W $w) (X $x))";
        my $sizes = $case->{fixed} ? "(A $w) (B $x)" : '(A (param W)) (B (param X))';
        my $original = $case->{shape} eq 'original';
        my $literal = $case->{scalar} ? "1'b1" : $case->{sized} ? "9'b100000000" : '256';
        my $source = $original ? '(& A B 3)' : "(^ (| A $literal) B)";
        my $floor = $case->{scalar} ? 1 : $case->{sized} ? 9 : 32;
        my $text = "(?fsm:literal_closure $params (+size $sizes (DATA 1) (OTHER 1))"
            ." (idle (<$source (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $raw = scalar Lispish::multi(\$text);
        my $before = $json->encode($raw);
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
        my $state = source_state($module);
        my @helpers = sort grep {exists $module->signals->{$_}{_source_literal_width_allocation}}
            keys %{$module->signals};
        is(scalar(@helpers), $original ? 1 : 2, 'original source has the expected physical helper population');

        for my $language (qw(systemverilog verilog)) {
            my ($hdl, $error);
            my $ctx = FSM::HDL::FlattenedDT->new;
            eval {$hdl = $language eq 'verilog' ? $ctx->generate_verilog($module)
                : $ctx->generate_systemverilog($module); 1} or $error = $@;
            is($error, undef, "$language ordinary generation: $source ($w,$x)") or diag($error);
            next if $error;
            my %assignments = $hdl =~ /^  assign (\w+) = ([^;]+);/mg;
            # The emitted name is the identity. Scalar wires have no range.
            my %declarations;
            while ($hdl =~ /^  wire (\[[^\n]+:0\])?\s*(\w+);$/mg) {
                $declarations{$2} = $1 // '';
            }
            my @children = grep {$assignments{$_} eq ($original ? 'A & B & 3' : "A | $literal")}
                @helpers;
            is(scalar(@children), 1, 'actual child expression preserves original operator operands and literal');
            next unless @children == 1;
            my $child = $children[0];
            my @parents = grep {$_ ne $child} @helpers;
            is_deeply([map {$assignments{$_}} @parents], $original ? [] : ["$child ^ B"],
                'actual parent consumes the literal child and independent B');
            for my $name (@helpers) {
                ok(exists($declarations{$name}), 'each physical helper has an actual wire declaration');
                next unless exists $declarations{$name};
                my $parent = $name ne $child;
                for my $values ([$w, $x], [1, 1], [64, 1], [1, 128]) {
                    my ($a, $b) = $case->{fixed} ? ($w, $x) : @$values;
                    my $expected = maximum($floor, $a, ($original || $parent ? $b : ()));
                    is(range_width($declarations{$name}, W => $a, X => $b), $expected,
                        'complete emitted range agrees with independent source maximum');
                }
                like($declarations{$name}, qr/\bW\b/, 'mutable dependency survives default-one sizing')
                    unless $case->{fixed};
                like($declarations{$name}, qr/\bX\b/, 'independent parent dependency survives')
                    if !$case->{fixed} && ($original || $parent);
            }
            is(source_state($module), $state, 'source widths nullable literal policies and parameter bindings conserve');
            is($json->encode($raw), $before, 'complete caller source and JSON kinds conserve');
        }
    }
};

done_testing();
