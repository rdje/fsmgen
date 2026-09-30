use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP=>1);
my $source = <<'ISF';
(actor carriers
  (types (type frame (record (count (four_state (signed (bits 3)))) (ready (two_state bit))))
    (type _isf_sample_q (bits 1)))
  (interface (input start) (output seen (width 3)) (output done))
  (storage (var packet (type frame) (reset 0)) (var held (type frame) (reset 0)))
  (transaction main (on start) (set seen packet.count) (complete done)))
ISF

sub prepared {
    my ($clauses, $template) = @_;
    my $a = $parser->parse_source($template // $source, 'sample-carriers.isf');
    my $packet = shift @{$a->{storage}};
    my %input = map {$_=>$packet->{$_}} qw(name width type type_spec);
    $input{domain} = $packet->{domain} if exists $packet->{domain};
    push @{$a->{interface}{inputs}}, \%input;
    $a->{transactions}[0]{clauses} = $clauses;
    return $a;
}
sub sample { ['sample',$_[0],'as',$_[1]] }
sub run_cli {
    my (@args) = @_;
    open my $f, '-|', './bin/fsmgen', '--quiet', '--strict', @args or die $!;
    local $/;
    my $text = <$f>;
    close $f;
    return ($? >> 8, $text);
}

subtest 'actual private parent scalar declarations preserve type properties and metadata' => sub {
    my $a = prepared([['on','start',sample('packet.count','q'),sample('packet.ready','ready_q')],
        sample('q','again'), ['set','seen','again'], ['complete','done']]);
    my $before = $json->encode($a);
    my $result = $scheduler->lower($a);
    is($json->encode($a), $before, 'complete caller facts remain unchanged through carrier emission');
    my $fsm = $result->{files}{'carriers.fsm'};
    like($fsm, qr/\(type _isf_sample_q_1 \(four_state \(signed \(bits 3\)\)\)\)/,
        'actual emitted type uses deterministic collision-safe signed four-state scalar');
    like($fsm, qr/\(type _isf_sample_ready_q \(two_state bit\)\)/, 'exact bit kind and explicit two-state wrapper survive');
    like($fsm, qr/\(q _isf_sample_q_1\)/, 'private sampled alias has a typed size declaration');
    like($fsm, qr/\(again _isf_sample_again\)/, 'chained sampled alias has the same scalar type declaration');
    like($fsm, qr/\(internal q\)/, 'private alias cannot become an inferred public input');
    unlike($fsm, qr/\((?:input|output) (?:q|again|ready_q)\)/, 'no scalarized sample field pins');
    unlike($fsm, qr/\((?:q|again|ready_q) _isf_sample_\w+ \(reset/, 'private samples inherit no actor storage reset');
    like($fsm, qr/\(held frame \(reset 0\)\)/, 'actual owned storage reset remains intact');
    like($fsm, qr/\(<= \(q packet.count\) <start\)/, 'entry capture assignment retains existing guard and opcode');
    like($fsm, qr/main_sample_1[\s\S]*\(<= \(again q\)\)[\s\S]*\(-> main_set_2\)/,
        'body capture precedes its data consumer through the existing sample state');
    my $report = $json->decode($scheduler->report($a));
    my %entries = map {$_->{name}=>$_} @{$report->{inferred_storage}};
    is_deeply($entries{q}, {name=>'q',kind=>'register',role=>'sample_alias',width=>3},
        'actual schedule reports exact scalar snapshot width and existing role');
    is_deeply($entries{ready_q}, {name=>'ready_q',kind=>'register',role=>'sample_alias',width=>1},
        'one-bit sample remains a private scalar snapshot');
    open my $f, '>', "$work/carriers.fsm" or die $!;
    print {$f} $fsm;
    close $f or die $!;
    my ($exit,$text) = run_cli('--check','--json',"$work/carriers.fsm");
    is($exit, 0, 'actual emitted typed IAL0 strictly checks through native public CLI');
    ok($json->decode($text)->{success}, 'strict replay reports success rather than a partial product');
};

subtest 'transaction product ABI and ordinary products remain unchanged' => sub {
    my $a = prepared([['on','start',sample('packet.count','q')],['set','seen','q'],['complete','done']]);
    my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
    my @products = $lowerer->_build_transaction($a->{transactions}[0], $a, 0);
    is(scalar(@products), 11, 'exact existing transaction product ABI is retained');
    is_deeply([@{$products[6]}{qw(q)}], [3], 'actual width product carries the selected leaf width');
    is($products[1]{q}, 3, 'private emitted counter declaration uses exact scalar width');
    is($products[7]{q}, 'sample_alias', 'private capture role is retained in the existing role product');
    my $ordinary = $parser->parse_source($source, 'sample-carriers.isf');
    my $before = $json->encode($ordinary);
    my $first = $json->encode($scheduler->lower($ordinary));
    is($json->encode($ordinary), $before, 'ordinary source facts remain unchanged');
    is($json->encode($scheduler->lower($ordinary)), $first, 'complete ordinary scheduled products and emitted bytes remain deterministic');
};

subtest 'actual generated child and named-domain modules keep private scalar types' => sub {
    my $template = $source;
    $template =~ s/\(transaction main/\(transaction worker/;
    $template =~ s/\)\)\)\s*\z/)) (transaction main (on start) (spawn worker as job) (await_all done) (complete done)))/;
    my $a = prepared([['on','start',sample('packet.count','q')],['set','seen','q'],['complete','done']], $template);
    my $result = $scheduler->lower($a);
    ok(exists($result->{files}{'worker.fsm'}), 'actual generated transaction child is emitted');
    my $child = $result->{files}{'worker.fsm'} // '';
    like($child, qr/\(q _isf_sample_q_1\)/, 'generated child uses its private typed scalar alias');
    like($child, qr/\(packet frame\)/, 'generated child keeps the existing packed input type carrier');
    like($child, qr/\(internal q\)/, 'generated child sample remains internal');
    unlike($result->{files}{'carriers.fsm'}, qr/\(q _isf_sample_q_1\)/, 'parent does not borrow child sample declaration');
    for my $name (sort keys %{$result->{files}}) {
        open my $f, '>', "$work/$name" or die $!;
        print {$f} $result->{files}{$name};
        close $f or die $!;
    }
    my ($exit,$text) = run_cli('--check','--json',"$work/worker.fsm");
    is($exit, 0, 'actual generated child strictly replays as IAL0');
    ok($json->decode($text)->{success}, 'generated child check succeeds');

    $template = $source;
    $template =~ s/\(actor carriers/(actor carriers (clock-domains (domain core (clock core_clk) (reset core_rst) :default) (domain aux (clock aux_clk) (reset aux_rst)))/;
    $a = prepared([['on','start',sample('packet.count','q')],['set','seen','q'],['complete','done']], $template);
    $result = $scheduler->lower($a);
    my $core = $result->{files}{'carriers__domain_core.fsm'} // '';
    my $aux = $result->{files}{'carriers__domain_aux.fsm'} // '';
    like($core, qr/\(q _isf_sample_q_1\)/, 'owning domain retains exact typed private sample');
    like($core, qr/\(internal q\)/, 'domain sample stays internal');
    unlike($aux, qr/\(q _isf_sample_q_1\)/, 'unrelated domain gains no sample carrier');
    for my $name (sort keys %{$result->{files}}) {
        open my $f, '>', "$work/$name" or die $!;
        print {$f} $result->{files}{$name};
        close $f or die $!;
    }
    ($exit,$text) = run_cli('--check','--json',"$work/carriers__domain_core.fsm");
    is($exit, 0, 'actual owning-domain module strictly replays as IAL0');
    ok($json->decode($text)->{success}, 'owning-domain check succeeds');
};

subtest 'whole input snapshots and actual scheduler helper collisions refuse' => sub {
    for my $case (
        [prepared([sample('packet','q')]), qr/whole record/],
        [prepared([sample('packet.count','can_accept')]), qr/collides with a generated declaration/],
        [prepared([sample('packet.count','held')]), qr/collides with a declaration/],
    ) {
        my $before = $json->encode($case->[0]);
        my $ok = eval {$scheduler->lower($case->[0]);1};
        my ($line) = split /\n/,$@;
        ok(!$ok, 'invalid sample carrier refuses before emission');
        like($line // '', $case->[1], 'first diagnostic names the exact carrier cause');
        is($json->encode($case->[0]), $before, 'refused carrier leaves complete caller facts unchanged');
    }
    my $ok = eval {$parser->parse_source('(actor refused (types (type frame (record (data bit)))) (interface (input packet (type frame))) (transaction main (on packet.data)))','refused.isf');1};
    ok(!$ok, 'record member activation trigger remains outside the input subset');
    like((split /\n/,$@)[0], qr/on trigger does not admit record port reference 'packet.data'/, 'unsupported trigger refusal stays precise');
};

done_testing;
