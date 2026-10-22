use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use File::Find qw(find);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

# ISF-REDUCTION-DELIVERY.1.2.3.3.1: --quiet suppresses informational
# lowering/trace announcements, while all products and diagnostics retain
# their existing contracts. No external HDL tools run.
my $work=tempdir(CLEANUP=>1);
my $json=JSON::PP->new->canonical;
my $capture_dir;
if (defined(my $epoch=$ENV{FSMGEN_INTENT_QUIET_CAPTURE})) {
    die 'invalid quiet capture epoch' unless $epoch =~ /\A[a-zA-Z0-9_-]{1,64}\z/;
    $capture_dir=".artifacts/tmp/intent-quiet-$epoch";
    mkdir $capture_dir or die "exclusive quiet capture directory: $!";
}
sub capture {FSM::Test::SourceQueryRunner::_capture($_[0],'')}
sub read_file {open my $fh,'<:raw',$_[0] or die $!; local $/; return <$fh>}
sub normalize_date {my $s=$_[0]; $s =~ s{^// Date:[^\n]*$}{// Date: GENERATED}mg; return $s}
sub same {is($json->encode($_[0]),$json->encode($_[1]),$_[2])}
sub preserve {
    return unless defined $capture_dir;
    sysopen my $fh,"$capture_dir/$_[0].json",O_WRONLY|O_CREAT|O_EXCL or die $!;
    print {$fh} $json->encode($_[1])."\n" or die $!;
    close $fh or die $!;
}
sub lowered_files {
    my ($dir)=@_;
    my %files;
    find({no_chdir=>1,wanted=>sub {
        return unless -f $File::Find::name;
        my $name=$File::Find::name; $name =~ s/\A\Q$dir\E\///;
        $files{$name}=read_file($File::Find::name);
    }},$dir);
    return \%files;
}
for my $case (
    ['isf','isf/unary_reductions.isf','ISF Intent Scheduling'],
    ['single','ppif/valid_ready_handshake.ppif','IAL2 Protocol/Platform Intent'],
    ['bundle','ppif/valid_ready_dual_channel_bundle.ppif','IAL2 Protocol/Platform Intent Bundle'],
) {
    my ($name,$source,$heading)=@$case;
    subtest "$name quiet generation preserves verbose, lowered, HDL, trace and machine products" => sub {
        my $before=read_file($source);
        my %products;
        my @observations;
        for my $mode (qw(verbose quiet short trace)) {
            my $dir="$work/$name-$mode-lowered";
            mkdir $dir or die $!;
            my $output="$work/$name-$mode.sv";
            my $trace="$work/$name-$mode.trace";
            my @flags=$mode eq 'verbose' ? () : $mode eq 'short' ? ('-q') : ('--quiet');
            push @flags,'--trace-verbosity=debug','--trace-log',$trace if $mode eq 'trace';
            my @argv=($^X,'bin/fsmgen','--strict',@flags,'--outdir',$dir,'--output',$output,$source);
            my $r=capture(\@argv);
            is($r->{exit_code},0,"$mode generation succeeds") or diag($r->{stdout},$r->{stderr});
            is($r->{signal},0,"$mode no signal");
            is($r->{stderr},'',"$mode clean success stderr");
            if ($mode eq 'verbose') {
                like($r->{stdout},qr/=== \Q$heading\E ===/, 'ordinary progress heading remains visible');
                like($r->{stdout},qr/^Wrote: /m, 'ordinary explicit lowered-artifact announcements remain visible');
            } else {
                is($r->{stdout},'',"$mode suppresses every informational announcement");
            }
            next if $r->{exit_code};
            my $hdl=read_file($output);
            my $lowered=lowered_files($dir);
            ok(keys(%$lowered)>0,"$mode creates actual lowered review artifacts");
            if ($mode eq 'verbose') {$products{hdl}=$hdl;$products{lowered}=$lowered}
            else {
                is(normalize_date($hdl),normalize_date($products{hdl}),"$mode complete HDL unchanged except generated date");
                same($lowered,$products{lowered},"$mode complete lowered artifacts byte-identical");
            }
            my $trace_text=-f $trace ? read_file($trace) : undef;
            if ($mode eq 'trace') {
                ok(defined($trace_text) && length($trace_text),'quiet trace still reaches its explicit trace file');
                like($trace_text // '',qr/Initialize ISF adapter facade/,
                    'explicit trace includes initial source lowering, before HDL generation');
            }
            push @observations,{mode=>$mode,argv=>\@argv,result=>$r,hdl=>$hdl,lowered=>$lowered,
                trace_bytes=>(-f $trace ? -s $trace : undef),trace_text=>$trace_text};
        }
        my @machine;
        for my $kind ([check=>qw(--check --json)],[semantic=>'--emit-semantic-json'],[schedule=>'--emit-schedule-json']) {
            my ($label,@flags)=@$kind;
            my @results;
            for my $quiet (0,1) {
                my @argv=($^X,'bin/fsmgen','--strict',($quiet ? '--quiet' : ()),@flags,$source);
                my $r=capture(\@argv);
                is($r->{exit_code},0,"$label quiet=$quiet normal machine success") or diag($r->{stdout},$r->{stderr});
                is($r->{signal},0,"$label quiet=$quiet no signal");
                is($r->{stderr},'',"$label quiet=$quiet clean machine stderr");
                my $report=$json->decode($r->{stdout});
                ok(ref($report) eq 'HASH',"$label quiet=$quiet one complete JSON object");
                push @results,{argv=>\@argv,result=>$r,report=>$report};
            }
            same($results[0]{report},$results[1]{report},"$label complete machine report independent of quiet");
            my @traced;
            for my $quiet (0,1) {
                my $trace="$work/$name-$label-quiet$quiet.trace";
                my @argv=($^X,'bin/fsmgen','--strict',($quiet ? '--quiet' : ()),
                    '--trace-verbosity=debug','--trace-log',$trace,@flags,$source);
                my $r=capture(\@argv);
                is($r->{exit_code},0,"$label traced quiet=$quiet normal machine success");
                is($r->{signal},0,"$label traced quiet=$quiet no signal");
                is($r->{stderr},'',"$label traced quiet=$quiet clean machine stderr");
                my $report=eval {$json->decode($r->{stdout})};
                my $error=$@;
                my $valid=ok(ref($report) eq 'HASH',"$label traced quiet=$quiet one uncontaminated JSON object");
                diag(substr($error,0,240)) unless $valid;
                same($report,$results[0]{report},"$label traced quiet=$quiet complete machine report unchanged") if $valid;
                my $trace_text=-f $trace ? read_file($trace) : undef;
                like($trace_text // '',qr/Initialize ISF adapter facade/,
                    "$label traced quiet=$quiet initial lowering reaches the trace file");
                push @traced,{argv=>\@argv,result=>$r,report=>$report,decode_error=>$error,trace_text=>$trace_text};
            }
            push @machine,{kind=>$label,results=>\@results,traced=>\@traced};
        }
        is(read_file($source),$before,'source bytes remain unchanged');
        preserve($name,{source_path=>$source,source=>$before,generation=>\@observations,machine=>\@machine});
    };
}
done_testing();
