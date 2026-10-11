use strict;
use warnings;
use JSON::PP;
use File::Find;
use File::Basename qw(dirname);
use Digest::SHA;
use IPC::Open3;
use IO::Handle;
use Symbol qw(gensym);
use Time::HiRes qw(stat);

my @roots = ('docs/audits/raw-semantic-association-product-20261011',
             'docs/audits/raw-semantic-association-product-gate-repair-20261011');
my $archive = "$roots[1]/first-epoch.zip";
my @root_stat = stat '.';
my $json = JSON::PP->new->canonical->utf8;
sub plain {
    my ($path) = @_;
    die "own relative custody path" if $path =~ m{^/|(?:^|/)\.\.(?:/|$)|(?:^|/)\.git(?:/|$)};
    my $cursor = '';
    for my $part (split m{/}, $path) {
        $cursor .= ($cursor eq '' ? '' : '/') . $part;
        die "ordinary own custody boundary" if -l $cursor || -e "$cursor/.git";
        my @st = stat $cursor;
        die "same-volume custody source" if !@st || $st[0] != $root_stat[0];
    }
}
sub bytes {
    my ($path) = @_;
    plain($path);
    open my $fh, '<:raw', $path or die "open whole custody member: $!";
    local $/;
    my $raw = <$fh>;
    close $fh or die "close whole custody member: $!";
    return $raw;
}
sub graph {
    my (%files, %directories);
    find({no_chdir => 1, wanted => sub {
        my $path = $File::Find::name;
        plain($path);
        if (-d $path) { $directories{$path} = 1; }
        elsif (-f $path) { $files{$path} = 1; }
        else { die "ordinary custody source node"; }
    }}, @roots);
    return [sort keys %files], [sort keys %directories];
}
my %expected;
my $main = $json->decode(bytes("$roots[0]/manifest.json"));
$expected{"$roots[0]/$_"} = 1 for (keys %{$main->{files}}, 'manifest.json', 'checks.json');
my $repair = $json->decode(bytes("$roots[1]/qualified-manifest.json"));
$expected{"$roots[1]/$_"} = 1 for (keys %$repair, 'qualified-manifest.json');
my %expected_directories = map {$_ => 1} @roots;
for my $path (keys %expected) {
    my $directory = dirname($path);
    while (grep {$directory eq $_ || index($directory, "$_/") == 0} @roots) {
        $expected_directories{$directory} = 1;
        $directory = dirname($directory);
    }
}
my ($files, $directories) = graph();
die "complete sealed custody filesystem population" unless $json->encode($files) eq $json->encode([sort keys %expected]);
die "complete sealed custody directory population" unless $json->encode($directories) eq $json->encode([sort keys %expected_directories]);
open my $index_pipe, '-|', 'git', '--no-replace-objects', 'ls-files', '--stage', '-z', '--', @roots
    or die "open own index census: $!";
my $index_raw = do {local $/; <$index_pipe>};
close $index_pipe or die "complete own index census";
my %index;
for my $entry (split /\0/, $index_raw) {
    die "ordinary unambiguous staged custody member" unless $entry =~ /\A(100644|100755) ([0-9a-f]{40,64}) 0\t(.+)\z/s;
    my ($mode, $oid, $path) = ($1, $2, $3);
    die "unique staged custody member" if exists $index{$path};
    $index{$path} = {mode => $mode, oid => $oid};
}
die "required archived repair member is absent from Git index" unless exists $index{$archive};
die "complete required staged custody population" unless $json->encode([sort keys %index]) eq $json->encode($files);
my ($input, $output, $error);
$error = gensym;
my $pid = open3($input, $output, $error, 'git', '--no-replace-objects', 'cat-file', '--batch');
$input->autoflush(1);
binmode $input;
binmode $output;
my %members;
for my $path (@$files) {
    plain($path);
    my @before = stat $path;
    die "whole staged custody mode" unless (!!($before[2] & 0111)) == ($index{$path}{mode} eq '100755');
    print {$input} $index{$path}{oid}, "\n" or die "send whole staged object";
    my $header = <$output>;
    die "whole staged object header" unless $header =~ /\A\Q$index{$path}{oid}\E blob ([0-9]+)\n\z/ && $1 == $before[7];
    my $remaining = $before[7];
    my $digest = Digest::SHA->new(256);
    open my $fh, '<:raw', $path or die "open current custody body: $!";
    while ($remaining) {
        my $amount = $remaining > 1048576 ? 1048576 : $remaining;
        my ($blob, $current);
        my $count = read($output, $blob, $amount);
        die "complete staged object body" unless defined($count) && $count > 0;
        die "whole staged and current custody bytes" unless read($fh, $current, $count) == $count && $current eq $blob;
        $digest->add($blob);
        $remaining -= $count;
    }
    my $tail;
    die "complete staged and current object boundary" unless read($fh, $tail, 1) == 0 && read($output, $tail, 1) == 1 && $tail eq "\n";
    close $fh or die "close current custody body";
    my @after = stat $path;
    die "whole custody source epoch" unless join(':', @before[0,1,7,9]) eq join(':', @after[0,1,7,9]);
    $members{$path} = {%{$index{$path}}, bytes => $before[7], sha256 => $digest->hexdigest};
}
close $input or die "close staged object requests";
my $errors = (do {local $/; <$error>}) // '';
my $extra = (do {local $/; <$output>}) // '';
waitpid $pid, 0;
die "complete own staged object protocol" unless $? == 0 && $errors eq '' && $extra eq '';
my ($final_files, $final_directories) = graph();
die "whole custody directory epoch" unless $json->encode([$files, $directories]) eq $json->encode([$final_files, $final_directories]);
print $json->encode({members => \%members, directories => $directories,
    scope => 'Complete current staged Git/source namespace custody only. Original native/private and complete semantic scopes are unchanged.'}), "\n";
