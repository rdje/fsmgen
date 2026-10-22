use strict;
use warnings;
use lib 'perl','t/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Support::ISFReductions qw(capture_expression_reductions);
use FSM::Support::ISFRecordPortScopes qw(record_actor_scope);
use FSM::Support::SemanticIntrospectionMCPAdapter;
my $root=abs_path('.');my $work=tempdir(CLEANUP=>1);my $json=JSON::PP->new->canonical;
sub capture {FSM::Test::SourceQueryRunner::_capture($_[0],$_[1] // '')}
sub write_file {
 my($name,$text)=@_;my$p="$work/$name";open my$f,'>',$p or die$!;print{$f}$text;close$f or die$!;
 $p =~ s/\A\Q$root\E\///;return$p;
}
sub same {is($json->encode($_[0]),$json->encode($_[1]),$_[2])}
write_file('shared.fsm','(?pkg:shared (+constants (VALUE 1)))');
my %paths;
for my $case ([enum=>'mode','BUSY','(enums (mode (BUSY 1)))'],
 [package=>'shared','VALUE','(imports (package shared))']) {
 my($name,$prefix,$member,$decl)=@$case;
 for my $variant(qw(baseline reduction)) {
  my$rhs=$variant eq 'baseline'?"$prefix.$member":"(^ $prefix.$member)";
  $paths{$name}{$variant}=write_file("$name-$variant.isf",qq{(actor static_namespace $decl
   (types (type frame (record ($member (bits 3)) (data (bits 5)))))
   (interface (input start) (input $prefix (type frame)) (output out) (output done))
   (transaction main (on start) (set out $rhs) (complete done)))});
 }
}
subtest 'actual canonical static set and record scope keep their separate roles' => sub {
 for my$case([enum=>'mode','BUSY'],[package=>'shared','VALUE']) {
  my($name,$prefix,$member)=@$case;
  my$actor=FSM::Adapter::ISF->new->parse_file($paths{$name}{baseline});
  my$before=$json->encode($actor);
  my$symbols=FSM::Scheduler::ISF::LoweringIR->new->expression_static_scopes($actor);
  ok(exists $symbols->{transactions}{main}{"$prefix.$member"},"$name actual namespace owns the exact static token");
  my$scope=record_actor_scope(actor=>$actor);
  is($scope->{$prefix}{type_spec}{members}{$member}{width},3,"$name colliding record declaration really has a different field width");
  my$rows=eval {capture_expression_reductions(expression=>['^',"$prefix.$member"],scope=>$scope,
   static_symbols=>$symbols->{transactions}{main},owner_kind=>'transaction',owner=>'main',context=>'collision RHS')};
  my$error=$@;
  ok(!$rows,"$name constant cannot borrow record field width");
  like($error,qr/collision RHS.*not a declared packed scalar signal/s,"$name refusal identifies the actual operand context");
  is($json->encode($actor),$before,"$name complete source data/kinds stay unchanged");
 }
};
subtest 'static membership covers selectors without masking unrelated declared fields' => sub {
 my$actor=FSM::Adapter::ISF->new->parse_file($paths{enum}{baseline});
 my$scope=record_actor_scope(actor=>$actor);
 $scope->{mode}{type_spec}{members}{data}{width}='5';
 my$symbols={'mode.BUSY'=>'1'};my$before=$json->encode([$scope,$symbols]);
 for my$operand(qw(mode.BUSY mode.BUSY[0] mode.BUSY[2:1])) {
  my$rows=eval {capture_expression_reductions(expression=>['^',$operand],scope=>$scope,static_symbols=>$symbols,
   owner_kind=>'rule',owner=>'r',context=>'selected static RHS')};my$error=$@;
  ok(!$rows,"$operand stays a static value");like($error,qr/not a declared packed scalar signal/,"$operand exact category");
 }
 my$rows=eval {capture_expression_reductions(expression=>['^','mode.data[3:1]'],scope=>$scope,static_symbols=>$symbols,
  owner_kind=>'rule',owner=>'r',context=>'declared field RHS')};my$error=$@;
 is_deeply($rows,[{owner_kind=>'rule',owner=>'r',context=>'declared field RHS',kind=>'unary',operator=>'^',
  operand=>'mode.data[3:1]',operand_width=>3,result_width=>1}], 'unrelated declared field/slice retains exact width') or diag($error);
 is($json->encode([$scope,$symbols]),$before,'complete caller scope and static value kinds unchanged');
 for my$bad(undef,[],{'bad-name'=>1}) {
  my$ok=eval {capture_expression_reductions(expression=>['^','mode.data'],scope=>$scope,static_symbols=>$bad,
   owner_kind=>'rule',owner=>'r',context=>'invalid static context');1};
  ok(!$ok,'malformed static context refuses');like($@,qr/static symbols/,'context shape has its own diagnostic');
 }
};
subtest 'every source owner and alias retains canonical static refusal' => sub {
 my$ordinal=0;
 for my$case([enum=>'mode','BUSY','(enums (mode (BUSY 1)))'],
  [package=>'shared','VALUE','(imports (package shared))']) {
  my($name,$prefix,$member,$decl)=@$case;my$token="$prefix.$member";
  for my$kind(qw(transaction rule drive)) {
   for my$op(qw(^ & | xor and or)) {
    my$rhs="($op $token)";
    my$body=$kind eq 'transaction'?"(transaction main (on start) (set out $rhs) (complete done))":
     $kind eq 'rule'?"(rule watch start (out $rhs))":
     "(drive tap (out $rhs)) (transaction main (on start) (drive tap) (complete done))";
    my$source="(actor owner_scope $decl (types (type frame (record ($member (bits 3)) (data (bits 5))))) "
     ."(interface (input start) (input $prefix (type frame)) (output out) (output done)) $body)";
    my$path=write_file("$name-owner-".$ordinal++.".isf",$source);
    my$ok=eval {FSM::Adapter::ISF->new->parse_file($path);1};my$error=$@;
    ok(!$ok,"$name $kind $op rejects the static operand");
    like($error,qr/operand '\Q$token\E' is not a declared packed scalar signal/,"$name $kind $op preserves the operand cause");
   }
  }
 }
 my$actor=FSM::Adapter::ISF->new->parse_file($paths{enum}{baseline});my$scope=record_actor_scope(actor=>$actor);
 my$symbols={'mode.BUSY'=>'1'};my$before=$json->encode([$scope,$symbols]);
 is_deeply(capture_expression_reductions(expression=>['^','mode.BUSY','mode.data'],scope=>$scope,
  static_symbols=>$symbols,owner_kind=>'rule',owner=>'r',context=>'binary control'),[],
  'ordinary multi-operand expressions may still use static values without reduction records');
 my$ok=eval {capture_expression_reductions(expression=>['^','mode.data[5]'],scope=>$scope,
  static_symbols=>$symbols,owner_kind=>'rule',owner=>'r',context=>'bounds control');1};
 ok(!$ok,'unrelated field still enforces declared selection bounds');like($@,qr/bounds control.*path/s,'bounds stay with the common path resolver');
 $symbols={'mode'=>0};my$marker_before=$json->encode($symbols);
 $ok=eval {capture_expression_reductions(expression=>['^','mode.data[0]'],scope=>$scope,
  static_symbols=>$symbols,owner_kind=>'rule',owner=>'r',context=>'static ancestor');1};
 ok(!$ok,'a selected descendant of a static root cannot borrow record layout even with a false marker');
 like($@,qr/not a declared packed scalar signal/,'namespace maps use canonical key membership');
 is($json->encode($symbols),$marker_before,'static marker values are never coerced');
 is($json->encode([$scope,{'mode.BUSY'=>'1'}]),$before,'all scope and original static marker kinds stay unchanged');
};
subtest 'all public transports refuse qualified statics before canonical carrier emission' => sub {
 my$api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
 for my$case([enum=>'mode.BUSY'],[package=>'shared.VALUE']) {
  my($name,$operand)=@$case;
  my$baseline=capture([$^X,'bin/fsmgen',qw(--strict --check --json),$paths{$name}{baseline}]);
  is($baseline->{exit_code},0,"$name otherwise identical ordinary scalar read stays valid");
  my$cause="Invalid ISF reductions: transaction 'main' clause[1] set RHS reduction '^' operand '$operand' is not a declared packed scalar signal";
  for my$mode([check=>[qw(--strict --check --json)],'fsmgen_check'],
   [semantic=>[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
   [schedule=>['--emit-schedule-json'],'fsmgen_schedule_preview']) {
   my($kind,$flags,$tool)=@$mode;
   my$native=capture([$^X,'bin/fsmgen',@$flags,$paths{$name}{reduction}]);
   isnt($native->{exit_code},0,"$name $kind source refuses");
   my$request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,arguments=>{source_id=>$paths{$name}{reduction}}}};
   my$response=$api->handle_jsonrpc_request($request);
   if($kind eq 'schedule') {
    is($native->{stdout},'',"$name preview emits no false success inventory");
    like($native->{stderr},qr/\Q$cause\E/,"$name preview preserves exact primary source cause");
    is(ref($response->{error}) eq 'HASH'?$response->{error}{code}:undef,-32000,"$name preview keeps existing message-only error boundary");
   } else {
    my$report=normalize_repository_paths($json->decode($native->{stdout}),$root);
    ok(!$report->{success},"$name $kind structured failure");
    is_deeply([map{$_->{message}}@{$report->{diagnostics}}],[$cause],"$name $kind exact source cause");
    ok(!exists $report->{source}{reductions},"$name $kind failure invents no source records");
    same($response->{result}{structuredContent}{report},$report,"$name $kind complete native/API failure equality");
    same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},"$name $kind text/structured equality");
   }
   my$wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
   is($wire->{exit_code},0,"$name $kind newline protocol succeeds");
   is($wire->{stderr},'',"$name $kind newline stderr clean");
   same($json->decode($wire->{stdout}),$response,"$name $kind complete API/newline failure equality");
  }
 }
};
done_testing;
