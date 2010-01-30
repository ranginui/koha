#!/usr/bin/perl
# script to update all translations
use strict;
use warnings;
use lib '/home/jmf/kohaclone';
use C4::Languages;
# Go through the theme/module combinations we need to update.
my $dir = "po";
my $po;
opendir (DIR,$dir);
while (defined($po = readdir(DIR))) {
    next if $po =~ /(^\.\.?$|img|fam)/;
    $po =~  /^(.*)-i-(staff|opac).*/;
    print "lang: $1 interface:$2\n";
    my ($lang,$interface) = ($1,$2);
    $interface =~ s/staff/intranet/;
    system("mkdir ../../koha-tmpl/$interface-tmpl/prog/$lang");
    system("./tmpl_process3.pl install -i ../../koha-tmpl/$interface-tmpl/prog/en/ -o ../../koha-tmpl/$interface-tmpl/prog/$lang -s po/$po -r");
}
closedir DIR;

=head
my($theme, $module) = @$spec;
   my $pid = fork;
   die "fork: $!\n" unless defined $pid;
   if (!$pid) {

      # If current directory is translator/po instead of translator,
      # then go back to the parent
      if ($chdir_needed_p) {
	 chdir('..') || die "..: cd: $!\n";
      }

      # Now call tmpl_process3.pl to do the real work
      #
      # Traditionally, the pot file should be named PACKAGE.pot
      # (for Koha probably something like koha_intranet_css.pot),
      # but this is not Koha's convention.
      #
      my $target = "po/${theme}_${module}" . ($pot_p? ".pot": "_$lang.po");
      rename($target, "$target~") if $pot_p;
      exec('./tmpl_process3.pl', ($pot_p? 'create': 'update'),
	    '-i', "../../koha-tmpl/$module-tmpl/$theme/en/",
	    '-s', $target, '-r');

      die "tmpl_process3.pl: exec: $!\n";
   }
   wait;
}
=cut
