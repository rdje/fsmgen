use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use Test::More;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use JSON::PP;
use Cwd qw(getcwd);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname basename);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::FileDocumentOriginAuthority;
use FSM::Adapter::ISF::Parser;

my $json = JSON::PP->new->canonical;
my $repository = getcwd();
my $capture = $ENV{FSMGEN_FILE_ORIGIN_CAPTURE};
$capture = File::Spec->rel2abs($capture) if defined $capture;
my @inputs = sort glob 'docs/audits/conditional-origin-atl-20261002/current-bound/*.json';
@inputs = grep {basename($_) ne 'atl-only.json' && basename($_) ne 'finalization.json'} @inputs;
is(scalar @inputs, 24, 'complete immutable use/ATL original-source cohort');
subtest 'actual file refusal reason excludes the caller expectation' => sub {
    my $pattern = qr/file_reason_only_in_caller_argument/;
    my $error = file_refusal_with_echo($pattern);
    is(diagnostic_line($error), 'file origin independent document set required',
        'actual constructor supplies the first diagnostic reason');
    like($error, $pattern, 'actual Carp trace echoes the caller regex');
    ok(!diagnostic_matches($error, 'file_reason_only_in_caller_argument'), 'caller echo cannot authenticate a wrong reason');
    my @controls;
    refuses('actual-constructor-positive', sub {
        FSM::Test::FileDocumentOriginAuthority->from_files('missing.isf', {}, []);
    }, 'file origin independent document set required', \@controls);
    capture('diagnostic-echo', {error => $error, expected => 'file_reason_only_in_caller_argument',
        matched => diagnostic_matches($error, 'file_reason_only_in_caller_argument') ? 1 : 0, controls => \@controls});
};
subtest 'file cause matching excludes primary source-label echo' => sub {
    my $expected = 'file origin selected source bytes differ from authority';
    my $workspace = tempdir(CLEANUP => 1);
    my $label = File::Spec->abs2rel("$workspace/$expected.isf", $repository);
    my $source = '(not_actor)';
    write_file($label, $source);
    my $accepted = eval {
        FSM::Test::FileDocumentOriginAuthority->from_files($label, {$label => $source}, []);
        1;
    };
    my $error = $@;
    ok(!$accepted, 'actual unrelated file source refuses');
    is(diagnostic_line($error), "Error: no (actor ...) root found in '$label'", 'real file label appears in unrelated primary cause');
    like(diagnostic_line($error), qr/selected source bytes differ from authority/, 'primary message actually echoes wanted text');
    ok(!diagnostic_matches($error, $expected), 'complete cause cannot be authenticated by file label text');
    capture('diagnostic-label', {source => $source, label => $label, error => $error,
        expected => $expected, accepted => $accepted ? 1 : 0,
        matched => diagnostic_matches($error, $expected)});
};
for my $path (@inputs) {
    my $input = $json->decode(read_file($path));
    subtest "file-backed portable origins $input->{case}{name}" => sub {
        my @products;
        for my $layout (qw(adjacent search dotted)) {
            my ($documents, $mapping) = documents_for($input, $layout);
            my $first = tempdir(CLEANUP => 1);
            my $second = tempdir(CLEANUP => 1);
            write_documents($first, $documents);
            # Copy, verify, then use a differently named physical root. Every
            # copy stays on the repository volume; no global/temp store is used.
            for my $name (sort keys %$documents) {
                make_path(dirname("$second/$name"));
                copy("$first/$name", "$second/$name") or die $!;
                is(read_file("$second/$name"), $documents->{$name}, 'complete moved file bytes verified');
            }
            my @moved;
            for my $workspace ($first, $second) {
                is((stat($workspace))[0], (stat($repository))[0], 'actual workspace remains on repository volume');
                chdir $workspace or die $!;
                local $ENV{FSMLIB} = 'libraries';
                my $ordinary = FSM::Adapter::ISF::Parser->new->parse_file('sources/main.isf');
                my $portable = expected_projection($ordinary, undef, sub {runtime_relative($_[0])});
                my $expected = expected_projection($input->{ordinary}, $input->{proof}, sub {$mapping->{$_[0]} // die 'unknown predecessor identity'});
                my $authority = authority_class()->from_files('sources/main.isf', $documents, ['libraries']);
                my ($actor, $proof) = ($authority->actor, $authority->proof);
                is($json->encode($portable), $json->encode($expected->[0]), 'complete ordinary file product equals independent immutable actor');
                is($json->encode([$actor,$proof]), $json->encode($expected), 'whole file actor/proof/primitive kinds equal independent predecessor projection');
                ok($authority->validate(clone($actor), clone($proof)), 'opaque whole products authenticate against supplied file bytes');
                my @selected = map {{identity=>runtime_relative($_->{library_source}), absolute=>File::Spec->file_name_is_absolute($_->{library_source})?1:0}}
                    @{$ordinary->{library_uses}};
                is_deeply([map {$_->{absolute}} @selected], [($layout eq 'adjacent' ? 1 : 0) x @selected],
                    'actual canonical absolute root candidate versus relative FSMLIB candidate');
                my @controls;
                for my $name (qw(identity document_digest producer_swap source_operation target coverage scalar_kind)) {
                    my ($bad_actor,$bad_proof)=(clone($actor),clone($proof));
                    if ($name eq 'identity') {$bad_proof->{atl}[0]{resolution}{library_source}='sources/forged.isf'}
                    elsif ($name eq 'document_digest') {$bad_proof->{documents}[0]{source_sha256}='0' x 64}
                    elsif ($name eq 'producer_swap') {$bad_proof->{atl}[0]{actor_id}=1}
                    elsif ($name eq 'source_operation') {$bad_proof->{uses}[0]{ledger}{catalog}[0]{operation}='forged'}
                    elsif ($name eq 'target') {$bad_actor->{library_uses}[0]{actor}{actor_name}='forged'}
                    elsif ($name eq 'coverage') {pop @{$bad_proof->{documents}}}
                    elsif ($name eq 'scalar_kind') {$bad_proof->{atl}[0]{actor_id}="$bad_proof->{atl}[0]{actor_id}"}
                    my $before=$json->encode([$bad_actor,$bad_proof]);
                    my $accepted=eval {$authority->validate($bad_actor,$bad_proof);1};
                    my $diagnostic=$@;
                    ok(!$accepted,"actual $name reload refuses");
                    like(diagnostic_line($diagnostic),qr/differs from authoritative document set/,'complete independent source authentication');
                    is($json->encode([$bad_actor,$bad_proof]),$before,'validation preserves original submitted kinds');
                    push @controls,{name=>$name,actor=>$bad_actor,proof=>$bad_proof,accepted=>$accepted?1:0,
                        diagnostic=>($diagnostic =~ /\A([^\n]*)/ ? $1 : '')};
                }
                my $view=$authority->proof;
                $view->{atl}[0]{instance}='forged_view';
                is($json->encode($authority->proof),$json->encode($proof),'returned views detach completely');
                push @moved, {actor=>$actor,proof=>$proof,ordinary=>$portable,selected=>\@selected,controls=>\@controls};
                chdir $repository or die $!;
            }
            is($json->encode($moved[0]),$json->encode($moved[1]),'moved root reconstructs every whole product and refusal');
            push @products,{layout=>$layout,documents=>$documents,roots=>\@moved};
        }
        capture($input->{case}{name},{case=>$input->{case},predecessor=>$path,products=>\@products});
    };
}

subtest 'actual file precedence and independently supplied membership' => sub {
    my $input=$json->decode(read_file($inputs[0]));
    my ($documents)=documents_for($input,'adjacent');
    my $workspace=tempdir(CLEANUP=>1);
    write_documents($workspace,$documents);
    my %decoys;
    for my $name (grep {$_ ne 'sources/main.isf'} keys %$documents) {
        my $filename=basename($name);
        $decoys{"libraries/$filename"}=$documents->{$name}."\n ";
        $decoys{"other/$filename"}=$documents->{$name}."\n  ";
        $decoys{$filename}=$documents->{$name}."\n   ";
        if ($filename eq 'common.choice.isf') {
            $decoys{'sources/common/choice.isf'}=$documents->{$name}."\n    ";
        }
    }
    write_documents($workspace,\%decoys);
    chdir $workspace or die $!;
    my @controls;
    my $authority=authority_class()->from_files('sources/main.isf',$documents,['libraries','other']);
    is_deeply([map {$_->{source_label}} @{$authority->proof->{documents}}],[sort keys %$documents],
        'adjacent files precede both FSMLIB roots and current directory');
    # A consistent digest of a lower-priority source cannot authorize the
    # higher-priority actual file, even though its whole actor is identical.
    my $shadow=clone($documents);
    my ($selected)=sort grep {$_ ne 'sources/main.isf'} keys %$documents;
    $shadow->{$selected}.="\n ";
    refuses('selected-byte-substitution',sub {authority_class()->from_files('sources/main.isf',$shadow,['libraries'])},'file origin selected source bytes differ from authority',
        \@controls);
    my $missing=clone($documents);delete $missing->{$selected};
    refuses('missing-selected-authority',sub {authority_class()->from_files('sources/main.isf',$missing,['libraries'])},'file origin selected document authority missing',
        \@controls);
    my $root_changed=clone($documents);$root_changed->{'sources/main.isf'}.="\n ";
    refuses('root-byte-substitution',sub {authority_class()->from_files('sources/main.isf',$root_changed,['libraries'])},'file origin root bytes differ from authority',
        \@controls);
    write_file($selected,$documents->{$selected}."\n ");
    refuses('actual-file-mutation',sub {authority_class()->from_files('sources/main.isf',$documents,['libraries'])},'file origin selected source bytes differ from authority',
        \@controls);
    write_file($selected,$documents->{$selected});
    my $unused=clone($documents);$unused->{'libraries/unused.isf'}='(library unused (actor worker))';
    refuses('unused-authority',sub {authority_class()->from_files('sources/main.isf',$unused,['libraries'])},'library origin authoritative document membership differs',
        \@controls);
    unlink $selected or die $!;
    refuses('deleted-selected-file',sub {authority_class()->from_files('sources/main.isf',$documents,['libraries'])},'file origin selected document authority missing',
        \@controls);
    # A remaining root-relative pathish file still outranks FSMLIB. Remove it
    # explicitly before qualifying the next search coordinate.
    unlink 'sources/common/choice.isf' or die $! if -f 'sources/common/choice.isf';
    my $fallback=clone($documents);
    delete $fallback->{$selected};$fallback->{'libraries/'.basename($selected)}=$decoys{'libraries/'.basename($selected)};
    my $after=authority_class()->from_files('sources/main.isf',$fallback,['libraries','other']);
    ok(grep($_->{source_label} eq 'libraries/'.basename($selected),@{$after->proof->{documents}}),'first FSMLIB root wins after adjacent deletion');
    unlink 'libraries/'.basename($selected) or die $!;
    my $last=clone($fallback);
    delete $last->{'libraries/'.basename($selected)};$last->{'other/'.basename($selected)}=$decoys{'other/'.basename($selected)};
    my $final=authority_class()->from_files('sources/main.isf',$last,['libraries','other']);
    ok(grep($_->{source_label} eq 'other/'.basename($selected),@{$final->proof->{documents}}),'second FSMLIB root wins only after first deletion');
    unlink 'other/'.basename($selected) or die $!;
    my $cwd_documents=clone($last);
    delete $cwd_documents->{'other/'.basename($selected)};
    $cwd_documents->{basename($selected)}=$decoys{basename($selected)};
    my $cwd=authority_class()->from_files('sources/main.isf',$cwd_documents,['libraries','other']);
    ok(grep($_->{source_label} eq basename($selected),@{$cwd->proof->{documents}}),'current directory follows both declared search roots');
    symlink '../'.basename($selected),$selected or die $!;
    refuses('symlink-library',sub {authority_class()->from_files('sources/main.isf',$documents,['libraries'])},'file origin selected file is missing or aliased',\@controls);
    capture('precedence',{documents=>$documents,decoys=>\%decoys,proof=>$authority->proof,controls=>\@controls,
        fallback_documents=>$fallback,fallback_proof=>$after->proof,last_documents=>$last,last_proof=>$final->proof,
        cwd_documents=>$cwd_documents,cwd_proof=>$cwd->proof});
    chdir $repository or die $!;
};

subtest 'same-source selection and path aliases remain explicit' => sub {
    my ($selected_input)=grep {
        $json->decode(read_file($_))->{proof}{uses}[0]{ledger}{catalog}[0]{operation} eq 'select'
    } @inputs;
    die 'immutable select source witness missing' unless defined $selected_input;
    my $input=$json->decode(read_file($selected_input));
    my ($documents)=documents_for($input,'adjacent');
    my $root=join "\n",$documents->{'sources/main.isf'},map {$documents->{$_}} sort grep {$_ ne 'sources/main.isf'} keys %$documents;
    my $workspace=tempdir(CLEANUP=>1);
    write_documents($workspace,{'sources/main.isf'=>$root});
    my %decoys=map {'libraries/'.basename($_)=>$documents->{$_}."\n "}
        grep {$_ ne 'sources/main.isf'} keys %$documents;
    write_documents($workspace,\%decoys);
    chdir $workspace or die $!;
    my $authority=authority_class()->from_files('sources/main.isf',{'sources/main.isf'=>$root},['libraries']);
    my $expected=expected_projection($input->{ordinary},$input->{proof},sub {'sources/main.isf'});
    my $digest=sha256_hex($root);
    $expected->[1]{source_sha256}=$digest;
    $expected->[1]{documents}=[{source_label=>'sources/main.isf',source_sha256=>$digest}];
    $_->{ledger}{source_sha256}=$digest for @{$expected->[1]{actors}},@{$expected->[1]{uses}},@{$expected->[1]{atl}};
    is($json->encode([$authority->actor,$authority->proof]),$json->encode($expected),
        'same actual source forms retain complete original conditional ledgers across use and ATL rebuilding');
    is_deeply([map {$_->{source_label}} @{$authority->proof->{documents}}],['sources/main.isf'],'same-source library forms need no external source authority');
    my @controls;
    for my $identity ('/absolute.isf','../escaped.isf','sources/../main.isf','sources//main.isf','sources/./main.isf') {
        refuses('path-'.$identity,sub {authority_class()->from_files($identity,{$identity=>$root},[])},'file origin canonical relative identity required',\@controls);
    }
    symlink 'main.isf','sources/alias.isf' or die $!;
    refuses('symlink-root',sub {authority_class()->from_files('sources/alias.isf',{'sources/alias.isf'=>$root},[])},'file origin selected file is missing or aliased',\@controls);
    capture('same-source',{predecessor=>$selected_input,documents=>{'sources/main.isf'=>$root},decoys=>\%decoys,
        actor=>$authority->actor,proof=>$authority->proof,controls=>\@controls});
    chdir $repository or die $!;
};
done_testing;

sub authority_class {$ENV{FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS} || 'FSM::Test::FileDocumentOriginAuthority'}
sub clone {$json->decode($json->encode($_[0]))}
sub runtime_relative {File::Spec->abs2rel(File::Spec->rel2abs($_[0]),getcwd())}
sub documents_for {
    my ($input,$layout)=@_;
    my (%documents,%mapping);
    for my $old (sort keys %{$input->{documents}}) {
        my $name=$old eq $input->{label} ? 'sources/main.isf' : ($layout eq 'adjacent' ? 'sources/' : 'libraries/').basename($old);
        $name =~ s{common\.choice\.isf}{common/choice.isf} if $layout eq 'dotted';
        $mapping{$old}=$name;$documents{$name}=$input->{documents}{$old};
    }
    return (\%documents,\%mapping);
}
# Independent complete predecessor projection, using only emitted source-field
# membership and an explicit immutable old-to-new document map. Rehash every
# declared actor binding after changing coordinates, preserving primitive kinds.
sub expected_projection {
    my ($actor,$proof,$identity)=@_;
    my $out=clone(defined($proof)?[$actor,$proof]:$actor);
    project_values($out,$identity);
    return $out unless defined $proof;
    my $p=$out->[1];
    @{$p->{documents}}=sort {$a->{source_label} cmp $b->{source_label}} @{$p->{documents}};
    $_->{ledger}{actor_sha256}=sha256_hex($json->encode($_->{actor})) for @{$p->{actors}};
    $_->{ledger}{actor_sha256}=sha256_hex($json->encode($_->{target})) for @{$p->{uses}};
    $_->{ledger}{actor_sha256}=sha256_hex($json->encode($_->{resolution}{actor})) for @{$p->{atl}};
    $p->{actor_sha256}=sha256_hex($json->encode($out->[0]));
    return $out;
}
sub project_values {
    my ($v,$identity)=@_;
    if (ref($v) eq 'HASH') {
        for my $key (keys %$v) {
            if ($key eq 'source_label' || $key eq 'library_source') {$v->{$key}=$identity->($v->{$key})}
            else {project_values($v->{$key},$identity)}
        }
    } elsif (ref($v) eq 'ARRAY') {project_values($_,$identity) for @$v}
}
sub write_documents {
    my ($workspace,$documents)=@_;
    for my $name (keys %$documents) {make_path(dirname("$workspace/$name"));write_file("$workspace/$name",$documents->{$name})}
}
sub refuses {
    my ($name,$action,$expected,$controls)=@_;
    my $accepted=eval {$action->();1};my $diagnostic=$@;
    ok(!$accepted,"actual $name refuses");
    ok(diagnostic_matches($diagnostic,$expected),'precise actual file authority refusal');
    push @$controls,{name=>$name,accepted=>$accepted?1:0,diagnostic=>diagnostic_line($diagnostic)};
}
sub diagnostic_line {(split /\n/, $_[0] // '')[0] // ''}
sub diagnostic_matches {
    my ($error, $expected) = @_;
    return ($error // '') =~ /\Q$expected\E/ ? 1 : 0
        if $ENV{FSMGEN_FILE_DIAGNOSTIC_FULL_STACK};
    return diagnostic_cause_matches($error, $expected);
}
sub file_refusal_with_echo {
    my ($expected)=@_;
    eval {FSM::Test::FileDocumentOriginAuthority->from_files('missing.isf',{},[])};
    return $@;
}
sub read_file {open my $f,'<:raw',$_[0] or die $!;local $/;my $s=<$f>;close $f or die $!;return $s}
sub write_file {open my $f,'>:raw',$_[0] or die $!;print {$f} $_[1] or die $!;close $f or die $!}
sub capture {return unless defined $capture;write_file("$capture/$_[0].json",$json->encode($_[1])."\n")}
