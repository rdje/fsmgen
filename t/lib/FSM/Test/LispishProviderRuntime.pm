package FSM::Test::LispishProviderRuntime;

use strict;
use warnings;
use Exporter qw(import);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp ();
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::ProcessSupervisor qw(repository_root supervise_process);

our @EXPORT_OK = qw(run_provider_case);
my $ROOT = repository_root();
my %CASES = map { $_ => 1 } qw(api absolute relative missing outside syntax);

# Fixed programmes and fixture layout: callers select a case, never commands.
my $CHILD = <<'CHILD';
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use JSON::PP;
my ($root, $workspace, $case) = @ARGV;
unshift @INC, "$root/perl";
unshift @INC, $case eq 'relative' ? 'bundle/perl' : "$workspace/bundle/perl";
unshift @INC, sub {
    die "Forbidden legacy import: $_[1]\n" if $_[1] =~ m{\A(?:PPlugin|Global|HUtils)\.pm\z};
    return;
};
require File::Find;
{
    no warnings qw(redefine once);
    *File::Find::find = sub { die "Forbidden recursive discovery\n" };
}
require Lispish;
chdir "$workspace/decoy" or die "cannot enter decoy cwd: $!\n";
my $json = JSON::PP->new->canonical;
my %result;
if ($case eq 'syntax') {
    my $input = ')';
    Lispish::single(\$input);
    die "unexpected close was accepted\n";
}
if ($case eq 'missing' || $case eq 'outside') {
    my $input = '(only)';
    $result{parser_ok} = eval { Lispish::single(\$input); 1 } ? 1 : 0;
    $result{error} = $@;
} else {
    my @inputs = (
        '(actor parser_contract (clock clk))', '(only)', '()',
        '(node "two words" x[3] {a + b})', '(node 007 -2 0x2)',
        "(first a)\n(second b)",
    );
    $result{forms} = [map { my $input = $_; scalar Lispish::multi(\$input) } @inputs];
    my $input = $inputs[-1];
    $result{single} = [Lispish::single(\$input), Lispish::single(\$input), Lispish::single(\$input)];
    $input = $inputs[-1];
    $result{list} = [Lispish::multi(\$input)];
    $result{file} = scalar Lispish::multi("$workspace/input.fsm");
    my $grammar = read_file("$workspace/bundle/specs/Lispish.spec");
    my $parser = LinkedSpec::Get(\$grammar);
    die "no direct parser\n" unless ref($parser) eq 'CODE';
    $input = $inputs[0];
    $result{before} = $parser->(\$input);
    my $other = read_file("$root/specs/pplugin.spec");
    my $other_parser = LinkedSpec::Get(\$other);
    die "no second parser\n" unless ref($other_parser) eq 'CODE';
    $input = $inputs[0];
    $result{after} = $parser->(\$input);
    $input = $inputs[0];
    $result{cached_after} = Lispish::single(\$input);
}
$result{legacy_loaded} = [grep { exists $INC{$_} } qw(PPlugin.pm Global.pm HUtils.pm)];
print $json->encode(\%result), "\n";
sub read_file {
    open my $stream, '<:raw', $_[0] or die "cannot read fixture: $!\n";
    local $/;
    my $body = <$stream>;
    close $stream or die "cannot close fixture: $!\n";
    return $body;
}
CHILD

sub run_provider_case {
    my ($case) = @_;
    die "unknown Lispish provider case\n" unless defined($case) && $CASES{$case};
    my $base = ensure_project_artifact_dir(qw(tmp lispish-provider-tests));
    my $workspace = File::Temp::tempdir('provider-XXXXXXXX', DIR => $base, CLEANUP => 0);
    die "provider fixture is off volume\n" unless (stat($workspace))[0] == (stat($ROOT))[0];
    make_path(map { "$workspace/$_" } qw(bundle/perl bundle/specs decoy/specs));
    copy("$ROOT/perl/Lispish.pm", "$workspace/bundle/perl/Lispish.pm") or die $!;
    if ($case eq 'outside') {
        symlink("$ROOT/specs/Lispish.spec", "$workspace/bundle/specs/Lispish.spec") or die $!;
    } elsif ($case ne 'missing') {
        copy("$ROOT/specs/Lispish.spec", "$workspace/bundle/specs/Lispish.spec") or die $!;
    }
    _write("$workspace/decoy/specs/Lispish.spec", "INVALID CWD DECOY\n");
    _write("$workspace/input.fsm", "(first a)\n(second b)");
    _write("$workspace/probe.pl", $CHILD);
    my %environment = %ENV;
    delete @environment{qw(PERL5OPT PERL5LIB PERLLIB BASH_ENV ENV)};
    @environment{qw(TMPDIR TMP TEMP)} = ($workspace) x 3;
    my $result = supervise_process(
        schema => 'fsmgen.test.lispish_provider.v1',
        stage => 'provider_case', containment => 'lispish_provider_group',
        bounds => { timeout_seconds => 60, capture_limit_bytes => 1_048_576 },
        cwd => $workspace, environment => \%environment,
        argv => [$^X, "$workspace/probe.pl", $ROOT, $workspace, $case],
    );
    if ($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}) {
        remove_tree($workspace);
    }
    $result->{fixture_retired} = -e $workspace ? 0 : 1;
    return $result;
}

sub _write {
    open my $stream, '>:raw', $_[0] or die $!;
    print {$stream} $_[1] or die $!;
    close $stream or die $!;
}

1;
