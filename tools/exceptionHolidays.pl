#!/usr/bin/perl

use strict;
use warnings;

use CGI;

use C4::Auth;
use C4::Output;


use C4::Calendar;

my $input = new CGI;
my $dbh = C4::Context->dbh();

my $branchcode = $input->param('showBranchName');
my $weekday = $input->param('showWeekday');
my $day = $input->param('showDay');
my $month = $input->param('showMonth');
my $year = $input->param('showYear');
my $title = $input->param('showTitle');
my $description = $input->param('showDescription');
my $holidaytype = $input->param('showHolidayType');

my $calendardate = sprintf("%04d-%02d-%02d", $year, $month, $day);
my $isodate = C4::Dates->new($calendardate, 'iso');
$calendardate = $isodate->output('syspref');

my $calendar = C4::Calendar->new(branchcode => $branchcode);

$title || ($title = '');
if ($description) {
    $description =~ s/\r/\\r/g;
    $description =~ s/\n/\\n/g;
} else {
    $description = '';
}   

if ($input->param('showOperation') eq 'exception') {
	$calendar->insert_exception_holiday(day => $day,
										month => $month,
									    year => $year,
						                title => $title,
						                description => $description);
} elsif ($input->param('showOperation') eq 'edit') {
    if($holidaytype eq 'weekday') {
      $calendar->ModWeekdayholiday(weekday => $weekday,
                                   title => $title,
                                   description => $description);
    } elsif ($holidaytype eq 'daymonth') {
      $calendar->ModDaymonthholiday(day => $day,
                                    month => $month,
                                    title => $title,
                                    description => $description);
    } elsif ($holidaytype eq 'ymd') {
      $calendar->ModSingleholiday(day => $day,
                                  month => $month,
                                  year => $year,
                                  title => $title,
                                  description => $description);
    } elsif ($holidaytype eq 'exception') {
      $calendar->ModExceptionholiday(day => $day,
                                  month => $month,
                                  year => $year,
                                  title => $title,
                                  description => $description);
    }
} elsif ($input->param('showOperation') eq 'delete') {
	$calendar->delete_holiday(weekday => $weekday,
	                          day => $day,
  	                          month => $month,
				              year => $year);
}
print $input->redirect("/cgi-bin/koha/tools/holidays.pl?branch=$branchcode&calendardate=$calendardate");
