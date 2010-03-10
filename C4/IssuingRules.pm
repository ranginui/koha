package C4::IssuingRules;

# Copyright 2009 BibLibre SARL
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
use warnings;
use C4::Context;
use C4::Koha;
use C4::SQLHelper qw( SearchInTable InsertInTable UpdateInTable DeleteInTable );
use Memoize;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
	# set the version for version checking
	$VERSION = 3.0.5;
	@ISA    = qw(Exporter);
	@EXPORT = qw(
	    &GetIssuingRule
		&GetIssuingRulesByBranchCode
		&GetIssuingRules
		&AddIssuingRule
		&ModIssuingRule
		&DelIssuingRule
	);
}

=head1 NAME

C4::IssuingRules - Koha issuing rules module

=head1 SYNOPSIS

use C4::IssuingRules;

=head1 DESCRIPTION

The functions in this module deal with issuing rules.

=head1 FUNCTIONS

=head2 GetIssuingRule

Compute the issuing rule for an itemtype, a borrower category and a branch.
Returns a hashref from the issuingrules table.

my $rule = &GetIssuingRule($categorycode, $itemtype, $branchcode);

The rules are applied from most specific to less specific, using the first found in this order:
    * same library, same patron type, same item type
    * same library, same patron type, default item type
    * same library, default patron type, same item type
    * same library, default patron type, default item type
    * default library, same patron type, same item type
    * default library, same patron type, default item type
    * default library, default patron type, same item type
    * default library, default patron type, default item type

The values in the returned hashref are inherited from a more generic rules if undef.

=cut
#Caching GetIssuingRule
memoize('GetIssuingRule');

sub GetIssuingRule {
    my ( $categorycode, $itemtype, $branchcode ) = @_;
    $categorycode||="*";
    $itemtype||="*";
    $branchcode||="*";

    # This configuration table defines the order of inheritance. We'll loop over it.
    my @attempts = (
        [ "*"          , "*"      , "*"         ],
        [ "*"          , $itemtype, "*"         ],
        [ $categorycode, "*"      , "*"         ],
        [ $categorycode, $itemtype, "*"         ],
        [ "*"          , "*"      , $branchcode ],
        [ "*"          , $itemtype, $branchcode ],
        [ $categorycode, "*"      , $branchcode ],
        [ $categorycode, $itemtype, $branchcode ],
    );

    # This complex query returns a nested hashref, so we can access a rule using :
    # my $rule = $$rules{$categorycode}{$itemtype}{$branchcode};
    # this will be usefull in the inheritance computation code
    my $dbh = C4::Context->dbh;
    my $rules = $dbh->selectall_hashref(
        "SELECT * FROM issuingrules where branchcode IN ('*',?) and itemtype IN ('*', ?) and categorycode IN ('*',?)",
        ["branchcode", "itemtype", "categorycode"],
        undef,
        ( $branchcode, $itemtype, $categorycode )
    );

    # This block is for inheritance. It loops over rules returned by the 
    # previous query. If a value is found in a more specific rule, it replaces 
    # the old value from the more generic rule.
    my $oldrule;
    for my $attempt ( @attempts ) {
        if ( my $rule = $$rules{@$attempt[2]}{@$attempt[1]}{@$attempt[0]} ) {
            if ( $oldrule ) {
                for ( keys %$oldrule ) {
                    if ( defined $rule->{$_} ) {
                        $oldrule->{$_} = $rule->{$_};
                    }
                }
            } else {
                $oldrule = $rule;
            }
        }
    }
    if($oldrule){
        return $oldrule;
    }else{
        return {
            'itemtype'          => $itemtype,
            'categorycode'      => $categorycode,
            'branchcode'        => $branchcode,
            'holdspickupdelay'  => 0,
       #     'maxissueqty'       => 0,
            'renewalsallowed'   => 0,
            'firstremind'       => 0,
            'accountsent'       => 0,
            'reservecharge'     => 0,
            'fine'              => 0,
            'restrictedtype'    => 0,
            'rentaldiscount'    => 0,
            'chargename'        => 0,
            'finedays'          => 0,
            'holdrestricted'    => 0,
            'allowonshelfholds' => 0,
            'reservesallowed'   => 0,
            'chargeperiod'      => 0,
       #     'issuelength'       => 0,
            'renewalperiod'     => 0,
        };
    }
}

=head2 GetIssuingRulesByBranchCode
  
  my @issuingrules = &GetIssuingRulesByBranchCode($branchcode);

  Retruns a list of hashref from the issuingrules Koha table for a given 
  branchcode.
  Each hashref will contain data from issuingrules plus human readable names of 
  patron and item categories.

=cut

sub GetIssuingRulesByBranchCode {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("
        SELECT issuingrules.*, itemtypes.description AS humanitemtype, categories.description AS humancategorycode
        FROM issuingrules
        LEFT JOIN itemtypes
            ON (itemtypes.itemtype = issuingrules.itemtype)
        LEFT JOIN categories
            ON (categories.categorycode = issuingrules.categorycode)
        WHERE issuingrules.branchcode = ?
        ORDER BY humancategorycode, humanitemtype
    ");
    $sth->execute(shift);
    
    my $res = $sth->fetchall_arrayref({});
    
    return @$res;
}

=head2 GetIssuingRules
  
  my @issuingrules = &GetIssuingRules({
      branchcode   => $branch, 
      categorycode => $input->param('categorycode'), 
      itemtype     => $input->param('itemtype'),
  });

  Get an issuing rule from Koha database.
  An alias for SearchInTable, see C4::SQLHelper for more help.

=cut

sub GetIssuingRules {
    my $res = SearchInTable('issuingrules', shift);
    return @$res;
}

=head2 AddIssuingRule

  my $issuingrule = {
      branchcode      => $branch,
      categorycode    => $input->param('categorycode'),
      itemtype        => $input->param('itemtype'),
      maxissueqty     => $maxissueqty,
      renewalsallowed => $input->param('renewalsallowed'),
      reservesallowed => $input->param('reservesallowed'),
      issuelength     => $input->param('issuelength'),
      fine            => $input->param('fine'),
      finedays        => $input->param('finedays'),
      firstremind     => $input->param('firstremind'),
      chargeperiod    => $input->param('chargeperiod'),
  };
  
  &AddIssuingRule( $issuingrule );

  Adds an issuing rule to Koha database.
  An alias for InsertInTable, see C4::SQLHelper for more help.

=cut

sub AddIssuingRule { InsertInTable('issuingrules',shift); }

=head2 ModIssuingRule
  
  &ModIssuingRule( $issuingrule );

  Update an issuing rule of the Koha database.
  An alias for UpdateInTable, see C4::SQLHelper for more help.

=cut

sub ModIssuingRule { UpdateInTable('issuingrules',shift); }

=head2 DelIssuingRule
  
  DelIssuingRule({
      branchcode   => $branch, 
      categorycode => $input->param('categorycode'), 
      itemtype     => $input->param('itemtype'),
  });

  Delete an issuing rule from Koha database.
  An alias for DeleteInTable, see C4::SQLHelper for more help.

=cut

sub DelIssuingRule { DeleteInTable('issuingrules',shift); }

1;

=head1 AUTHOR

Koha Developement team <info@koha.org>

Jean-André Santoni <jeanandre.santoni@biblibre.com>

=cut
