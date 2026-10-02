use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use Test::More;
use FSM::Test::ProjectDataLocality;
use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use JSON::PP;

my $repository = getcwd();
my $json = JSON::PP->new->canonical;
my $module = $ENV{FSMGEN_PATHSEARCH_SOURCE} || 'perl/PathSearch.pm';
my $capture = $ENV{FSMGEN_PATHSEARCH_CAPTURE};
my $first = tempdir(CLEANUP => 1);
my $second = tempdir(CLEANUP => 1);

for my $workspace ($first, $second) {
    make_path(map { "$workspace/$_" } qw(tree/modules tree/data cwd extra));
    copy($module, "$workspace/tree/modules/PathSearch.pm") or die $!;
    write_file("$workspace/tree/data/tree_only.conf", 'tree bytes');
    write_file("$workspace/cwd/cwd_only.conf", 'cwd bytes');
    write_file("$workspace/extra/extra_only.custom", 'extra bytes');
    write_file("$workspace/tree/probe.pl", <<'PERL');
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use File::Spec;
use JSON::PP;
BEGIN {
    unshift @INC, $ARGV[0] eq 'absolute' ? Cwd::abs_path('modules') : 'modules';
}
use PathSearch;

my $root = Cwd::abs_path('..');
my $search = PathSearch->new;
die "empty basename initialized a search\n" if defined $search->go(undef);
chdir "$root/cwd" or die $!;
my %result;
for my $name (qw(tree_only cwd_only)) {
    my $path = $search->go($name);
    die "missing $name\n" unless defined $path;
    open my $file, '<:raw', $path or die $!;
    local $/;
    $result{$name} = {
        path => File::Spec->abs2rel(Cwd::abs_path($path), $root),
        bytes => <$file>,
    };
    close $file or die $!;
}
my $extra = $search->go('extra_only', 'custom', "$root/extra");
die "missing explicit extra directory\n" unless defined $extra;
$result{extra_path} = File::Spec->abs2rel(Cwd::abs_path($extra), $root);
$result{retained_extra_path} = File::Spec->abs2rel(
    Cwd::abs_path($search->go('extra_only', 'custom')), $root);
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $result{missing} = $search->go('absent_probe');
}
$result{missing_warning} = @warnings == 1
    && $warnings[0] =~ /Unable to find file 'absent_probe\.conf'/ ? 1 : 0;
print JSON::PP->new->canonical->encode(\%result);
PERL
}

is(read_file("$second/tree/modules/PathSearch.pm"), read_file("$first/tree/modules/PathSearch.pm"),
    'moved fixture uses identical complete module bytes');
my @products;
for my $workspace ($first, $second) {
    for my $style (qw(relative absolute)) {
        my $location = $workspace eq $first ? "first" : "moved";
        subtest "fresh $style load in $location fixture" => sub {
            is((stat($workspace))[0], (stat($repository))[0], 'fixture stays on repository volume');
            chdir "$workspace/tree" or die $!;
            my ($ok, $error, $full, $stdout, $stderr) = run(command => [
                $^X, "-I$repository/perl", 'probe.pl', $style,
            ]);
            chdir $repository or die $!;
            my $out = join '', @{$stdout || []};
            my $err = join '', @{$stderr || []};
            ok($ok, 'load before chdir and first search after chdir succeeds');
            is($err, '', 'successful search has no initialization diagnostic');
            my $product = eval { $json->decode($out) };
            is_deeply($product, {
                tree_only => { path => 'tree/data/tree_only.conf', bytes => 'tree bytes' },
                cwd_only => { path => 'cwd/cwd_only.conf', bytes => 'cwd bytes' },
                extra_path => 'extra/extra_only.custom',
                retained_extra_path => 'extra/extra_only.custom',
                missing => undef,
                missing_warning => 1,
            }, 'module-root, first-call cwd, extension, retained extras and missing-file contract');
            push @products, { style => $style, success => $ok ? 1 : 0,
                product => $product, stdout => $out,
                stderr => portable_diagnostic($err, $workspace),
                error => portable_diagnostic($error || '', $workspace) };
        };
    }
}
is_deeply([@products[0,1]], [@products[2,3]], 'whole fresh-process products survive moving the fixture root');
if (defined $capture) {
    write_file($capture, $json->encode({ module => $module, products => \@products }) . "\n");
}
done_testing;

sub portable_diagnostic {
    my ($value, $workspace) = @_;
    $value =~ s/\Q$workspace\E/<workspace>/g;
    $value =~ s/\Q$repository\E/./g;
    return $value;
}

sub read_file {
    my ($path) = @_;
    open my $file, '<:raw', $path or die $!;
    local $/;
    my $bytes = <$file>;
    close $file or die $!;
    return $bytes;
}

sub write_file {
    my ($path, $bytes) = @_;
    open my $file, '>:raw', $path or die $!;
    print {$file} $bytes or die $!;
    close $file or die $!;
}
