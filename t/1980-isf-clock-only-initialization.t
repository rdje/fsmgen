use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->pretty;
my %products;

for my $with_reset (0, 1) {
    subtest $with_reset ? 'explicit reset supplies reset assignments' : 'clock-only storage has no invented initialization' => sub {
        my $case = $with_reset ? 'explicit' : 'clock_only';
        my $reset = $with_reset ? '(reset (rst_n async active_low))' : '';
        my $source = <<"ISF";
(actor reset_initialization
  (clock-domains (domain core (clock clk) $reset))
  (interface (input start) (input we) (input data (width 8))
    (output live_value (width 8)) (output status_value (width 8)) (output done))
  (storage (var live (width 8) (reset 37)) (var status (width 8) (reset 19)))
  (rule write_live we (set live data))
  (transaction main (on start)
    (update live_value live) (update status_value status) (complete done)))
ISF
        my $path = "$work/$case.isf";
        write_file($path, $source);
        $path =~ s/^\Q$root\E\///;
        $products{$case}{source} = $source;
        for my $query (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)],
                semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my $r = capture([$^X, 'bin/fsmgen', @{$flags{$query}}, $path]);
            is($r->{exit_code}, 0, "$query accepts the complete ISF source") or diag($r->{stdout}, $r->{stderr});
            is($r->{stderr}, '', "$query stderr clean");
            return if $r->{exit_code};
            my $report = $json->decode($r->{stdout});
            $products{$case}{queries}{$query} = FSM::Test::SourceQueryRunner::normalize_repository_paths($report, $root);
            my $origin = $query eq 'schedule' ? $report->{reset_provenance} : $report->{source}{reset_provenance};
            is_deeply($origin, [{domain => 'core', origin => $with_reset ? 'explicit' : 'domain_absent'}], 'reset clause origin matches source');
            if ($query eq 'semantic') {
                is($report->{semantic}{explicit_system_contract}{reset}, $with_reset ? 'rst_n' : undef,
                    'effective reset is separate from storage reset values');
            }
        }
        for my $language (qw(systemverilog verilog)) {
            my $output = "$work/$case.$language";
            my $r = capture([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                '--output', $output, $path]);
            is($r->{exit_code}, 0, "$language emits the standalone domain") or diag($r->{stdout}, $r->{stderr});
            return if $r->{exit_code};
            my $hdl = read_file($output);
            $products{$case}{hdl}{$language} = $hdl;
            $hdl =~ s{//[^\n]*}{}g;
            unlike($hdl, qr/\binitial\b/, 'no power-on initial block');
            for my $signal (qw(live status)) {
                like($hdl, qr/\breg\s+\[7:0\]\s+\Q$signal\E\s*;/, "$signal declaration has no initializer");
            }
            like($hdl, qr/\bcurrent_state\s*,\s*next_state\s*;/, 'state declaration has no initializer');
            my @state_writes = $hdl =~ /\bcurrent_state\s*<=\s*([^;]+);/g;
            if ($with_reset) {
                like($hdl, qr/\@\(posedge clk or negedge rst_n\)/, 'actual reset event is present');
                is_deeply(\@state_writes, ['MAIN_IDLE_0', 'next_state'], 'reset selects the initial state');
                like($hdl, qr/\blive\s*<=\s*(?:8'd)?37\s*;/, 'written storage has explicit reset assignment');
                like($hdl, qr/\bstatus\s*<=\s*(?:8'd)?19\s*;/, 'read-only storage has explicit reset assignment');
            } else {
                unlike($hdl, qr/\brst_n\b|\bnegedge\b/, 'no reset pin or reset event');
                is_deeply(\@state_writes, ['next_state'], 'state only samples its computed successor');
                my @live_writes = $hdl =~ /\blive\s*<=\s*([^;]+);/g;
                is(scalar @live_writes, 1, 'written storage has only its ordinary clocked assignment');
                my $next = $live_writes[0] // '';
                like($next, qr/\A[A-Za-z_][A-Za-z0-9_]*\z/, 'clocked value is the selected next-value signal');
                unlike($hdl, qr/\bstatus\s*(?:<=|=)/, 'reset metadata alone invents no write or initialization');
                like($hdl, qr/\b\Q$next\E\s*=\s*live\s*;/, 'unwritten cycles retain current value without initializing it');
                like($hdl, qr/\b\Q$next\E\s*=\s*data\s*;/, 'ordinary write data reaches the selected next value');
            }
        }
    };
}

if (defined(my $capture_path = $ENV{FSMGEN_CLOCK_ONLY_CAPTURE})) {
    die 'capture path must be repository-local beneath .artifacts' unless $capture_path =~ m{\A\.artifacts/[A-Za-z0-9_/-]+\.json\z};
    write_file($capture_path, $json->encode(\%products));
}
done_testing();

sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], '') }
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
