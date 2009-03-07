use strict;                                                                                                                                    
use warnings;                                                                                                                                  
use Carp;                                                                                                                                      
                                                                                                                                               
use base 'Koha::DataObject'; 

use constant QUERY => 'SELECT borrowernumber,cardnumber,firstname,surname FROM borrowers WHERE borrowernumber = ?';

__PACKAGE__->mk_accessors(qw(borrowernumber cardnumber firstname surname));

  
