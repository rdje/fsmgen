#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

my %docs = map {
    $_ => read_repo_file($_)
} qw(
    docs/ISF_SPEC.md
    docs/book/src/14-feature-backlog.md
    docs/book/src/13g-rules.md
    docs/book/src/13j-type-enum-aggregate.md
);

my @stale_patterns = (
    qr/standalone enum member or aggregate guards, rule target enum members, and enum members.*remain deferred/s,
    qr/standalone\s+enum\/aggregate guards, enum rule targets, and subaggregate rule targets remain\s+backlog/s,
);

for my $path (sort keys %docs) {
    for my $pattern (@stale_patterns) {
        unlike(
            $docs{$path},
            $pattern,
            "$path does not contain stale standalone enum/aggregate rule guard backlog wording",
        );
    }
}

like(
    $docs{'docs/ISF_SPEC.md'},
    qr/Standalone enum member rule guards and standalone scalar aggregate\s+storage leaf rule guards are shipped/s,
    'ISF spec states standalone enum and scalar aggregate rule guards are shipped',
);

like(
    $docs{'docs/book/src/14-feature-backlog.md'},
    qr/Standalone scalar enum and scalar aggregate rule guards are\s+shipped/s,
    'feature backlog states standalone enum and scalar aggregate rule guards are shipped',
);

like(
    $docs{'docs/book/src/14-feature-backlog.md'},
    qr/The remaining backlog is aggregate paths in rule assignment RHS or\s+rule guard expression operator position/s,
    'feature backlog preserves the remaining rule guard/operator deferrals',
);

like(
    $docs{'docs/book/src/13g-rules.md'},
    qr/\(rule fire_when_busy mode\.BUSY\s+\(set fire 1\)\)/s,
    'rules chapter keeps the standalone enum rule guard example',
);

like(
    $docs{'docs/book/src/13g-rules.md'},
    qr/\(rule fire_when_flag frame\.flag\s+\(set fire 1\)\)/s,
    'rules chapter keeps the standalone aggregate rule guard example',
);

like(
    $docs{'docs/book/src/13j-type-enum-aggregate.md'},
    qr/Standalone rule guard.*\(rule r mode\.BUSY/s,
    'type/enum/aggregate chapter keeps standalone enum rule guard row',
);

like(
    $docs{'docs/book/src/13j-type-enum-aggregate.md'},
    qr/Standalone rule guard.*\(rule fire frame\.flag/s,
    'type/enum/aggregate chapter keeps standalone aggregate rule guard row',
);

done_testing();

sub read_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}
