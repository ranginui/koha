#!/usr/bin/perl

# Copyright 2008 Liblime
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
use utf8;

BEGIN {

    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}

use Getopt::Long;
use Pod::Usage;
use Text::CSV_XS;
use Locale::Currency::Format 1.28;
use Encode;

use C4::Context;
use C4::Dates qw/format_date/;
use C4::Debug;
use C4::Letters;
use C4::Overdues qw(GetFine);

=head1 NAME

overdue_notices.pl - prepare messages to be sent to patrons for overdue items

=head1 SYNOPSIS

overdue_notices.pl [ -n ] [ -library <branchcode> ] [ -library <branchcode>...] [ -max <number of days> ] [ -csv [ <filename> ] ] [ -itemscontent <field list> ]

 Options:
   -help                          brief help message
   -man                           full documentation
   -n                             No email will be sent
   -max          <days>           maximum days overdue to deal with
   -library      <branchname>     only deal with overdues from this library (repeatable : several libraries can be given)
   -csv          <filename>       populate CSV file
   -html         <filename>       Output html to file
   -itemscontent <list of fields> item information in templates
   -borcat       <categorycode>   category code that must be included
   -borcatout    <categorycode>   category code that must be excluded

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-v>

Verbose. Without this flag set, only fatal errors are reported.

=item B<-n>

Do not send any email. Overdue notices that would have been sent to
the patrons or to the admin are printed to standard out. CSV data (if
the -csv flag is set) is written to standard out or to any csv
filename given.

=item B<-max>

Items older than max days are assumed to be handled somewhere else,
probably the F<longoverdues.pl> script. They are therefore ignored by
this program. No notices are sent for them, and they are not added to
any CSV files. Defaults to 90 to match F<longoverdues.pl>.

=item B<-library>

select overdues for one specific library. Use the value in the
branches.branchcode table. This option can be repeated in order 
to select overdues for a group of libraries.

=item B<-csv>

Produces CSV data. if -n (no mail) flag is set, then this CSV data is
sent to standard out or to a filename if provided. Otherwise, only
overdues that could not be emailed are sent in CSV format to the admin.

=item B<-itemscontent>

comma separated list of fields that get substituted into templates in
places of the E<lt>E<lt>items.contentE<gt>E<gt> placeholder. This
defaults to issuedate,title,barcode,author

Other possible values come from fields in the biblios, items, and
issues tables.

=item B<-borcat>

Repetable field, that permit to select only few of patrons categories.

=item B<-borcatout>

Repetable field, permis to exclude some patrons categories.

=item B<-t> | B<--triggered>

This option causes a notice to be generated if and only if 
an item is overdue by the number of days defined in a notice trigger.

By default, a notice is sent each time the script runs, which is suitable for 
less frequent run cron script, but requires syncing notice triggers with 
the  cron schedule to ensure proper behavior.
Add the --triggered option for daily cron, at the risk of no notice 
being generated if the cron fails to run on time.

=item B<-list-all>

Default items.content lists only those items that fall in the 
range of the currently processing notice.
Choose list-all to include all overdue items in the list (limited by B<-max> setting).

=back

=head1 DESCRIPTION

This script is designed to alert patrons and administrators of overdue
items.

=head2 Configuration

This script pays attention to the overdue notice configuration
performed in the "Overdue notice/status triggers" section of the
"Tools" area of the staff interface to Koha. There, you can choose
which letter templates are sent out after a configurable number of
days to patrons of each library. More information about the use of this
section of Koha is available in the Koha manual.

The templates used to craft the emails are defined in the "Tools:
Notices" section of the staff interface to Koha.

=head2 Outgoing emails

Typically, messages are prepared for each patron with overdue
items. Messages for whom there is no email address on file are
collected and sent as attachments in a single email to each library
administrator, or if that is not set, then to the email address in the
C<KohaAdminEmailAddress> system preference.

These emails are staged in the outgoing message queue, as are messages
produced by other features of Koha. This message queue must be
processed regularly by the
F<misc/cronjobs/process_message_queue.pl> program.

In the event that the C<-n> flag is passed to this program, no emails
are sent. Instead, messages are sent on standard output from this
program. They may be redirected to a file if desired.

=head2 Templates

Templates can contain variables enclosed in double angle brackets like
E<lt>E<lt>thisE<gt>E<gt>. Those variables will be replaced with values
specific to the overdue items or relevant patron. Available variables
are:

