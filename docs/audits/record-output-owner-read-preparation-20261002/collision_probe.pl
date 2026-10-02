use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $json = JSON::PP->new->canonical->utf8;
my $root = abs_path('.');
for my $name (qw(packet start done isf_child_start_seen)) {
    my $source = '(actor view_'.$name.' (clock clk) (reset (rst_n sync active_low))'
        .' (types (type frame (record (tag (bits 2)) (payload (signed (four_state (bits 3)))))))'
        .' (interface (input request) (output '.$name.' (type frame)) (output seen (width 3)) (output ack))'
        .' (storage (var held (type frame) (reset 5)))'
        .' (transaction worker (params (MODE 0)) (ports (output result (width 3)))'
        .' (set result '.$name.'.payload) (complete ack))'
        .' (transaction main (on request) (set '.$name.' held)'
        .' (do worker (params (MODE 1)) (bind (output result seen))) (complete ack)))';
    my $path = '.artifacts/record-output-owner-reads/sources/'.$name.'.isf';
    write_file($path, $source);
    my $parsed = attempt(sub {FSM::Adapter::ISF->new->parse_file($path)});
    my $result = {source => $source, source_id => $path, source_sha256 => sha256_hex($source), parse => $parsed};
    if ($parsed->{success}) {
        my $actor = $parsed->{value};
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        $result->{ir} = attempt(sub {$scheduler->{ir}->build_module($actor)});
        $result->{lower} = attempt(sub {$scheduler->lower($actor)});
        $result->{actor_before} = $json->decode($before);
        $result->{actor_after} = $actor;
    }
    write_file('.artifacts/record-output-owner-reads/'.$name.'.json',
        $json->encode(normalize_repository_paths($result, $root))."\n");
    print "$name actual source/private collision capture complete\n";
}
sub attempt {
    my ($run) = @_;
    my ($value, $error);
    my $ok = eval {$value = $run->(); 1};
    $error = $@ unless $ok;
    return {success => $ok ? JSON::PP::true : JSON::PP::false, value => $value, error => $error};
}
sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}
