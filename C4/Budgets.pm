package C4::Budgets;

# Copyright 2000-2002 Katipo Communications
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
use C4::Context;
use C4::Dates qw(format_date format_date_in_iso);
use C4::SQLHelper qw<:all>;
use C4::Debug;

use vars qw($VERSION @ISA @EXPORT);

BEGIN {
	# set the version for version checking
	$VERSION = 3.01;
	require Exporter;
	@ISA    = qw(Exporter);
	@EXPORT = qw(

        &GetBudget
        &GetBudgets
        &GetBudgetHierarchy
	    &AddBudget
        &ModBudget
        &DelBudget
        &GetBudgetSpent
        &GetBudgetOrdered
        &GetPeriodsCount

	    &GetBudgetPeriod
        &GetBudgetPeriods
        &ModBudgetPeriod
        &AddBudgetPeriod
	    &DelBudgetPeriod

	    &GetBudgetPeriodsDropbox
        &GetBudgetSortDropbox
        &GetAuthvalueDropbox
        &GetBudgetPermDropbox

        &ModBudgetPlan

        &GetCurrency
        &GetCurrencies
        &ModCurrencies
        &ConvertCurrency
        
		&GetBudgetsPlanCell
        &AddBudgetPlanValue
        &GetBudgetAuthCats
        &BudgetHasChildren
        &CheckBudgetParent
        &CheckBudgetParentPerm

        &HideCols
        &GetCols
	);
}

# ----------------------------BUDGETS.PM-----------------------------";


sub HideCols {
    my ( $authcat, @hide_cols ) = @_;
    my $dbh = C4::Context->dbh;

    my $sth1 = $dbh->prepare(
        qq|
        UPDATE aqbudgets_planning SET display = 0 
        WHERE authcat = ? 
        AND  authvalue = ? |
    );
    foreach my $authvalue (@hide_cols) {
#        $sth1->{TraceLevel} = 3;
        $sth1->execute(  $authcat, $authvalue );
    }
}

sub GetCols {
    my ( $authcat, $authvalue ) = @_;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(
        qq|
        SELECT count(display) as cnt from aqbudgets_planning
        WHERE  authcat = ? 
        AND authvalue = ? and display  = 0   |
    );

#    $sth->{TraceLevel} = 3;
    $sth->execute( $authcat, $authvalue );
    my $res  = $sth->fetchrow_hashref;

    return  $res->{cnt} > 0 ? 0: 1

}

sub CheckBudgetParentPerm {
    my ( $budget, $borrower_id ) = @_;
    my $depth = $budget->{depth};
    my $parent_id = $budget->{budget_parent_id};
    while ($depth) {
        my $parent = GetBudget($parent_id);
        $parent_id = $parent->{budget_parent_id};
        if ( $parent->{budget_owner_id} == $borrower_id ) {
            return 1;
        }
        $depth--
    }
    return 0;
}