=over

=item E<lt>E<lt>bibE<gt>E<gt>

the name of the library

=item E<lt>E<lt>items.contentE<gt>E<gt>

one line for each item, each line containing a tab separated list of
title, author, barcode, issuedate

=item E<lt>E<lt>borrowers.*E<gt>E<gt>

any field from the borrowers table

=item E<lt>E<lt>branches.*E<gt>E<gt>

any field from the branches table

=back

=head2 CSV output

The C<-csv> command line option lets you specify a file to which
overdues data should be output in CSV format.

With the C<-n> flag set, data about all overdues is written to the
file. Without that flag, only information about overdues that were
unable to be sent directly to the patrons will be written. In other
words, this CSV file replaces the data that is typically sent to the
administrator email address.

=head1 USAGE EXAMPLES

C<overdue_notices.pl> - In this most basic usage, with no command line
arguments, all libraries are procesed individually, and notices are
prepared for all patrons with overdue items for whom we have email
addresses. Messages for those patrons for whom we have no email
address are sent in a single attachment to the library administrator's
email address, or to the address in the KohaAdminEmailAddress system
preference.

C<overdue_notices.pl -n -csv /tmp/overdues.csv> - sends no email and
populates F</tmp/overdues.csv> with information about all overdue
items.

C<overdue_notices.pl -library MAIN max 14> - prepare notices of
overdues in the last 2 weeks for the MAIN library.

=head1 SEE ALSO

The F<misc/cronjobs/advance_notices.pl> program allows you to send
messages to patrons in advance of thier items becoming due, or to
alert them of items that have just become due.

=cut

# These variables are set by command line options.
# They are initially set to default values.
my $dbh = C4::Context->dbh();
my $help    = 0;
my $man     = 0;
my $verbose = 0;
my $nomail  = 0;
my $MAX     = 90;
my @branchcodes; # Branch(es) passed as parameter
my $csvfilename;
my $htmlfilename;
my $triggered = 0;
my $listall = 0;
my $itemscontent = join( ',', qw( issuedate title barcode author biblionumber ) );
my @myborcat;
my @myborcatout;

