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
my $module = $ENV{FSMGEN_GLOBAL_SOURCE} || 'perl/Global.pm';
my @products;
my @workspaces = map { tempdir(CLEANUP => 1) } 1 .. 2;
for my $workspace (@workspaces) {
    make_path(map { "$workspace/$_" } qw(tree/modules tree/data cwd));
    copy($module, "$workspace/tree/modules/Global.pm") or die $!;
    copy('perl/PathSearch.pm', "$workspace/tree/modules/PathSearch.pm") or die $!;
    copy('specs/pplugin.spec', "$workspace/tree/data/pplugin.spec") or die $!;
    write_file("$workspace/tree/data/fixture_link.conf", '(LINK_VALUE fixed)');
    write_file("$workspace/tree/data/fixture_conf.conf", '(CONF_VALUE retained)');
    write_file("$workspace/tree/probe.pl", <<'PERL');
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use JSON::PP;
use Scalar::Util qw(refaddr);
BEGIN {
    unshift @INC, $ARGV[0] eq 'absolute' ? Cwd::abs_path('modules') : 'modules';
}
use Global;

my $root = Cwd::abs_path('..');
my $configuration = Cwd::abs_path('modules') . '/env.conf';
chdir "$root/cwd" or die $!;
# Configuration does not exist during module loading: its read remains lazy.
write_config(<<'CONF');
(NAME late_configuration)
(PATH [FX_TOP]/payload)
(preload_list (link fixture_link) (conf fixture_conf))
CONF
my $global = Global->new;
my $values = {%$global};
$values->{FX_TOP} = File::Spec->abs2rel($values->{FX_TOP}, $root);
$values->{PATH} = File::Spec->abs2rel($values->{PATH}, $root);
write_config('(NAME changed_after_initialization)');
my $again = Global->new;
my $result = {
    values => $values,
    singleton => refaddr($global) == refaddr($again) ? 1 : 0,
    retained_name => $again->{NAME},
};
print JSON::PP->new->canonical->encode($result);

sub write_config {
    open my $file, '>:raw', $configuration or die $!;
    print {$file} $_[0] or die $!;
    close $file or die $!;
}
PERL
}

is(read_file("$workspaces[0]/tree/modules/Global.pm"), read_file("$workspaces[1]/tree/modules/Global.pm"),
    'moved fixture uses identical complete Global bytes');
for my $workspace (@workspaces) {
    for my $style (qw(relative absolute)) {
        # Each fresh interpreter must start without env.conf, including after
        # the previous absolute/relative fixture process initialized its copy.
        unlink "$workspace/tree/modules/env.conf" if -e "$workspace/tree/modules/env.conf";
        my $location = $workspace eq $workspaces[0] ? 'first' : 'moved';
        subtest "fresh $style Global load in $location fixture" => sub {
            is((stat($workspace))[0], (stat($repository))[0], 'fixture stays on repository volume');
            chdir "$workspace/tree" or die $!;
            my ($ok, $error, $full, $stdout, $stderr) = run(command => [
                $^X, "-I$repository/perl", 'probe.pl', $style,
            ]);
            chdir $repository or die $!;
            my $out = join '', @{$stdout || []};
            my $err = join '', @{$stderr || []};
            ok($ok, 'first configuration read after cwd change succeeds');
            is($err, '', 'configuration/preload initialization has no diagnostic');
            my $product = eval { $json->decode($out) };
            is_deeply($product, {
                values => {
                    NAME => 'late_configuration', PATH => 'tree/payload', FX_TOP => 'tree',
                    preload_list => { link => 'fixture_link', conf => 'fixture_conf' },
                    fixture_link => { LINK_VALUE => 'fixed' },
                    fixture_conf => { CONF_VALUE => 'retained' },
                },
                singleton => 1, retained_name => 'late_configuration',
            }, 'whole lazy configuration, root substitution, preloads and singleton contract');
            push @products, { style => $style, success => $ok ? 1 : 0, product => $product,
                stdout => $out, stderr => portable_diagnostic($err, $workspace),
                error => portable_diagnostic($error || '', $workspace) };
        };
    }
}
is_deeply([@products[0,1]], [@products[2,3]], 'whole configuration products survive moving the fixture root');
if (defined $ENV{FSMGEN_GLOBAL_CAPTURE}) {
    write_file($ENV{FSMGEN_GLOBAL_CAPTURE}, $json->encode({ module => $module, products => \@products }) . "\n");
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
