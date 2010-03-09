#!/usr/bin/perl

# Copyright 2007 Liblime Ltd
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

# Script to take some borrowers data in a known format and load it into Koha
#
# File format
#
# cardnumber,surname,firstname,title,othernames,initials,streetnumber,streettype,
# address line , address line 2, city, zipcode, contry, email, phone, mobile, fax, work email, work phone,
# alternate streetnumber, alternate streettype, alternate address line 1, alternate city,
# alternate zipcode, alternate country, alternate email, alternate phone, date of birth, branchcode,
# categorycode, enrollment date, expiry date, noaddress, lost, debarred, contact surname,
# contact firstname, contact title, borrower notes, contact relationship, ethnicity, ethnicity notes
# gender, username, opac note, contact note, password, sort one, sort two
#
# any fields except cardnumber can be blank but the number of fields must match
# dates should be in the format you have set up Koha to expect
# branchcode and categorycode need to be valid

use strict;
use warnings;

use C4::Auth;
use C4::Output;
use C4::Dates qw(format_date_in_iso);
use C4::Context;
use C4::Branch qw(GetBranchName);
use C4::Members;
use C4::Members::Attributes qw(:all);
use C4::Members::AttributeTypes;
use C4::Members::Messaging;
use Date::Calc qw(Today_and_Now);
use Getopt::Long;
use File::Temp;
use Text::CSV;
# Text::CSV::Unicode, even in binary mode, fails to parse lines with these diacriticals:
# ė
# č

use CGI;
# use encoding 'utf8';    # don't do this

my $input = CGI->new();

# Checks if the script is called from commandline
my $commandline = 0;
my $uploadborrowers;
my $matchpoint;
my $overwrite_cardnumber;
my $ext_preserve;
my $file;
my $cl_defaults;
my $help;
if (scalar @ARGV > 0) { 
    # Getting parameters
    GetOptions ('matchpoint=s' => \$matchpoint, 'overwrite' => \$overwrite_cardnumber, 'preserve_attributes' => \$ext_preserve, 'file=s' => \$file, 'help|?' => \$help);
    $commandline = 1;

    if ($help) {
	print "\nimport_borrowers.pl [--matchpoint=matchpoint] [--overwrite] [--preserve_attributes] --file=csvtoimport.csv\n\n";
	print " * matchpoint is either 'cardnumber' or like 'patron_attribute_' + patron attribute code (example: patron_attribute_EXTERNALID)\n";
	print " * Default values can be specified in import_borrowers.yaml (keys must be column names from the borrowers table)\n\n";
	exit;
    } 

    # Default parameters values : 
    $matchpoint ||= "cardnumber";
    $overwrite_cardnumber ||= 0;
    $ext_preserve ||= 0;

    # Default values
    $cl_defaults = YAML::LoadFile('import_borrowers.yaml') if (-e 'import_borrowers.yaml');

    open($uploadborrowers, '<', $file) or die("Unable to open $file");
} else {
    $uploadborrowers      = $input->param('uploadborrowers');
    $matchpoint           = $input->param('matchpoint');
    $overwrite_cardnumber = $input->param('overwrite_cardnumber');
    $ext_preserve         = $input->param('ext_preserve') || 0;
}

my (@errors, @feedback);
my $extended = C4::Context->preference('ExtendedPatronAttributes');
my $set_messaging_prefs = C4::Context->preference('EnhancedMessagingPreferences');
my @columnkeys = C4::Members->columns;
if ($extended) {
    push @columnkeys, 'patron_attributes';
}
my $columnkeystpl = [ map { {'key' => $_} }  grep {$_ ne 'borrowernumber' && $_ ne 'cardnumber'} @columnkeys ];  # ref. to array of hashrefs.

our $csv  = Text::CSV->new({binary => 1});  # binary needed for non-ASCII Unicode
# push @feedback, {feedback=>1, name=>'backend', value=>$csv->backend, backend=>$csv->backend};

my ( $template, $loggedinuser, $cookie ) = get_template_and_user({
	    template_name   => "tools/import_borrowers.tmpl",
	    query           => $input,
	    type            => "intranet",
	    authnotrequired => $commandline,
	    flagsrequired   => { tools => 'import_patrons' },
	    debug           => 1,
    });