GetOptions(
    'help|?'         => \$help,
    'man'            => \$man,
    'v'              => \$verbose,
    'n'              => \$nomail,
    'max=s'          => \$MAX,
    'library=s'      => \@branchcodes,
    'csv:s'          => \$csvfilename,    # this optional argument gets '' if not supplied.
    'html:s'          => \$htmlfilename,    # this optional argument gets '' if not supplied.
    'itemscontent=s' => \$itemscontent,
    'list-all'      => \$listall,
    't|triggered'             => \$triggered,
    'borcat=s'      => \@myborcat,
    'borcatout=s'   => \@myborcatout,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

if ( defined $csvfilename && $csvfilename =~ /^-/ ) {
    warn qq(using "$csvfilename" as filename, that seems odd);
}

my @overduebranches    = C4::Overdues::GetBranchcodesWithOverdueRules();	# Branches with overdue rules
my @branches;									# Branches passed as parameter with overdue rules
my $branchcount = scalar(@overduebranches);

my $overduebranch_word = scalar @overduebranches > 1 ? 'branches' : 'branch';
my $branchcodes_word = scalar @branchcodes > 1 ? 'branches' : 'branch';

my $PrintNoticesMaxLines = C4::Context->preference('PrintNoticesMaxLines');

if ($branchcount) {
    $verbose and warn "Found $branchcount $overduebranch_word with first message enabled: " . join( ', ', map { "'$_'" } @overduebranches ), "\n";
} else {
    die 'No branches with active overduerules';
}

if (@branchcodes) {
    $verbose and warn "$branchcodes_word @branchcodes passed on parameter\n";
    
    # Getting libraries which have overdue rules
    my %seen = map { $_ => 1 } @branchcodes;
    @branches = grep { $seen{$_} } @overduebranches;
    
    
    if (@overduebranches) {

    	my $branch_word = scalar @branches > 1 ? 'branches' : 'branch';
	$verbose and warn "$branch_word @branches have overdue rules\n";

    } else {
    
        $verbose and warn "No active overduerules for $branchcodes_word  '@branchcodes'\n";
        ( scalar grep { '' eq $_ } @branches )
          or die "No active overduerules for DEFAULT either!";
        $verbose and warn "Falling back on default rules for @branchcodes\n";
        @branches = ('');
    }
}

# these are the fields that will be substituted into <<item.content>>
my @item_content_fields = split( /,/, $itemscontent );

binmode( STDOUT, ":utf8" );


our $csv;       # the Text::CSV_XS object
our $csv_fh;    # the filehandle to the CSV file.
if ( defined $csvfilename ) {
    my $sep_char = C4::Context->preference('delimiter') || ',';
    $csv = Text::CSV_XS->new( { binary => 1 , sep_char => $sep_char } );
    if ( $csvfilename eq '' ) {
        $csv_fh = *STDOUT;
    } else {
        open $csv_fh, ">", $csvfilename or die "unable to open $csvfilename: $!";
    }
    if ( $csv->combine(qw(name surname address1 address2 zipcode city country email itemcount itemsinfo)) ) {
        print $csv_fh $csv->string, "\n";
    } else {
        $verbose and warn 'combine failed on argument: ' . $csv->error_input;
    }
}

@branches = @overduebranches unless @branches;
our $html_fh;
if ( defined $htmlfilename ) {
  if ( $htmlfilename eq '' ) {
    $html_fh = *STDOUT;
  } else {
    my $today = C4::Dates->new();
    open $html_fh, ">",File::Spec->catdir ($htmlfilename,"notices-".$today->output('iso').".html");
  }
  
  print $html_fh "<html>\n";
  print $html_fh "<head>\n";
  print $html_fh "<style type='text/css'>\n";
  print $html_fh "pre {page-break-after: always;}\n";
  print $html_fh "pre {white-space: pre-wrap;}\n";
  print $html_fh "pre {white-space: -moz-pre-wrap;}\n";
  print $html_fh "pre {white-space: -o-pre-wrap;}\n";
  print $html_fh "pre {word-wrap: break-work;}\n";
  print $html_fh "</style>\n";
  print $html_fh "</head>\n";
  print $html_fh "<body>\n";
}

foreach my $branchcode (@branches) {

    my $branch_details = C4::Branch::GetBranchDetail($branchcode);
    my $admin_email_address = $branch_details->{'branchemail'} || C4::Context->preference('KohaAdminEmailAddress');
    my @output_chunks;    # may be sent to mail or stdout or csv file.

    $verbose and warn sprintf "branchcode : '%s' using %s\n", $branchcode, $admin_email_address;

    my $sth2 = $dbh->prepare( <<'END_SQL' );
SELECT biblio.*, items.*, issues.*, TO_DAYS(NOW())-TO_DAYS(date_due) AS days_overdue
  FROM issues,items,biblio
  WHERE items.itemnumber=issues.itemnumber
    AND biblio.biblionumber   = items.biblionumber
    AND issues.borrowernumber = ?
    AND TO_DAYS(NOW())-TO_DAYS(date_due) BETWEEN ? and ?
END_SQL

    my $query = "SELECT * FROM overduerules WHERE delay1 IS NOT NULL AND branchcode = ? ";
    $query .= " AND categorycode IN (".join( ',' , ('?') x @myborcat ).") " if (@myborcat);
    $query .= " AND categorycode NOT IN (".join( ',' , ('?') x @myborcatout ).") " if (@myborcatout);
    
    my $rqoverduerules =  $dbh->prepare($query);
    $rqoverduerules->execute($branchcode, @myborcat, @myborcatout);
    
    # We get default rules is there is no rule for this branch
    if($rqoverduerules->rows == 0){
        $query = "SELECT * FROM overduerules WHERE delay1 IS NOT NULL AND branchcode = '' ";
        $query .= " AND categorycode IN (".join( ',' , ('?') x @myborcat ).") " if (@myborcat);
        $query .= " AND categorycode NOT IN (".join( ',' , ('?') x @myborcatout ).") " if (@myborcatout);
        
        $rqoverduerules = $dbh->prepare($query);
        $rqoverduerules->execute(@myborcat, @myborcatout);
    }

    # my $outfile = 'overdues_' . ( $mybranch || $branchcode || 'default' );
    while ( my $overdue_rules = $rqoverduerules->fetchrow_hashref ) {
      PERIOD: foreach my $i ( 1 .. 3 ) {

            $verbose and warn "branch '$branchcode', pass $i\n";
            my $mindays = $overdue_rules->{"delay$i"};    # the notice will be sent after mindays days (grace period)
            my $maxdays = (
                  $overdue_rules->{ "delay" . ( $i + 1 ) }
                ? $overdue_rules->{ "delay" . ( $i + 1 ) }
                : ($MAX)
            );                                            # issues being more than maxdays late are managed somewhere else. (borrower probably suspended)

            if ( !$overdue_rules->{"letter$i"} ) {
                $verbose and warn "No letter$i code for branch '$branchcode'";
                next PERIOD;
            }

            # $letter->{'content'} is the text of the mail that is sent.
            # this text contains fields that are replaced by their value. Those fields must be written between brackets
            # The following fields are available :
	    # itemcount is interpreted here as the number of items in the overdue range defined by the current notice or all overdues < max if(-list-all).
            # <date> <itemcount> <firstname> <lastname> <address1> <address2> <address3> <city> <postcode>

            my $borrower_sql = <<'END_SQL';
SELECT COUNT(*), issues.borrowernumber, firstname, surname, address, address2, city, zipcode, country, email, MIN(date_due) as longest_issue
FROM   issues,borrowers,categories
WHERE  issues.borrowernumber=borrowers.borrowernumber
AND    borrowers.categorycode=categories.categorycode
END_SQL
            my @borrower_parameters;
            if ($branchcode) {
                $borrower_sql .= ' AND issues.branchcode=? ';
                push @borrower_parameters, $branchcode;
            }
            if ( $overdue_rules->{categorycode} ) {
                $borrower_sql .= ' AND borrowers.categorycode=? ';
                push @borrower_parameters, $overdue_rules->{categorycode};
            }
            $borrower_sql .= '  AND categories.overduenoticerequired=1
                                GROUP BY issues.borrowernumber ';
            if($triggered) {
                $borrower_sql .= ' HAVING TO_DAYS(NOW())-TO_DAYS(longest_issue) = ?';
                push @borrower_parameters, $mindays;
            } else {
                $borrower_sql .= ' HAVING TO_DAYS(NOW())-TO_DAYS(longest_issue) BETWEEN ? and ? ' ;
                push @borrower_parameters, $mindays, $maxdays;
            }

            # $sth gets borrower info iff at least one overdue item has triggered the overdue action.
	        my $sth = $dbh->prepare($borrower_sql);
            $sth->execute(@borrower_parameters);
            $verbose and warn $borrower_sql . "\n $branchcode | " . $overdue_rules->{'categorycode'} . "\n ($mindays, $maxdays)\nreturns " . $sth->rows . " rows";

            while ( my ($itemcount, $borrowernumber, $firstname, $lastname,
                    $address1, $address2, $city, $postcode, $country, $email,
                    $longest_issue ) = $sth->fetchrow )
            {
                $verbose and warn "borrower $firstname, $lastname ($borrowernumber) has $itemcount items triggering level $i.";
    
                my $letter = C4::Letters::getletter( 'circulation', $overdue_rules->{"letter$i"} );

                unless ($letter) {
                    $verbose and warn "Message '$overdue_rules->{letter$i}' content not found";
    
                    # might as well skip while PERIOD, no other borrowers are going to work.
                    # FIXME : Does this mean a letter must be defined in order to trigger a debar ?
                    next PERIOD;
                }
    
                if ( $overdue_rules->{"debarred$i"} ) {
    
                    #action taken is debarring
                    C4::Members::DebarMember($borrowernumber);
                    $verbose and warn "debarring $borrowernumber $firstname $lastname\n";
                }
                my @params = ($listall ? ( $borrowernumber , 1 , $MAX ) : ( $borrowernumber, $mindays, $maxdays ));
                $sth2->execute(@params);
                my $itemcount = 0;
                my $titles = "";
                my @items = ();
                
                my $i = 0;
                my $exceededPrintNoticesMaxLines = 0;
                while ( my $item_info = $sth2->fetchrow_hashref() ) {
                    if ( ( !$email || $nomail ) && $PrintNoticesMaxLines && $i >= $PrintNoticesMaxLines ) {
                      $exceededPrintNoticesMaxLines = 1;
                      last;
                    }
                    $i++;
                    my @item_info = map { $_ =~ /^date|date$/ ? format_date( $item_info->{$_} ) : $item_info->{$_} || '' } @item_content_fields;
                    $titles .= join("\t", @item_info) . "\n";
                    $itemcount++;
                    push (@items, $item_info->{'biblionumber'});
                }
                $sth2->finish;
                $letter = parse_letter(
                    {   letter          => $letter,
                        borrowernumber  => $borrowernumber,
                        branchcode      => $branchcode,
                        biblionumber    => \@items,
                        substitute      => {    # this appears to be a hack to overcome incomplete features in this code.
                                            bib             => $branch_details->{'branchname'}, # maybe 'bib' is a typo for 'lib<rary>'?
                                            'items.content' => $titles
                                           }
                    }
                );
                
                if ( $exceededPrintNoticesMaxLines ) {
                  $letter->{'content'} .= "List too long for form; please check your account online for a complete list of your overdue items.";
                }

                my @misses = grep { /./ } map { /^([^>]*)[>]+/; ( $1 || '' ); } split /\</, $letter->{'content'};
                if (@misses) {
                    $verbose and warn "The following terms were not matched and replaced: \n\t" . join "\n\t", @misses;
                }
                $letter->{'content'} =~ s/\<[^<>]*?\>//g;    # Now that we've warned about them, remove them.
                $letter->{'content'} =~ s/\<[^<>]*?\>//g;    # 2nd pass for the double nesting.
    
                if ($nomail) {
    
                    push @output_chunks,
                      prepare_letter_for_printing(
                        {   letter         => $letter,
                            borrowernumber => $borrowernumber,
                            firstname      => $firstname,
                            lastname       => $lastname,
                            address1       => $address1,
                            address2       => $address2,
                            city           => $city,
                            postcode       => $postcode,
                            email          => $email,
                            itemcount      => $itemcount,
                            titles         => $titles,
                            outputformat   => defined $csvfilename ? 'csv' : defined $htmlfilename ? 'html' : '',
                        }
                      );
                } else {
                    if ($email) {
                        C4::Letters::EnqueueLetter(
                            {   letter                 => $letter,
                                borrowernumber         => $borrowernumber,
                                message_transport_type => 'email',
                                from_address           => $admin_email_address,
                            }
                        );
                    } else {
    
                        # If we don't have an email address for this patron, send it to the admin to deal with.
                        push @output_chunks,
                          prepare_letter_for_printing(
                            {   letter         => $letter,
                                borrowernumber => $borrowernumber,
                                firstname      => $firstname,
                                lastname       => $lastname,
                                address1       => $address1,
                                address2       => $address2,
                                city           => $city,
                                postcode       => $postcode,
                                email          => $email,
                                itemcount      => $itemcount,
                                titles         => $titles,
                                outputformat   => defined $csvfilename ? 'csv' : defined $htmlfilename ? 'html' : '',
                            }
                          );
                    }
                }
            }
            $sth->finish;
        }
    }

    if (@output_chunks) {
        if ($nomail) {
            if ( defined $csvfilename ) {
                print $csv_fh @output_chunks;
            } elsif ( defined $htmlfilename ) {
                print $html_fh @output_chunks;
            } else {
                local $, = "\f";    # pagebreak
                print @output_chunks;
            }
        } 
        elsif ( defined $htmlfilename ) {
            print $html_fh @output_chunks;        
        }
        else {
            my $attachment = {
                filename => defined $csvfilename ? 'attachment.csv' : 'attachment.txt',
                type => 'text/plain',
                content => join( "\n", @output_chunks )
            };

            my $letter = {
                title   => 'Overdue Notices',
                content => 'These messages were not sent directly to the patrons.',
            };
            C4::Letters::EnqueueLetter(
                {   letter                 => $letter,
                    borrowernumber         => undef,
                    message_transport_type => 'email',
                    attachments            => [$attachment],
                    to_address             => $admin_email_address,
                }
            );
        }
    }

}
if ($csvfilename) {
    # note that we're not testing on $csv_fh to prevent closing
    # STDOUT.
    close $csv_fh;
}

if ( defined $htmlfilename ) {
  print $html_fh "</body>\n";
  print $html_fh "</html>\n";
  close $html_fh;
}

=head1 INTERNAL METHODS

These methods are internal to the operation of overdue_notices.pl.

=head2 parse_letter

parses the letter template, replacing the placeholders with data
specific to this patron, biblio, or item

named parameters:
  letter - required hashref
  borrowernumber - required integer
  substitute - optional hashref of other key/value pairs that should
    be substituted in the letter content

returns the C<letter> hashref, with the content updated to reflect the
substituted keys and values.


=cut

sub parse_letter { # FIXME: this code should probably be moved to C4::Letters:parseletter
    my $params = shift;
    foreach my $required (qw( letter borrowernumber )) {
        return unless exists $params->{$required};
    }


    if ( $params->{'substitute'} ) {
        while ( my ( $key, $replacedby ) = each %{ $params->{'substitute'} } ) {
            my $replacefield = "<<$key>>";
            $params->{'letter'}->{title}   =~ s/$replacefield/$replacedby/g;
            $params->{'letter'}->{content} =~ s/$replacefield/$replacedby/g;
        }
    }

    $params->{'letter'} = C4::Letters::parseletter( $params->{'letter'}, 'borrowers', $params->{'borrowernumber'} );

    if ( $params->{'branchcode'} ) {
        $params->{'letter'} = C4::Letters::parseletter( $params->{'letter'}, 'branches', $params->{'branchcode'} );
    }

    if ( $params->{'biblionumber'} ) {
        my $item_format = '';
        PROCESS_ITEMS:
        while (scalar(@{$params->{'biblionumber'}}) > 0) {
            my $item = shift @{$params->{'biblionumber'}};
            my $fine = GetFine($item, $params->{'borrowernumber'});
            if (!$item_format) {
                $params->{'letter'}->{'content'} =~ m/(<item>.*<\/item>)/;
                $item_format = $1;
            }
            if ($params->{'letter'}->{'content'} =~ m/<fine>(.*)<\/fine>/) { # process any fine tags...
                no strict; # currency_format behaves badly if we quote the bareword for some reason...
                my $formatted_fine = currency_format("$1", "$fine", FMT_SYMBOL);
                use strict;
                $formatted_fine = Encode::encode("utf8", $formatted_fine);
                $params->{'letter'}->{'content'} =~ s/<fine>.*<\/fine>/$formatted_fine/;
            }
            $params->{'letter'} = C4::Letters::parseletter( $params->{'letter'}, 'biblio',      $item );
            $params->{'letter'} = C4::Letters::parseletter( $params->{'letter'}, 'biblioitems', $item );
            $params->{'letter'} = C4::Letters::parseletter( $params->{'letter'}, 'items', $item );
            $params->{'letter'}->{'content'} =~ s/(<item>.*<\/item>)/$1\n$item_format/ if scalar(@{$params->{'biblionumber'}} > 0);

        }
    }
    $params->{'letter'}->{'content'} =~ s/<\/{0,1}?item>//g; # strip all remaining item tags...
    return $params->{'letter'};
}

=head2 prepare_letter_for_printing

returns a string of text appropriate for printing in the event that an
overdue notice will not be sent to the patron's email
address. Depending on the desired output format, this may be a CSV
string, or a human-readable representation of the notice.

required parameters:
  letter
  borrowernumber

optional parameters:
  outputformat

=cut

sub prepare_letter_for_printing {
    my $params = shift;

    return unless ref $params eq 'HASH';

    foreach my $required_parameter (qw( letter borrowernumber )) {
        return unless defined $params->{$required_parameter};
    }

    my $return;
    if ( exists $params->{'outputformat'} && $params->{'outputformat'} eq 'csv' ) {
        if ($csv->combine(
                $params->{'firstname'}, $params->{'lastname'}, $params->{'address1'},  $params->{'address2'}, $params->{'postcode'},
                $params->{'city'},      $params->{'email'},    $params->{'itemcount'}, $params->{'titles'}
            )
          ) {
            return $csv->string, "\n";
        } else {
            $verbose and warn 'combine failed on argument: ' . $csv->error_input;
        }
    } elsif ( exists $params->{'outputformat'} && $params->{'outputformat'} eq 'html' ) {
      $return = "<pre>\n";
      $return .= "$params->{'letter'}->{'content'}\n";
      $return .= "\n</pre>\n";
    } else {
        $return .= "$params->{'letter'}->{'content'}\n";

        # $return .= Data::Dumper->Dump( [ $params->{'borrowernumber'}, $params->{'letter'} ], [qw( borrowernumber letter )] );
    }
    return $return;
}

