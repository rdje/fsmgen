use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;

# ISF-REDUCTION-DELIVERY.1.2.3.3.1: bounded generation/refusal profiles.
# Existing VHDL folds are a text-generation contract; runtime remains separate.
my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my $sentinel = "EXISTING DESTINATION\nretain each byte on refusal\n";
my $capture_dir;
if (defined(my $epoch = $ENV{FSMGEN_UNARY_PROFILE_CAPTURE})) {
    die 'invalid profile capture epoch' unless $epoch =~ /\A[a-zA-Z0-9_-]{1,64}\z/;
    $capture_dir = ".artifacts/tmp/unary-profile-$epoch";
    mkdir $capture_dir or die "exclusive profile capture directory: $!";
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
    return $path;
}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
sub capture {FSM::Test::SourceQueryRunner::_capture($_[0], '')}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub preserve {
    return unless defined $capture_dir;
    my ($name, $data) = @_;
    sysopen my $fh, "$capture_dir/$name.json", O_WRONLY|O_CREAT|O_EXCL or die $!;
    print {$fh} $json->encode($data)."\n" or die $!;
    close $fh or die $!;
}
sub refusal_reason {
    my ($case, $target) = @_;
    return undef unless $target eq 'vhdl';
    if ($case->{name} eq 'ordinary_unrolled') {
        return "[VHDL.pm][direct scaffold] Unsupported generated SystemVerilog shape for direct VHDL backend: arithmetic expression '"
            . join(' ^ ', map {"data[$_]"} 0..7) . "' is outside the direct VHDL scaffold";
    }
    return undef unless ($case->{shape} // '') =~ /\A(?:slice|nested_range)\z/;
    my $op = $case->{shape} eq 'slice' ? $case->{operator} : '|';
    return "[VHDL.pm][direct scaffold] Unsupported generated SystemVerilog shape for direct VHDL backend: "
        . "unary reduction expression '($op(data[7:4]))' is outside the direct VHDL scaffold: "
        . "operand 'data[7:4]' is a 4-bit range slice; only scalar identifiers and in-range static bit selects are supported";
}
sub primary_reason {
    my ($error) = @_;
    $error //= '';
    $error =~ s/\ASource file: '[^\n]+'\n//;
    $error =~ s/\AError generating HDL: //;
    my $first = (split /\n/, $error)[0] // '';
    $first =~ s/ at [^\n]+ line \d+\.?\z//;
    return $first;
}
sub compact {my $s=$_[0]; $s =~ s/\s+//g; return $s}
sub strip_outer {
    my ($s)=@_;
    $s =~ s/\A\s+|\s+\z//g;
    while ($s =~ /\A\(.*\)\z/s) {
        my ($depth,$whole)=(0,1);
        for my $i (0..length($s)-1) {
            my $c=substr($s,$i,1);
            $depth++ if $c eq '('; $depth-- if $c eq ')';
            if ($depth==0 && $i<length($s)-1) {$whole=0;last}
        }
        last unless $whole && $depth==0;
        $s=substr($s,1,length($s)-2); $s =~ s/\A\s+|\s+\z//g;
    }
    return $s;
}
sub vhdl_signature {
    my $s=strip_outer($_[0]);
    my ($depth,$start,@parts)=(0,0);
    for my $i (0..length($s)-1) {
        my $c=substr($s,$i,1);
        $depth++ if $c eq '('; $depth-- if $c eq ')';
        if ($c eq '&' && $depth==0) {push @parts,substr($s,$start,$i-$start);$start=$i+1}
    }
    if (@parts) {push @parts,substr($s,$start);return ['concat',map {vhdl_signature($_)} @parts]}
    return ['not',vhdl_signature($1)] if $s =~ /\Anot\b\s*(.+)\z/s;
    return compact($s);
}
sub profile_errors {
    my ($case,$target,$hdl)=@_;
    my @errors;
    push @errors,'module identity' unless $hdl =~ /\b(?:module|entity)\s+\Q$case->{name}\E\b/i;
    my $width=$case->{width};
    my $declaration = $target eq 'vhdl'
        ? ($width==1 ? qr/\bresult\s*:\s*out\s+std_logic\b/i
            : qr/\bresult\s*:\s*out\s+std_logic_vector\s*\(\s*\Q@{[$width-1]}\E\s+downto\s+0\s*\)/i)
        : ($width==1 ? qr/\boutput\s+reg\s+result\b/
            : qr/\boutput\s+reg\s+\[\Q@{[$width-1]}\E:0\]\s+result\b/);
    push @errors,'declared result width' unless $hdl =~ $declaration;
    push @errors,'foreign procedural keyword' if $target =~ /\A(?:verilog|v)\z/
        && $hdl =~ /^\s*always_(?:ff|comb)\b/m;
    return \@errors unless $case->{unary};
    if ($target eq 'vhdl') {
        my @values=grep {compact($_) ne 'result'} $hdl =~ /^\s*result_next\s*<=\s*([^;]+);/mg;
        push @errors,'actual VHDL write count' unless @values==1;
        push @errors,'actual VHDL value' unless @values==1
            && $json->encode(vhdl_signature($values[0])) eq $json->encode($case->{vhdl_value});
        my %wanted=map {$_=>1} @{$case->{helpers} // []};
        my %actual;
        while ($hdl =~ /function\s+(fsmgen_direct_vhdl_reduce_(or|and|xor))\([^\n]+\) return std_logic is\n(.*?)end function \1;/sg) {
            my ($name,$operator,$body)=($1,$2,$3); $actual{$operator}=1;
            my $identity=$operator eq 'and' ? '1' : '0';
            push @errors,"$operator fold identity" unless $body =~ /variable result : std_logic := '\Q$identity\E';/;
            push @errors,"$operator fold operation" unless $body =~ /result := result \Q$operator\E value\(index\);/;
            push @errors,"$operator fold extent" unless $body =~ /for index in value'range loop/;
        }
        push @errors,'complete required fold helper membership'
            unless $json->encode([sort keys %actual]) eq $json->encode([sort keys %wanted]);
    } else {
        my @values=grep {compact($_) ne 'result'} $hdl =~ /^\s*result_next\s*=\s*([^;]+);/mg;
        push @errors,'actual SV/Verilog write count' unless @values==1;
        push @errors,'actual SV/Verilog value' unless @values==1 && compact($values[0]) eq $case->{sv_value};
    }
    return \@errors;
}
sub normalize_date {my $s=$_[0]; $s =~ s{^(?://|--) Date:[^\n]*$}{GENERATED DATE}mg; return $s}
sub source {
    my ($name, $rhs, $width) = @_;
    return "(actor $name (clock clk) (reset (rst_n sync active_low))\n"
        . " (interface (input go) (input data (width 8)) (input other (width 8)) (input flag)"
        . " (output result (width $width)) (output done))\n"
        . " (transaction main (on go) (set result $rhs) (complete done)))\n";
}
sub facade {
    my ($path, $target) = @_;
    my ($product, $error);
    eval {$product = FSM::Pipeline::HDLGenerator->new(target_language => $target, quiet => 1, strict_mode => 1)
        ->generate_hdl_from_file($path); 1} or $error = $@;
    return ($product, $error);
}

my @cases;
for my $operator (['^','xor'], ['&','and'], ['|','or']) {
    for my $operand ([vector => 'data'], [scalar => 'flag'], [bit => 'data[3]'], [slice => 'data[7:4]']) {
        my $name = "profile_$operator->[1]_$operand->[0]";
        my $vhdl_value=$operand->[0] eq 'vector' ? "fsmgen_direct_vhdl_reduce_$operator->[1](data)"
            : $operand->[0] eq 'scalar' ? 'flag' : 'data(3)';
        push @cases, {name => $name, unary => 1, width=>1, shape=>$operand->[0],operator=>$operator->[0],
            sv_value=>"($operator->[0]($operand->[1]))",vhdl_value=>$vhdl_value,
            helpers=>($operand->[0] eq 'vector' ? [$operator->[1]] : []),
            text => source($name, "($operator->[0] $operand->[1])", 1)};
    }
}
push @cases, {name => 'profile_nested', unary => 1, width=>3, shape=>'nested_range',
    sv_value=>'{!((^(data))),(&(data[0])),(|(data[7:4]))}',text => source('profile_nested',
    '(concat (! (^ data)) (& data[0]) (| data[7:4]))', 3)};
push @cases, {name=>'profile_odd',unary=>1,width=>1,shape=>'odd',helpers=>['xor'],
    sv_value=>'!((^(data)))',vhdl_value=>['not','fsmgen_direct_vhdl_reduce_xor(data)'],
    text=>source('profile_odd','(! (^ data))',1)};
push @cases, {name=>'profile_nested_scalar',unary=>1,width=>3,shape=>'nested_scalar',helpers=>['xor'],
    sv_value=>'{!((^(data))),(&(data[0])),(|(flag))}',
    vhdl_value=>['concat',['not','fsmgen_direct_vhdl_reduce_xor(data)'],'data(0)','flag'],
    text=>source('profile_nested_scalar','(concat (! (^ data)) (& data[0]) (| flag))',3)};
for my $operator (['^','xor'], ['&','and'], ['|','or']) {
    my $name = "ordinary_$operator->[1]";
    push @cases, {name => $name, unary => 0,width=>8, text => source($name, "($operator->[0] data other)", 8)};
}
push @cases, {name => 'ordinary_unrolled', unary => 0,width=>1, text => source('ordinary_unrolled',
    '(^ data[0] data[1] data[2] data[3] data[4] data[5] data[6] data[7])', 1)};
push @cases, {name => 'ordinary_not', unary => 0,width=>1, text => source('ordinary_not', '(! flag)', 1)};
my %supported;

subtest 'public facade binds actual unary generation and precise shape-specific refusals' => sub {
    for my $case (@cases) {
        my $path = write_file("$work/$case->{name}.isf", $case->{text});
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $before = $json->encode($actor);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is($json->encode($actor), $before, "$case->{name} caller data/kinds unchanged");
        my ($carrier) = values %{$lowered->{files}};
        my $carrier_path = write_file("$work/$case->{name}.fsm", $carrier);
        my @observations;
        for my $input ($path, $carrier_path) {
            for my $target (qw(systemverilog sv verilog v vhdl)) {
                my ($product, $error) = facade($input, $target);
                my $wanted=refusal_reason($case,$target);
                if (defined($wanted)) {
                    ok(!defined($product), "$case->{name} $target no partial facade product");
                    is(primary_reason($error), $wanted,
                        "$case->{name} $target exact contextual primary refusal");
                } else {
                    ok(defined($product), "$case->{name} $target preserves ordinary/supported generation") or diag($error // 'no product');
                    same(profile_errors($case,$target,$product->{hdl_code} // ''),[],
                        "$case->{name} $target independent value/width/fold profile");
                    $supported{$case->{name}}{$target}=$product->{hdl_code} if defined($product);
                }
                # The typed CoreAST module is deliberately not JSON erased.
                push @observations, {path => $input, target => $target, error => $error,
                    product => defined($product) ? {hdl_code => $product->{hdl_code}, source_info => $product->{source_info},
                        result_keys => [sort keys %$product]} : undef};
            }
        }
        is(sha256_hex(read_file($path)), sha256_hex($case->{text}), "$case->{name} source bytes unchanged");
        is(sha256_hex(read_file($carrier_path)), sha256_hex($carrier), "$case->{name} actual carrier bytes unchanged");
        preserve($case->{name}, {source => $case->{text}, carrier => $carrier, observations => \@observations});
        for my $aliases ([qw(systemverilog sv)],[qw(verilog v)]) {
            same(normalize_date($supported{$case->{name}}{$aliases->[0]}),
                normalize_date($supported{$case->{name}}{$aliases->[1]}), 'complete language-alias HDL except generated date');
        }
    }
};

subtest 'native products publish supported profiles and atomically refuse the VHDL range boundary' => sub {
    my $case = $cases[3];
    my $path = "$work/$case->{name}.isf";
    my $carrier = "$work/$case->{name}.fsm";
    my @observations;
    for my $input ($path, $carrier) {
        for my $target (qw(systemverilog sv verilog v vhdl)) {
            my $wanted = refusal_reason($case,$target);
            my $status = defined($wanted) ? 1 : 0;
            my $output = "$input-$target.hdl";
            write_file($output, $sentinel);
            my $existing = capture([$^X,'bin/fsmgen',qw(--strict --quiet),'--language',$target,'--output',$output,$input]);
            is($existing->{exit_code}, $status, "$target native existing-destination normal outcome");
            is($existing->{signal}, 0, "$target native no signal");
            is($existing->{stdout}, '', "$target no stdout HDL");
            my $after = read_file($output);
            if (defined($wanted)) {
                is(primary_reason($existing->{stderr}), $wanted, "$target native exact primary refusal");
                is($after, $sentinel, "$target refused existing destination byte-exact");
            } else {
                is($existing->{stderr}, '', "$target clean supported stderr");
                same(profile_errors($case,$target,$after),[], "$target independently correct published value/width");
                is(normalize_date($after),normalize_date($supported{$case->{name}}{$target}),
                    "$target whole native/facade HDL except generated date");
            }
            unlink $output or die $!;
            my $absent = capture([$^X,'bin/fsmgen',qw(--strict --quiet),'--language',$target,'--output',$output,$input]);
            is($absent->{exit_code}, $status, "$target absent-destination normal outcome");
            is($absent->{signal}, 0, "$target absent-destination no signal");
            if (defined($wanted)) {
                is(primary_reason($absent->{stderr}), $wanted, "$target absent-destination exact primary refusal");
                ok(!-e $output, "$target refusal creates no destination");
            } else {
                is($absent->{stderr}, '', "$target supported absent-destination clean stderr");
                same(profile_errors($case,$target,read_file($output)),[], "$target absent destination receives correct product");
            }
            my @machine;
            for my $kind ([check => qw(--check --json)], [semantic => '--emit-semantic-json']) {
                my ($mode,@flags) = @$kind;
                my $r = capture([$^X,'bin/fsmgen',qw(--strict --quiet),'--language',$target,@flags,$input]);
                is($r->{exit_code}, $status, "$target $mode normal outcome");
                is($r->{signal}, 0, "$target $mode no signal");
                is($r->{stderr}, '', "$target $mode clean machine stderr");
                my $report = $json->decode($r->{stdout});
                is($json->encode($report->{success}), $status ? 'false' : 'true', "$target $mode exact success kind");
                if (defined($wanted)) {
                    is(primary_reason($report->{diagnostics}[0]{message}), $wanted, "$target $mode primary reason retained");
                    ok(!exists($report->{source}{reductions}), "$target $mode no successful source reduction inventory");
                    ok(!defined($report->{semantic}), "$target $mode no successful semantic snapshot");
                } elsif ($input eq $path) {
                    same($report->{source}{reductions}, [{owner_kind=>'transaction',owner=>'main',context=>"transaction 'main' clause[1] set RHS",
                        kind=>'unary',operator=>'^',operand=>'data[7:4]',operand_width=>4,result_width=>1}],
                        "$target $mode independently literal successful source inventory");
                } else {
                    ok(!exists($report->{source}{reductions}), "$target $mode carrier invents no authored ISF inventory");
                }
                push @machine, {mode => $mode, result => $r};
            }
            my $schedule = capture([$^X,'bin/fsmgen',qw(--strict --quiet),'--language',$target,'--emit-schedule-json',$path]);
            is($schedule->{exit_code}, 0, "$target schedule remains target neutral");
            is($schedule->{signal}, 0, "$target schedule no signal");
            is($schedule->{stderr}, '', "$target schedule clean stderr");
            my $report = $json->decode($schedule->{stdout});
            same($report->{reductions}, [{owner_kind=>'transaction',owner=>'main',context=>"transaction 'main' clause[1] set RHS",
                kind=>'unary',operator=>'^',operand=>'data[7:4]',operand_width=>4,result_width=>1}],
                "$target independent source schedule record survives refusal");
            push @observations, {input=>$input,target=>$target,existing=>$existing,destination_after=>$after,
                absent=>$absent,absent_destination_exists=>(-e $output ? JSON::PP::true : JSON::PP::false),
                machine=>\@machine,schedule=>$schedule};
        }
    }
    preserve('native', {source=>$case->{text},sentinel=>$sentinel,observations=>\@observations});
};

subtest 'independent profile oracle rejects wrong actual value and fold products' => sub {
    my ($xor)=grep {$_->{name} eq 'profile_xor_vector'} @cases;
    my $wrong=$supported{profile_xor_vector}{systemverilog};
    ok($wrong =~ s/(result_next\s*=\s*)\(\^\(data\)\)/$1(\&(data))/,
        'wrong source-result control changes the actual mux assignment');
    ok(@{profile_errors($xor,'systemverilog',$wrong)},'wrong XOR value cannot pass the independent profile oracle');
    my ($and)=grep {$_->{name} eq 'profile_and_vector'} @cases;
    for my $mutation (
        sub {$_[0] =~ s/variable result : std_logic := '1'/variable result : std_logic := '0'/},
        sub {$_[0] =~ s/result := result and value\(index\)/result := result or value(index)/},
    ) {
        my $bad=$supported{profile_and_vector}{vhdl};
        ok($mutation->($bad),'wrong fold control changes an actual helper');
        ok(@{profile_errors($and,'vhdl',$bad)},'wrong fold identity/operation cannot pass the independent oracle');
    }
};

done_testing();