sub AddBudgetPeriod {
    my ($budgetperiod) = @_;
	return InsertInTable("aqbudgetperiods",$budgetperiod);
}
# -------------------------------------------------------------------
sub GetPeriodsCount {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("
        SELECT COUNT(*) AS sum FROM aqbudgetperiods ");
    $sth->execute();
    my $res = $sth->fetchrow_hashref;
    return $res->{'sum'};
}

# -------------------------------------------------------------------
sub CheckBudgetParent {
    my ( $new_parent, $budget ) = @_;
    my $new_parent_id = $new_parent->{'budget_id'};
    my $budget_id     = $budget->{'budget_id'};
    my $dbh           = C4::Context->dbh;
    my $parent_id_tmp = $new_parent_id;

    # check new-parent is not a child (or a child's child ;)
    my $sth = $dbh->prepare(qq|
        SELECT budget_parent_id FROM
            aqbudgets where budget_id = ? | );
    while (1) {
        $sth->execute($parent_id_tmp);
        my $res = $sth->fetchrow_hashref;
        if ( $res->{'budget_parent_id'} == $budget_id ) {
            return 1;
        }
        if ( not defined $res->{'budget_parent_id'} ) {
            return 0;
        }
        $parent_id_tmp = $res->{'budget_parent_id'};
    }
}

# -------------------------------------------------------------------
sub BudgetHasChildren {
    my ( $budget_id  ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(qq|
       SELECT count(*) as sum FROM  aqbudgets
        WHERE budget_parent_id = ?   | );
    $sth->execute( $budget_id );
    my $sum = $sth->fetchrow_hashref;
    return $sum->{'sum'};
}

# -------------------------------------------------------------------
sub GetBudgetsPlanCell {
    my ( $cell, $period, $budget ) = @_;
    my ($actual, $sth);
    my $dbh = C4::Context->dbh;
    if ( $cell->{'authcat'} eq 'MONTHS' ) {
        # get the actual amount
        $sth = $dbh->prepare( qq|

            SELECT SUM(ecost) AS actual FROM aqorders
                WHERE    budget_id = ? AND
                entrydate like "$cell->{'authvalue'}%"  |
        );
        $sth->execute( $cell->{'budget_id'} );
    } elsif ( $cell->{'authcat'} eq 'BRANCHES' ) {
        # get the actual amount
        $sth = $dbh->prepare( qq|

            SELECT SUM(ecost) FROM aqorders
                LEFT JOIN aqorders_items
                ON (aqorders.ordernumber = aqorders_items.ordernumber)
                LEFT JOIN items
                ON (aqorders_items.itemnumber = items.itemnumber)
                WHERE budget_id = ? AND homebranch = ? |          );

        $sth->execute( $cell->{'budget_id'}, $cell->{'authvalue'} );
    } elsif ( $cell->{'authcat'} eq 'ITEMTYPES' ) {
        # get the actual amount
        $sth = $dbh->prepare(  qq|

            SELECT SUM( ecost *  quantity) AS actual
                FROM aqorders JOIN biblioitems
                ON (biblioitems.biblionumber = aqorders.biblionumber )
                WHERE aqorders.budget_id = ? and itemtype  = ? |
        );
        $sth->execute(  $cell->{'budget_id'},
                        $cell->{'authvalue'} );
    }
    # ELSE GENERIC ORDERS SORT1/SORT2 STAT COUNT.
    else {
        # get the actual amount
        $sth = $dbh->prepare( qq|

        SELECT  SUM(ecost * quantity) AS actual
            FROM aqorders
            JOIN aqbudgets ON (aqbudgets.budget_id = aqorders.budget_id )
            WHERE  aqorders.budget_id = ? AND
                ((aqbudgets.sort1_authcat = ? AND sort1 =?) OR
                (aqbudgets.sort2_authcat = ? AND sort2 =?))    |
        );
        $sth->execute(  $cell->{'budget_id'},
                        $budget->{'sort1_authcat'},
                        $cell->{'authvalue'},
                        $budget->{'sort2_authcat'},
                        $cell->{'authvalue'}
        );
    }
    $actual = $sth->fetchrow_array;

    # get the estimated amount
    $sth = $dbh->prepare( qq|

        SELECT estimated_amount AS estimated, display FROM aqbudgets_planning
            WHERE budget_period_id = ? AND
                budget_id = ? AND
                authvalue = ? AND
                authcat = ?         |
    );
    $sth->execute(  $cell->{'budget_period_id'},
                    $cell->{'budget_id'},
                    $cell->{'authvalue'},
                    $cell->{'authcat'},
    );


    my $res  = $sth->fetchrow_hashref;
  #  my $display = $res->{'display'};
    my $estimated = $res->{'estimated'};


    return $actual, $estimated;
}

# -------------------------------------------------------------------
sub ModBudgetPlan {
    my ( $budget_plan, $budget_period_id, $authcat ) = @_;
    my $dbh = C4::Context->dbh;
    foreach my $buds (@$budget_plan) {
        my $lines = $buds->{lines};
        my $sth = $dbh->prepare( qq|
                DELETE FROM aqbudgets_planning
                    WHERE   budget_period_id   = ? AND
                            budget_id   = ? AND
                            authcat            = ? |
        );
    #delete a aqplan line of cells, then insert new cells, 
    # these could be UPDATES rather than DEL/INSERTS...
        $sth->execute( $budget_period_id,  $lines->[0]{budget_id}   , $authcat );

        foreach my $cell (@$lines) {
            my $sth = $dbh->prepare( qq|

                INSERT INTO aqbudgets_planning
                     SET   budget_id     = ?,
                     budget_period_id  = ?,
                     authcat          = ?,
                     estimated_amount  = ?,
                     authvalue       = ?  |
            );
            $sth->execute(
                            $cell->{'budget_id'},
                            $cell->{'budget_period_id'},
                            $cell->{'authcat'},
                            $cell->{'estimated_amount'},
                            $cell->{'authvalue'},
            );
        }
    }
}

# -------------------------------------------------------------------
sub GetBudgetSpent {
	my ($budget_id) = @_;
	my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare(qq|
        SELECT SUM(ecost *  quantity) AS sum FROM aqorders
            WHERE budget_id = ? AND
            quantityreceived > 0 AND
            datecancellationprinted IS NULL
    |);

	$sth->execute($budget_id);
	my $sum =  $sth->fetchrow_array;
	return $sum;
}

# -------------------------------------------------------------------
sub GetBudgetOrdered {
	my ($budget_id) = @_;
	my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare(qq|
        SELECT SUM(ecost *  quantity) AS sum FROM aqorders
            WHERE budget_id = ? AND
            quantityreceived = 0 AND
            datecancellationprinted IS NULL
    |);

	$sth->execute($budget_id);
	my $sum =  $sth->fetchrow_array;
	return $sum;
}

# -------------------------------------------------------------------
sub GetBudgetPermDropbox {
	my ($perm) = @_;
	my %labels;
	$labels{'0'} = 'None';
	$labels{'1'} = 'Owner';
	$labels{'2'} = 'Library';
	my $radio = CGI::scrolling_list(
		-id       => 'budget_permission',
		-name      => 'budget_permission',
		-values    => [ '0', '1', '2' ],
		-default   => $perm,
		-labels    => \%labels,
		-size    => 1,
	);
	return $radio;
}

# -------------------------------------------------------------------
sub GetBudgetAuthCats  {
    my ($budget_period_id) = shift;
    # now, populate the auth_cats_loop used in the budget planning button
    # we must retrieve all auth values used by at least one budget
    my $dbh = C4::Context->dbh;
    my $sth=$dbh->prepare("SELECT sort1_authcat,sort2_authcat FROM aqbudgets WHERE budget_period_id=?");
    $sth->execute($budget_period_id);
    my %authcats;
    while (my ($sort1_authcat,$sort2_authcat) = $sth->fetchrow) {
        $authcats{$sort1_authcat}=1;
        $authcats{$sort2_authcat}=1;
    }
    my @auth_cats_loop;
    foreach (sort keys %authcats) {
        push @auth_cats_loop,{ authcat => $_ };
    }
    return \@auth_cats_loop;
}

# -------------------------------------------------------------------
sub GetAuthvalueDropbox {
	my ( $name, $authcat, $default ) = @_;
	my @authorised_values;
	my %authorised_lib;
	my $value;
	my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare(
		"SELECT authorised_value,lib
            FROM authorised_values
            WHERE category = ?
            ORDER BY  lib"
	);
	$sth->execute( $authcat );

	push @authorised_values, '';
	while (my ($value, $lib) = $sth->fetchrow_array) {
		push @authorised_values, $value;
		$authorised_lib{$value} = $lib;
	}

    return 0 if keys(%authorised_lib) == 0;

    my $budget_authvalue_dropbox = CGI::scrolling_list(
        -values   => \@authorised_values,
        -labels   => \%authorised_lib,
        -default  => $default,
        -override => 1,
        -size     => 1,
        -multiple => 0,
        -name     => $name,
        -id       => $name,
    );

    return $budget_authvalue_dropbox
}

# -------------------------------------------------------------------
sub GetBudgetPeriodsDropbox {
    my ($budget_period_id) = @_;
	my %labels;
	my @values;
	my ($active, $periods) = GetBudgetPeriods();
	foreach my $r (@$periods) {
		$labels{"$r->{budget_period_id}"} = $r->{budget_period_description};
		push @values, $r->{budget_period_id};
	}

	# if no buget_id is passed then its an add
	my $budget_period_dropbox = CGI::scrolling_list(
		-name    => 'budget_period_id',
		-values  => \@values,
		-default => $budget_period_id ? $budget_period_id :  $active,
		-size    => 1,
		-labels  => \%labels,
	);
	return $budget_period_dropbox;
}

# -------------------------------------------------------------------
sub GetBudgetPeriods {
	my ($filters,$orderby) = @_;
    return SearchInTable("aqbudgetperiods",$filters, $orderby, undef,undef, undef, "wide");
}
# -------------------------------------------------------------------
sub GetBudgetPeriod {
	my ($budget_period_id) = @_;
	my $dbh = C4::Context->dbh;
	## $total = number of records linked to the record that must be deleted
	my $total = 0;
	## get information about the record that will be deleted
	my $sth;
	if ($budget_period_id) {
		$sth = $dbh->prepare( qq|
              SELECT      *
                FROM aqbudgetperiods
                WHERE budget_period_id=? |
		);
		$sth->execute($budget_period_id);
	} else {         # ACTIVE BUDGET
		$sth = $dbh->prepare(qq|
			  SELECT      *
                FROM aqbudgetperiods
                WHERE budget_period_active=1 |
		);
		$sth->execute();
	}
	my $data = $sth->fetchrow_hashref;
	return $data;
}

# -------------------------------------------------------------------
sub DelBudgetPeriod{
	my ($budget_period_id) = @_;
	my $dbh = C4::Context->dbh;
	  ; ## $total = number of records linked to the record that must be deleted
    my $total = 0;

	## get information about the record that will be deleted
	my $sth = $dbh->prepare(qq|
		DELETE 
         FROM aqbudgetperiods
         WHERE budget_period_id=? |
	);
	return $sth->execute($budget_period_id);
}

# -------------------------------------------------------------------
sub ModBudgetPeriod {
	my ($budget_period_information) = @_;
	return UpdateInTable("aqbudgetperiods",$budget_period_information);
}

# -------------------------------------------------------------------
sub GetBudgetHierarchy {
	my ($budget_period_id, $branchcode, $owner) = @_;
	my @bind_params;
	my $dbh   = C4::Context->dbh;
	my $query = qq|
                    SELECT aqbudgets.*
                    FROM aqbudgets |;
    # show only period X if requested
	my @where_strings;
    if ($budget_period_id) {
        push @where_strings," aqbudgets.budget_period_id = ?";
        push @bind_params, $budget_period_id;
    }
	# show only budgets owned by me, my branch or everyone
    if ($owner) {
        if ($branchcode) {
            push @where_strings,qq{ (budget_owner_id = ? OR budget_branchcode = ? OR (budget_branchcode IS NULL or budget_branchcode="" AND (budget_owner_id IS NULL OR budget_owner_id="")))};
            push @bind_params, ($owner, $branchcode);
        } else {
            push @where_strings, ' (budget_owner_id = ? OR budget_owner_id IS NULL or budget_owner_id ="") ';
            push @bind_params, $owner;
        }
    } else {
        if ($branchcode) {
            push @where_strings," (budget_branchcode =? or budget_branchcode is NULL)";
            push @bind_params, $branchcode;
        }
    }
	$query.=" WHERE ".join(' AND ', @where_strings) if @where_strings;
	$debug && warn $query,join(",",@bind_params);
	my $sth = $dbh->prepare($query);
	$sth->execute(@bind_params);
	my $results = $sth->fetchall_arrayref({});
	my @res     = @$results;
	my $i = 0;
	while (1) {
		my $depth_cnt = 0;
		foreach my $r (@res) {
			my @child;
			# look for children
			$r->{depth} = '0' if !defined $r->{budget_parent_id};
			foreach my $r2 (@res) {
				if (defined $r2->{budget_parent_id}
					&& $r2->{budget_parent_id} == $r->{budget_id}) {
					push @child, $r2->{budget_id};
					$r2->{depth} = ($r->{depth} + 1) if defined $r->{depth};
				}
			}
			$r->{child} = \@child if scalar @child > 0;    # add the child
			$depth_cnt++ if !defined $r->{'depth'};
		}
		last if ($depth_cnt == 0 || $i == 100);
		$i++;
	}

	# look for top parents 1st
	my (@sort, $depth_count);
	($i, $depth_count) = 0;
	while (1) {
		my $children = 0;
		foreach my $r (@res) {
			if ($r->{depth} == $depth_count) {
				$children++ if (ref $r->{child} eq 'ARRAY');

				# find the parent id element_id and insert it after
				my $i2 = 0;
				my $parent;
				if ($depth_count > 0) {

					# add indent
					my $depth = $r->{depth} * 2;
					$r->{budget_code_indent} = $r->{budget_code};
					$r->{budget_name_indent} = $r->{budget_name};
					foreach my $r3 (@sort) {
						if ($r3->{budget_id} == $r->{budget_parent_id}) {
							$parent = $i2;
							last;
						}
						$i2++;
					}
				} else {
					$r->{budget_code_indent} = $r->{budget_code};
					$r->{budget_name_indent} = $r->{budget_name};
				}
                
				if (defined $parent) {
					splice @sort, ($parent + 1), 0, $r;
				} else {
					push @sort, $r;
				}
			}

			$i++;
		}    # --------------foreach
		$depth_count++;
		last if $children == 0;
	}

# add budget-percent and allocation, and flags for html-template
	foreach my $r (@sort) {
		my $subs_href = $r->{'child'};
        my @subs_arr = @$subs_href if defined $subs_href;

        my $moo = $r->{'budget_code_indent'};
        $moo =~ s/\ /\&nbsp\;/g;
        $r->{'budget_code_indent'} =  $moo;

        $moo = $r->{'budget_name_indent'};
        $moo =~ s/\ /\&nbsp\;/g;
        $r->{'budget_name_indent'} = $moo;

        $r->{'budget_spent'}       = GetBudgetSpent( $r->{'budget_id'} );

        $r->{'budget_amount_total'} =  $r->{'budget_amount'};

        # foreach sub-levels
        my $unalloc_count ;

		foreach my $sub (@subs_arr) {
			my $sub_budget = GetBudget($sub);

			$r->{budget_spent_sublevel} +=    GetBudgetSpent( $sub_budget->{'budget_id'} );
			$unalloc_count +=   $sub_budget->{'budget_amount'};
		}
	}
	return \@sort;
}

# -------------------------------------------------------------------

sub AddBudget {
    my ($budget) = @_;
	return InsertInTable("aqbudgets",$budget);
}

# -------------------------------------------------------------------
sub ModBudget {
    my ($budget) = @_;
	return UpdateInTable("aqbudgets",$budget);
}

# -------------------------------------------------------------------
sub DelBudget {
	my ($budget_id) = @_;
	my $dbh         = C4::Context->dbh;
	my $sth         = $dbh->prepare("delete from aqbudgets where budget_id=?");
	my $rc          = $sth->execute($budget_id);
	return $rc;
}

=back

=head2 FUNCTIONS ABOUT BUDGETS

=over 2

=cut

=head3 GetBudget

=over 4

&GetBudget($budget_id);

get a specific budget

=back

=cut

# -------------------------------------------------------------------
sub GetBudget {
    my ( $budget_id ) = @_;
    my $dbh = C4::Context->dbh;
    my $query = "
        SELECT *
        FROM   aqbudgets
        WHERE  budget_id=?
        ";
    my $sth = $dbh->prepare($query);
    $sth->execute( $budget_id );
    my $result = $sth->fetchrow_hashref;
    return $result;
}

=head3 GetBudgets

=over 4

&GetBudgets($filter, $order_by);

gets all budgets

=back

=cut

# -------------------------------------------------------------------
sub GetBudgets {
    my ($filters,$orderby) = @_;
    return SearchInTable("aqbudgets",$filters, $orderby, undef,undef, undef, "wide");
}

# -------------------------------------------------------------------

=head3 GetCurrencies

@currencies = &GetCurrencies;

Returns the list of all known currencies.

C<$currencies> is a array; its elements are references-to-hash, whose
keys are the fields from the currency table in the Koha database.

=cut

sub GetCurrencies {
    my $dbh   = C4::Context->dbh;
    my $query = "
        SELECT *
        FROM   currency
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @results = ();
    while ( my $data = $sth->fetchrow_hashref ) {
        push( @results, $data );
    }
    return @results;
}

# -------------------------------------------------------------------

sub GetCurrency {
    my $dbh   = C4::Context->dbh;
    my $query = "
        SELECT * FROM currency where active = '1'    ";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my $r = $sth->fetchrow_hashref;
    return $r;
}

=head3 ModCurrencies

&ModCurrencies($currency, $newrate);

Sets the exchange rate for C<$currency> to be C<$newrate>.

=cut

sub ModCurrencies {
    my ( $currency, $rate ) = @_;
    my $dbh   = C4::Context->dbh;
    my $query = qq|
        UPDATE currency
        SET    rate=?
        WHERE  currency=? |;
    my $sth = $dbh->prepare($query);
    $sth->execute( $rate, $currency );
}

# -------------------------------------------------------------------

=head3 ConvertCurrency

$foreignprice = &ConvertCurrency($currency, $localprice);

Converts the price C<$localprice> to foreign currency C<$currency> by
dividing by the exchange rate, and returns the result.

If no exchange rate is found,e is one
to one.

=cut

sub ConvertCurrency {
    my ( $currency, $price ) = @_;
    my $dbh   = C4::Context->dbh;
    my $query = "
        SELECT rate
        FROM   currency
        WHERE  currency=?
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($currency);
    my $cur = ( $sth->fetchrow_array() )[0];
    unless ($cur) {
        $cur = 1;
    }
    return ( $price / $cur );
}

=item
	returns an array containing fieldname followed by PRI as value if PRIMARY Key
=cut
sub _columns(;$) {
	my $tablename=shift||"aqbudgets";
    return @{C4::Context->dbh->selectcol_arrayref("SHOW columns from $tablename",{Columns=>[1,4]})};
}

sub _filter_fields{
	my $budget=shift;
	my $tablename=shift;
    my @keys; 
	my @values;
	my %columns= _columns($tablename);
	#Filter Primary Keys of table
    my $elements=join "|",grep {$columns{$_} ne "PRI"} keys %columns;
	foreach my $field (grep {/\b($elements)\b/} keys %$budget){
		$$budget{$field}=format_date_in_iso($$budget{$field}) if ($field=~/date/ && $$budget{$field} !~C4::Dates->regexp("iso"));
		my $strkeys= " $field = ? ";
		if ($field=~/branch/){
			$strkeys="( $strkeys OR $field='' OR $field IS NULL) ";
		}
		push @values, $$budget{$field};
		push @keys, $strkeys;
	}
	return (\@keys,\@values);
}

END { }    # module clean-up code here (global destructor)

1;
__END__

=back

=head1 AUTHOR

Koha Developement team <info@koha.org>

=cut
