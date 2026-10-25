#===================================================================
# Copyright (c) 2005-2008 Richard DJE. All rights reserved.
#
# This Perl module is free software, you may redistribute it and/or 
# modify it under the same terms as Perl itself.
#===================================================================
package Lispish;

use 5.010;

use Cwd ();
use File::Basename ();
use File::Spec ();
use LinkedSpec ();

# Resolve while a relative @INC entry still refers to the loaded module.
# Grammar ownership follows this installation, never the caller's cwd.
my $module_root = File::Basename::dirname(
    File::Basename::dirname(Cwd::abs_path(__FILE__)));

sub _parser {
    my $resource = 'specs/Lispish.spec';
    my $path = Cwd::abs_path(File::Spec->catfile($module_root, 'specs', 'Lispish.spec'));
    die "$resource: missing canonical grammar\n" unless defined($path) && -f $path;
    my $relative = File::Spec->abs2rel($path, $module_root);
    die "$resource: canonical grammar is outside its installation\n"
        if File::Spec->file_name_is_absolute($relative)
        || $relative eq File::Spec->updir()
        || $relative =~ m{\A\.\.(?:/|\\)}
        || (stat($path))[0] != (stat($module_root))[0];
    open my $stream, '<:raw', $path or die "$resource: cannot open grammar: $!\n";
    my $grammar = do { local $/; <$stream> };
    close $stream or die "$resource: cannot close grammar: $!\n";
    my $parser = LinkedSpec::Get(\$grammar);
    die "$resource: compilation produced no parser\n" unless ref($parser) eq 'CODE';
    return $parser;
}

sub single  {state $code = _parser(); $code->($_[0])}
sub multi   {my $hread = shift;

 unless (ref $hread) {
  -s $hread || die "(Lispish::multi) -E- File '$hread' is either empty or does not exit,";

  my $hreadata = do {open (my $f, $hread); local $/; <$f>};
  $hread       = \$hreadata;
 }

 my @listo; 
 while(my $lite = single($hread)) {push @listo, $lite} 
 
 wantarray ? @listo : \@listo
}

sub recurse {my ($raw, @opt) = @_;
 my $it   = shift @opt if ref $opt[0] eq 'CODE';
 my %opt  = @opt;

 $opt{it} = $it if $it; 

 $opt{level} //= 1;

 # pre code
 $opt{pre} && $opt{pre}->($raw, $opt{level});

 my @capt;
 foreach (0 .. $#$raw) {
   if (ref ($raw->[$_]) eq 'ARRAY') {
      push @capt, recurse ($raw->[$_], level=>$opt{level}+1, map {$_=>$opt{$_}} grep !/level/o, keys %opt)
   } else {
      push @capt, $opt{it}->($raw->[$_], $raw, $_, $opt{level}) if $opt{it};
   } 
 }

 @capt = grep {defined} @capt;

 # post code
 $opt{post} ? ((!$opt{postcheck} || $opt{postcheck}->($raw, \@capt)) ? $opt{post}->($raw, \@capt, $opt{level}) : @capt) : $raw;
}

sub flatten    {recurse ($_[0], sub {$_[0]}, post=>sub {@{$_[1]}})}
sub substitute {my ($context, $raw, $subst_code) = @_; recurse ($raw, sub {$_[0] = $subst_code->($context, @_)})}
sub ascii  {
# recurse ($_[0], sub {print "$_[0] "}, pre=>  sub {return if ref $_[0][0]; print "\n", ' ' x $_[1], '('}, 
#                                      post=> sub {return if ref $_[0][0]; say '', (ref $_[0][-1] ? ' ' x $_[2] : ''), ')'}) 
 recurse ($_[0], pre  => sub {print "\n", ' ' x $_[1], '('}, 
                 it   => sub {print "$_[0] "}, 
                 post => sub {say '', (ref $_[0][-1] ? ' ' x $_[2] : ''), ')'});
 # return the intial Array-Tree, aka, ATree (vs HTree)
 $_[0]
}

sub grep {my ($raw, $node_re, @opt) = @_;
 my $itcode = shift @opt if ref $opt[0] eq 'CODE';
 my %opt    = @opt;

 my @list;
 recurse ($raw, sub {my ($v, $a, $i) = @_;
  return unless $i == 0 and not(ref $v) and $v =~ m/$node_re/;

  push @list, $a
 });


 my @mo = $itcode ? map {$itcode->($_)} @list : @list;

 wantarray ? @mo : \@$mo 
}

# $node_info_list == [node0_re=>node0_foreach_code, 
#                     node1_re=>node1_foreach_code,
#                     ...
#                     nodeN_re=>nodeN_foreach_code
#                    ]
sub bottom_up {my ($cr, $at, %pattern_action) = @_;
   recurse ($at, 
       #pre=> sub {say "PRE (@{$_[0]})"},
            postcheck => sub {!ref($_[0][0]) && $_[0][0] && $_[0][0] =~ qr/^\?\&?\w+(?::(\w+)?)?$/o},
            post      => sub {my ($ar, $capt, $l) = @_;
                          $ar->[0] =~ /^(?<nodetype>\S+)/o;

                          #say "#################### POST <$+{nodetype}>";
                          ($pattern_action{$+{nodetype}} // sub {})->(@_)
   })
}

1;
