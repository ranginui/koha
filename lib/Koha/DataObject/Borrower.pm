package Koha::DataObject::Borrower;

use strict;
use warnings;
use Carp;

use base 'Koha::DataObject';

use constant QUERY =>
'SELECT borrowernumber,cardnumber,firstname,surname FROM borrowers WHERE borrowernumber = ?';
use constant CACHE_POLICY    => __PACKAGE__->CACHE_POLICY_ALWAYS;

__PACKAGE__->mk_accessors(qw(borrowernumber cardnumber firstname surname));

1;