if (!$commandline) {
    $template->param(columnkeys => $columnkeystpl);
    $template->param( SCRIPT_NAME => $ENV{'SCRIPT_NAME'} );
    ($extended) and $template->param(ExtendedPatronAttributes => 1);

    if ($input->param('sample')) {
	print $input->header(
	    -type       => 'application/vnd.sun.xml.calc', # 'application/vnd.ms-excel' ?
	    -attachment => 'patron_import.csv',
	);
	$csv->combine(@columnkeys);
	print $csv->string, "\n";
	exit 1;
    }

    if ($input->param('report')) {
	open (FH, $input->param('errors_filename'));
	print $input->header(
	    -type => 'text/plain',
	    -attachment => 'import_borrowers_report.txt'
	);
	print <FH>;
	close FH;
	#TODO : We surely want to check that is it really a temp file that we are unlinking
	unlink $input->param('errors_filename');
	exit 1;
    }
}

if ($matchpoint) {
    $matchpoint =~ s/^patron_attribute_//;
}



if ( $uploadborrowers && length($uploadborrowers) > 0 ) {
    push @feedback, {feedback=>1, name=>'filename', value=>$uploadborrowers, filename=>$uploadborrowers};
    my $handle = ($commandline == 1) ? $uploadborrowers : $input->upload('uploadborrowers');
    my $uploadinfo = $input->uploadInfo($uploadborrowers);
    foreach (keys %$uploadinfo) {
        push @feedback, {feedback=>1, name=>$_, value=>$uploadinfo->{$_}, $_=>$uploadinfo->{$_}};
    }
    my $imported    = 0;
    my $alreadyindb = 0;
    my $lastalreadyindb;
    my $overwritten = 0;
    my $invalid     = 0;
    my $lastinvalid;
    my $matchpoint_attr_type; 
    my %defaults = ($commandline) ? %$cl_defaults : $input->Vars;

    # use header line to construct key to column map
    my $borrowerline = <$handle>;
    my $status = $csv->parse($borrowerline);
    ($status) or push @errors, {badheader=>1,line=>$., lineraw=>$borrowerline};
    my @csvcolumns = $csv->fields();
    my %csvkeycol;
    my $col = 0;
    foreach my $keycol (@csvcolumns) {
    	# columnkeys don't contain whitespace, but some stupid tools add it
    	$keycol =~ s/ +//g;
        $csvkeycol{$keycol} = $col++;
    }
    #warn($borrowerline);
    if ($extended) {
        $matchpoint_attr_type = C4::Members::AttributeTypes->fetch($matchpoint);
    }

    push @feedback, {feedback=>1, name=>'headerrow', value=>join(', ', @csvcolumns)};
    my $today_iso = C4::Dates->new()->output('iso');
    my @criticals = qw(surname branchcode categorycode);    # there probably should be others
    my @bad_dates;  # I've had a few.
    my $date_re = C4::Dates->new->regexp('syspref');
    my  $iso_re = C4::Dates->new->regexp('iso');
    LINE: while ( my $borrowerline = <$handle> ) {
        my %borrower;
        my @missing_criticals;
        my $patron_attributes;
        my $status  = $csv->parse($borrowerline);
        my @columns = $csv->fields();
        if (! $status) {
            push @missing_criticals, {badparse=>1, line=>$., lineraw=>$borrowerline};
        } elsif (@columns == @columnkeys) {
            @borrower{@columnkeys} = @columns;
            # MJR: try to fill blanks gracefully by using default values
            foreach my $key (@columnkeys) {
                if ($borrower{$key} !~ /\S/) {
                    $borrower{$key} = $defaults{$key};
                }
            } 
        } else {
            # MJR: try to recover gracefully by using default values
            foreach my $key (@columnkeys) {
            	if (defined($csvkeycol{$key}) and $columns[$csvkeycol{$key}] =~ /\S/) { 
            	    $borrower{$key} = $columns[$csvkeycol{$key}];
            	} elsif ( $defaults{$key} ) {
            	    $borrower{$key} = $defaults{$key};
            	} elsif ( scalar grep {$key eq $_} @criticals ) {
            	    # a critical field is undefined
            	    push @missing_criticals, {key=>$key, line=>$., lineraw=>$borrowerline};
            	} else {
            		$borrower{$key} = '';
            	}
            }
        }
        #warn join(':',%borrower);
        if ($borrower{categorycode}) {
            push @missing_criticals, {key=>'categorycode', line=>$. , lineraw=>$borrowerline, value=>$borrower{categorycode}, category_map=>1}
                unless GetBorrowercategory($borrower{categorycode});
        } else {
            push @missing_criticals, {key=>'categorycode', line=>$. , lineraw=>$borrowerline};
        }
        if ($borrower{branchcode}) {
            push @missing_criticals, {key=>'branchcode', line=>$. , lineraw=>$borrowerline, value=>$borrower{branchcode}, branch_map=>1}
                unless GetBranchName($borrower{branchcode});
        } else {
            push @missing_criticals, {key=>'branchcode', line=>$. , lineraw=>$borrowerline};
        }
        if (@missing_criticals) {
            foreach (@missing_criticals) {
                $_->{borrowernumber} = $borrower{borrowernumber} || 'UNDEF';
                $_->{surname}        = $borrower{surname} || 'UNDEF';
            }
            $invalid++;
            push @errors, {missing_criticals=>\@missing_criticals};
            next LINE;
        }
        if ($extended) {
            my $attr_str = $borrower{patron_attributes};
            delete $borrower{patron_attributes};    # not really a field in borrowers, so we don't want to pass it to ModMember.
            $patron_attributes = extended_attributes_code_value_arrayref($attr_str); 
        }
	# Popular spreadsheet applications make it difficult to force date outputs to be zero-padded, but we require it.
        foreach (qw(dateofbirth dateenrolled dateexpiry)) {
            my $tempdate = $borrower{$_} or next;
            if ($tempdate =~ /$date_re/) {
                $borrower{$_} = format_date_in_iso($tempdate);
            } elsif ($tempdate =~ /$iso_re/) {
                $borrower{$_} = $tempdate;
            } else {
                $borrower{$_} = '';
                push @missing_criticals, {key=>$_, line=>$. , lineraw=>$borrowerline, bad_date=>1};
            }
        }
	$borrower{dateenrolled} = $today_iso unless $borrower{dateenrolled};
	$borrower{dateexpiry} = GetExpiryDate($borrower{categorycode},$borrower{dateenrolled}) unless $borrower{dateexpiry}; 
        my $borrowernumber;
        my $member;
        if ( ($matchpoint eq 'cardnumber') && ($borrower{'cardnumber'}) ) {
            $member = GetMember( 'cardnumber' => $borrower{'cardnumber'} );
            if ($member) {
                $borrowernumber = $member->{'borrowernumber'};
            }
        } elsif ($extended) {
            if (defined($matchpoint_attr_type)) {
                foreach my $attr (@$patron_attributes) {
                    if ($attr->{code} eq $matchpoint and $attr->{value} ne '') {
                        my @borrowernumbers = $matchpoint_attr_type->get_patrons($attr->{value});
                        $borrowernumber = $borrowernumbers[0] if scalar(@borrowernumbers) == 1;
                        last;
                    }
                }
            }
        }
            
        if ($borrowernumber) {
            # borrower exists
            unless ($overwrite_cardnumber) {
                $alreadyindb++;
                $template->param('lastalreadyindb'=>$borrower{'surname'}.' / '.$borrowernumber) if (!$commandline);
                $lastalreadyindb = $borrower{'surname'}.' / '.$borrowernumber;
                next LINE;
            }
            $borrower{'borrowernumber'} = $borrowernumber;
            for my $col (keys %borrower) {
                # use values from extant patron unless our csv file includes this column or we provided a default.
                # FIXME : You cannot update a field with a  perl-evaluated false value using the defaults.
                unless(exists($csvkeycol{$col}) || $defaults{$col}) {
                    $borrower{$col} = $member->{$col} if($member->{$col}) ;
                }
            }
            unless (ModMember(%borrower)) {
                $invalid++;
                $template->param('lastinvalid'=>$borrower{'surname'}.' / '.$borrowernumber) if (!$commandline);
		$lastinvalid = $borrower{'surname'}.' / '.$borrowernumber;
                next LINE;
            }
            if ($extended) {
                if ($ext_preserve) {
                    my $old_attributes = GetBorrowerAttributes($borrowernumber);
                    $patron_attributes = extended_attributes_merge($old_attributes, $patron_attributes);  #TODO: expose repeatable options in template
                }
                SetBorrowerAttributes($borrower{'borrowernumber'}, $patron_attributes);
            }
            $overwritten++;
            $template->param('lastoverwritten'=>$borrower{'surname'}.' / '.$borrowernumber) if (!$commandline);
        } else {
            # FIXME: fixup_cardnumber says to lock table, but the web interface doesn't so this doesn't either.
            # At least this is closer to AddMember than in members/memberentry.pl
            if (!$borrower{'cardnumber'}) {
                $borrower{'cardnumber'} = fixup_cardnumber(undef);
            }
            if ($borrowernumber = AddMember(%borrower)) {
                if ($extended) {
                    SetBorrowerAttributes($borrowernumber, $patron_attributes);
                }
                if ($set_messaging_prefs) {
                    C4::Members::Messaging::SetMessagingPreferencesFromDefaults({ borrowernumber => $borrowernumber,
                                                                                  categorycode => $borrower{categorycode} });
                }
                $imported++;
                $template->param('lastimported'=>$borrower{'surname'}.' / '.$borrowernumber) if (!$commandline);
            } else {
                $invalid++;
                $template->param('lastinvalid'=>$borrower{'surname'}.' / AddMember') if (!$commandline);
                $lastinvalid = $borrower{'surname'}.' / AddMember';
            }
        }
    }
    (@errors  ) and $template->param(  ERRORS=>\@errors  ) if (!$commandline);
    (@feedback) and $template->param(FEEDBACK=>\@feedback) if (!$commandline);
    $template->param(
        'uploadborrowers' => 1,
        'imported'        => $imported,
        'overwritten'     => $overwritten,
        'alreadyindb'     => $alreadyindb,
        'invalid'         => $invalid,
        'total'           => $imported + $alreadyindb + $invalid + $overwritten,
    ) if (!$commandline);

    if (scalar(@errors) > 25 or $commandline) {

	my $total = $imported + $alreadyindb + $invalid + $overwritten;
	my $output;

	my $timestamp = C4::Dates->new()->output . " " . POSIX::strftime("%H:%M:%S",localtime);
	$output .= "Timestamp : $timestamp\n";
	$output .= "Import results\n";
	$output .= "$imported imported records\n";
	$output .= "$overwritten overwritten records\n";
	$output .= "$alreadyindb not imported because already in borrowers table and overwrite disabled\n"; 
	$output .= "(last was $lastalreadyindb)\n" if ($lastalreadyindb);
	$output .= "$invalid not imported because they are not in the expected format\n"; 
	$output .= "(last was $lastinvalid)\n" if ($lastinvalid);
	$output .= "$total records parsed\n";


	$output .= "\nError analysis\n";
	foreach my $hash (@errors) {
	   $output .= "Header row could not be parsed" if ($hash->{'badheader'});
	   foreach my $array ($hash->{'missing_criticals'}) {
	       foreach (@$array) {
		    $output .= "Line $_->{'line'}: ";
		    if ($hash->{'badparse'}) {
			$output .= "could not be parsed!";
		    } elsif ($hash->{'bad_date'}) { 
			$output .= "has $_->{'key'} in unrecognized format: $_->{'value'} ";
		    } else {
			$output .= "Critical field $_->{'key'}: ";
			if ($_->{'branch_map'} || $_->{'category_map'}) {
			    $output .= "has unrecognized value: $_->{'value'}";
			} else {
			    $output .= " missing";
			}
			$output .= " (borrowernumber: $_->{'borrowernumber'}; surname: $_->{'surname'})";
		    }
		    $output .= "\n";
		    $output .= $_->{'lineraw'} . "\n" if ($commandline);
		}
	   }
	}

    if (scalar(@errors) > 25 && !$commandline) {
	my $tmpf = File::Temp->new(UNLINK => 0);
	print $tmpf $output;
	$template->param(download_errors => 1, errors_filename => $tmpf->filename);
	close $tmpf;
    }

    if ($commandline) {
	# Write log file
	my $logfile = "/var/log/koha/reports/import_borrowers.log";
	if (open (FH, ">>$logfile")) {
	    print FH $output;
	    close(FH);
	} else {
	    $output .= "Unable to write to log file : $logfile\n";
	}


	# Send email with log
	 my $mail = MIME::Lite->new(
		    To      => C4::Context->preference('KohaAdminEmailAddress'),
		    Subject => "Import borrowers log email",
		    Type    => 'text/plain',
		    Data    => $output
		);
	$mail->send() or print "Unable to send log email";
    }
   }

} else {
    if ($extended) {
        my @matchpoints = ();
        my @attr_types = C4::Members::AttributeTypes::GetAttributeTypes();
        foreach my $type (@attr_types) {
            my $attr_type = C4::Members::AttributeTypes->fetch($type->{code});
            if ($attr_type->unique_id()) {
            push @matchpoints, { code =>  "patron_attribute_" . $attr_type->code(), description => $attr_type->description() };
            }
        }
        $template->param(matchpoints => \@matchpoints);
    }
}

output_html_with_http_headers $input, $cookie, $template->output if (!$commandline);

