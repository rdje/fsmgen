#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA;
use File::Basename qw(dirname);
use File::Find qw(find);
use Fcntl qw(:mode);
use JSON::PP;

@ARGV == 1 or die "one complete intake source required";
open my $input, '<:raw', $ARGV[0] or die "read intake: $!";
my $source = decode_json(do { local $/; <$input> });
close $input or die "close intake: $!";
my @roots = @{$source->{roots}};
my %expected = %{$source->{members}};
my (%files, %directories, %wanted_directories);
my @root_stat = stat '.';
my $root = abs_path('.');

sub plain {
    my ($path) = @_;
    $path !~ m{\A/|(?:\A|/)\.\.(?:/|\z)|(?:\A|/)\.git(?:/|\z)}
        or die "own relative source path";
    my @info = lstat $path;
    @info && !S_ISLNK($info[2]) && $info[0] == $root_stat[0]
        or die "ordinary same-volume source node";
    my $cursor = $path;
    while ($cursor ne '.') {
        !-l $cursor && !-e "$cursor/.git" or die "own source repository boundary";
        $cursor = dirname($cursor);
    }
    abs_path($path) eq "$root/$path" or die "plain complete source path";
    return @info;
}

for my $name (keys %expected) {
    for my $selected (@roots) {
        next if exists $expected{$selected};
        next if index($name, "$selected/") != 0;
        my $parent = dirname($name);
        while ($parent eq $selected || index($parent, "$selected/") == 0) {
            $wanted_directories{$parent} = 1;
            last if $parent eq $selected;
            $parent = dirname($parent);
        }
    }
}

my $visit = sub {
    my $path = $File::Find::name;
    my @info = plain($path);
    if (S_ISDIR($info[2])) {
        $directories{$path} = 1;
        return;
    }
    S_ISREG($info[2]) or die "ordinary whole source member";
    !exists $files{$path} or die "disjoint complete source roots";
    open my $stream, '<:raw', $path or die "read whole source: $!";
    my $digest = Digest::SHA->new(256);
    $digest->addfile($stream);
    close $stream or die "close whole source: $!";
    my @after = lstat $path;
    join('/', @info[0,1,7,9]) eq join('/', @after[0,1,7,9])
        or die "whole native source epoch conserved";
    $files{$path} = {bytes => $info[7], sha256 => $digest->hexdigest,
                    executable => ($info[2] & 0111 ? JSON::PP::true : JSON::PP::false)};
};
plain($_) for @roots;
find({wanted => $visit, no_chdir => 1, follow => 0}, @roots);
join("\n", sort keys %files) eq join("\n", sort keys %expected)
    or die "complete independent source file population";
join("\n", sort keys %directories) eq join("\n", sort keys %wanted_directories)
    or die "complete independent source directory population";
for my $name (sort keys %expected) {
    my $wanted = $expected{$name};
    $files{$name}{bytes} == $wanted->{bytes}
        && $files{$name}{sha256} eq $wanted->{sha256}
        && $files{$name}{executable} == ($wanted->{mode} eq '100755' ? 1 : 0)
        or die "complete independent whole source bytes and mode";
}
print JSON::PP->new->canonical->encode({members => \%files,
    directories => [sort keys %directories]}), "\n";
