use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use File::Path qw(make_path);
use FSM::Test::ProjectDataLocality;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF::Parser;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/imported-formal-boundary-20261002';
my $work = '.artifacts/imported-formal-boundary-20261002';
make_path("$base/products", "$base/sources", "$work/inputs");
my $child_constructor = FSM::Scheduler::ISF::LoweringIR->can('_build_library_child_ir');
my $formal_producer = FSM::Scheduler::ISF::FormalLowering->can('prepare');
my $clause_producer = FSM::Scheduler::ISF::FormalClauseResolver->can('transaction');
for my $kind (qw(ordinary shadow unused)) {
    my $pin = $kind eq 'shadow' ? '(input payload (width 3))' : '';
    my $body = $kind eq 'unused' ? '(wait 1)' : '(set payload 1) (wait payload)';
    my $child = "(actor worker (clock clk) (reset rst_n)"
        . " (interface (input start) $pin (output done))"
        . " (transaction main (ports (input payload (width 3))) (on start) $body (complete done)))";
    my $binding = $kind eq 'shadow' ? '(input payload incoming)' : '';
    my $root = '(actor root (clock clk) (reset rst_n)'
        . ' (interface (input start) (input incoming (width 3)) (output first_done) (output second_done) (output parent_done))'
        . ' (imports (library common.worker as lib))'
        . " (use lib.worker as first (bind (clock clk) (reset rst_n) (input start start) $binding (output done first_done)))"
        . " (use lib.worker as second (bind (clock clk) (reset rst_n) (input start start) $binding (output done second_done)))"
        . ' (transaction parent (ports (input delay (width 4))) (on start) (wait delay) (complete parent_done)))';
    my $source = $root . "\n(library common.worker (exports (actor worker)) $child)\n";
    write_file("$base/sources/$kind.isf", $source);
    write_file("$base/sources/standalone_$kind.isf", $child."\n");
    my $label = "$work/inputs/$kind.isf";
    write_file($label, $source);
    write_file("$work/inputs/standalone_$kind.isf", $child."\n");
    my $authority = FSM::Test::LibraryDocumentOriginAuthority->from_documents($label, {$label=>$source}, []);
    my $actor = $authority->actor;
    my (@children,@formals,@clauses);
    my $scheduler = FSM::Scheduler::ISF->new;
    my ($context,$error);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_build_library_child_ir = sub {
            my ($lowerer,$use,$parent)=@_;
            my $record={instance=>$use->{instance},module=>$use->{module},
                source_actor=>$json->decode($json->encode($use->{actor}))};
            push @children,$record;
            my $result=$child_constructor->(@_);
            $record->{product}=$json->decode($json->encode($result));
            return $result;
        };
        local *FSM::Scheduler::ISF::FormalLowering::prepare = sub {
            push @formals,{actor=>$_[2]{actor_name}};
            return $formal_producer->(@_);
        };
        local *FSM::Scheduler::ISF::FormalClauseResolver::transaction = sub {
            push @clauses,{transaction=>$_[1]{name}};
            return $clause_producer->(@_);
        };
        my $accepted=eval {$context=FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);1};
        $error=$@ unless $accepted;
    }
    my %public;
    for my $scope ('root','standalone') {
        my $input=$scope eq 'root' ? $label : "$work/inputs/standalone_$kind.isf";
        $public{$scope}=FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--quiet','--emit-schedule-json',$input], '');
    }
    write_file("$base/products/$kind.json",$json->encode({kind=>$kind,source=>$source,standalone_source=>$child,
        actor=>$actor,document_proof=>$authority->proof,context=>$context,error=>$error,
        children=>\@children,formal_calls=>\@formals,resolver_calls=>\@clauses,public=>\%public})."\n");
    print $json->encode({kind=>$kind,formal_calls=>\@formals,resolver_calls=>\@clauses,
        children=>[map {{instance=>$_->{instance},completed=>exists($_->{product})?1:0}} @children],
        error=>defined($error)?first_line($error):undef,
        public=>{map {$_=>$public{$_}{exit_code}} keys %public}}),"\n";
}
sub first_line {$_[0] =~ /\A([^\n]*)/ ? $1 : ''}
sub write_file {
    my ($path,$text)=@_;
    open my $fh,'>',$path or die $!; print {$fh} $text; close $fh or die $!;
}
