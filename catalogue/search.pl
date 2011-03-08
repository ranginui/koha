#!/usr/bin/perl
# Script to perform searching
# For documentation try 'perldoc /path/to/search'
#
# Copyright 2006 LibLime
#
# This file is part of Koha
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

=head1 NAME

search - a search script for finding records in a Koha system (Version 3)

=head1 OVERVIEW

This script utilizes a new search API for Koha 3. It is designed to be 
simple to use and configure, yet capable of performing feats like stemming,
field weighting, relevance ranking, support for multiple  query language
formats (CCL, CQL, PQF), full support for the bib1 attribute set, extended
attribute sets defined in Zebra profiles, access to the full range of Z39.50
and SRU query options, federated searches on Z39.50/SRU targets, etc.

The API as represented in this script is mostly sound, even if the individual
functions in Search.pm and Koha.pm need to be cleaned up. Of course, you are
free to disagree :-)

I will attempt to describe what is happening at each part of this script.
-- Joshua Ferraro <jmf AT liblime DOT com>

=head2 INTRO

This script performs two functions:

=over 

=item 1. interacts with Koha to retrieve and display the results of a search

=item 2. loads the advanced search page

=back

These two functions share many of the same variables and modules, so the first
task is to load what they have in common and determine which template to use.
Once determined, proceed to only load the variables and procedures necessary
for that function.

=head2 LOADING ADVANCED SEARCH PAGE

This is fairly straightforward, and I won't go into detail ;-)

=head2 PERFORMING A SEARCH

If we're performing a search, this script  performs three primary
operations:

=over 

=item 1. builds query strings (yes, plural)

=item 2. perform the search and return the results array

=item 3. build the HTML for output to the template

=back

There are several additional secondary functions performed that I will
not cover in detail.

=head3 1. Building Query Strings
    
There are several types of queries needed in the process of search and retrieve:

=over

=item 1 $query - the fully-built query passed to zebra

This is the most complex query that needs to be built. The original design goal 
was to use a custom CCL2PQF query parser to translate an incoming CCL query into
a multi-leaf query to pass to Zebra. It needs to be multi-leaf to allow field 
weighting, koha-specific relevance ranking, and stemming. When I have a chance 
I'll try to flesh out this section to better explain.

This query incorporates query profiles that aren't compatible with most non-Zebra 
Z39.50 targets to acomplish the field weighting and relevance ranking.

=item 2 $simple_query - a simple query that doesn't contain the field weighting,
stemming, etc., suitable to pass off to other search targets

This query is just the user's query expressed in CCL CQL, or PQF for passing to a 
non-zebra Z39.50 target (one that doesn't support the extended profile that Zebra does).

=item 3 $query_cgi - passed to the template / saved for future refinements of 
the query (by user)

This is a simple string that completely expresses the query as a CGI string that
can be used for future refinements of the query or as a part of a history feature.

=item 4 $query_desc - Human search description - what the user sees in search
feedback area

This is a simple string that is human readable. It will contain '=', ',', etc.

=back

=head3 2. Perform the Search

This section takes the query strings and performs searches on the named servers,
including the Koha Zebra server, stores the results in a deeply nested object, 
builds 'faceted results', and returns these objects.

=head3 3. Build HTML

The final major section of this script takes the objects collected thusfar and 
builds the HTML for output to the template and user.

=head3 Additional Notes

Not yet completed...

=cut

use strict;    # always use

#use warnings; FIXME - Bug 2505

## STEP 1. Load things that are used in both search page and
# results page and decide which template to load, operations
# to perform, etc.

## load Koha modules
use C4::Context;
use C4::Output;
use C4::Auth qw(:DEFAULT get_session);
use C4::Biblio;
use C4::Search;
use C4::Search::Query;
use C4::Languages qw(getAllLanguagesAuthorizedValues);
use C4::Koha;
use C4::VirtualShelves qw(GetRecentShelves);
use POSIX qw(ceil floor);
use C4::Branch;    # GetBranches
use Data::Pagination;

# create a new CGI object
# FIXME: no_undef_params needs to be tested
use CGI qw('-no_undef_params');
my $cgi = new CGI;

my ( $template, $borrowernumber, $cookie );

# decide which template to use
my $template_name;
my $template_type;
if ( ($cgi->param("filters")) || ( $cgi->param("idx") ) || ( $cgi->param("q") ) || ( $cgi->param('multibranchlimit') ) || ( $cgi->param('limit-yr') ) ) {
    $template_name = 'catalogue/results.tmpl';
} else {
    $template_name = 'catalogue/advsearch.tmpl';
    $template_type = 'advsearch';
}

# load the template
( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {   template_name   => $template_name,
        query           => $cgi,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
    }
);
if ( C4::Context->preference("marcflavour") eq "UNIMARC" ) {
    $template->param( 'UNIMARC' => 1 );
}

## URI Re-Writing
# Deprecated, but preserved because it's interesting :-)
# The same thing can be accomplished with mod_rewrite in
# a more elegant way
#
#my $rewrite_flag;
#my $uri = $cgi->url(-base => 1);
#my $relative_url = $cgi->url(-relative=>1);
#$uri.="/".$relative_url."?";
#warn "URI:$uri";
#my @cgi_params_list = $cgi->param();
#my $url_params = $cgi->Vars;
#
#for my $each_param_set (@cgi_params_list) {
#    $uri.= join "",  map "\&$each_param_set=".$_, split("\0",$url_params->{$each_param_set}) if $url_params->{$each_param_set};
#}
#warn "New URI:$uri";
# Only re-write a URI if there are params or if it already hasn't been re-written
#unless (($cgi->param('r')) || (!$cgi->param()) ) {
#    print $cgi->redirect(     -uri=>$uri."&r=1",
#                            -cookie => $cookie);
#    exit;
#}

# load the branches
my $branches = GetBranches();
my @branch_loop;

# we need to know the borrower branch code to set a default branch
my $borrowerbranchcode = C4::Context->userenv->{'branch'};

for my $branch_hash ( sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches ) {

    # if independantbranches is activated, set the default branch to the borrower branch
    my $selected = ( C4::Context->preference("independantbranches") and ( $borrowerbranchcode eq $branch_hash ) ) ? 1 : undef;
    push @branch_loop, { value => "$branch_hash", branchcode =>  $branches->{$branch_hash}->{'branchcode'}, branchname => $branches->{$branch_hash}->{'branchname'}, selected => $selected };
}

my $categories = GetBranchCategories( undef, 'searchdomain' );

$template->param( branchloop => \@branch_loop, searchdomainloop => $categories );

$template->param( holdingbranch_index => C4::Search::Query::getIndexName('holdingbranch') );

# load the Type stuff
my $itemtypes = GetItemTypes;

#Give ability to search in authorised values
my $indexandavlist = C4::Search::Engine::Solr::GetIndexesWithAvlist;

# the index parameter is different for item-level itemtypes
my $itype_or_itemtype = ( C4::Context->preference("item-level_itypes") ) ? 'itype' : 'itemtype';
my @itemtypesloop;
my $selected = 1;
my $cnt;
my $advanced_search_types = C4::Context->preference("AdvancedSearchTypes");

if ( !$advanced_search_types or $advanced_search_types eq 'itemtypes' ) {
    foreach my $thisitemtype ( sort { $itemtypes->{$a}->{'description'} cmp $itemtypes->{$b}->{'description'} } keys %$itemtypes ) {
        my %row = (
            number      => $cnt++,
            index       => C4::Search::Query::getIndexName('itype'),
            code        => $thisitemtype,
            selected    => $selected,
            description => $itemtypes->{$thisitemtype}->{'description'},
            count5      => $cnt % 4,
            imageurl    => getitemtypeimagelocation( 'intranet', $itemtypes->{$thisitemtype}->{'imageurl'} ),
        );
        $selected = 0 if ($selected);
        push @itemtypesloop, \%row;
    }
} else {
    my $advsearchtypes = GetAuthorisedValues($advanced_search_types);
    for my $thisitemtype ( sort { $a->{'lib'} cmp $b->{'lib'} } @$advsearchtypes ) {
        my %row = (
            number      => $cnt++,
            index       => C4::Search::Query::getIndexName('ccode'),
            code        => $thisitemtype->{authorised_value},
            selected    => $selected,
            description => $thisitemtype->{'lib'},
            count5      => $cnt % 4,
            imageurl    => getitemtypeimagelocation( 'intranet', $thisitemtype->{'imageurl'} ),
        );
        push @itemtypesloop, \%row;
    }
}
$template->param( itemtypeloop => \@itemtypesloop );

# The following should only be loaded if we're bringing up the advanced search template
if ( $template_type eq 'advsearch' ) {

    # load the servers (used for searching -- to do federated searching, etc.)
    my $primary_servers_loop;    # = displayPrimaryServers();
    $template->param( outer_servers_loop => $primary_servers_loop, );

    my $secondary_servers_loop;
    $template->param( outer_sup_servers_loop => $secondary_servers_loop, );

    # set the default sorting
    my $sort_by = $cgi->param('sort_by') || join(' ', grep { defined } ( 
            C4::Search::Query::getIndexName(C4::Context->preference('defaultSortField'))
            , C4::Context->preference('defaultSortOrder') ) );
    warn $sort_by;
    my $sortloop = C4::Search::Engine::Solr::GetSortableIndexes('biblio');
    for ( @$sortloop ) { # because html template is stupid
        $_->{'asc_selected'}  = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' asc';
        $_->{'desc_selected'} = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' desc';
    }

    $template->param(
        'sortloop' => $sortloop,
        $sort_by => 1
    );

    # determine what to display next to the search boxes (ie, boolean option
    # shouldn't appear on the first one, scan indexes should, adding a new
    # box should only appear on the last, etc.
    my @search_boxes_array;
    my $search_boxes_count = C4::Context->preference("OPACAdvSearchInputCount") || 3;    # FIXME: using OPAC sysprefs?
                                                                                         # FIXME: all this junk can be done in TMPL using __first__ and __last__

    for ( my $i = 1 ; $i <= $search_boxes_count ; $i++ ) {

        # if it's the first one, don't display boolean option, but show scan indexes
        if ( $i == 1 ) {
            push @search_boxes_array, { scan_index => 1 };
        }

        # if it's the last one, show the 'add field' box
        elsif ( $i == $search_boxes_count ) {
            push @search_boxes_array,
              { boolean   => 1,
                add_field => 1,
              };
        } else {
            push @search_boxes_array, { boolean => 1, };
        }
    }
    $template->param(
        uc( C4::Context->preference("marcflavour") ) => 1,
        search_boxes_loop                            => \@search_boxes_array,
        indexandavlist                               => $indexandavlist
    );

    # load the language limits (for search)
    $template->param( search_languages_loop => getAllLanguagesAuthorizedValues() );
    $template->param( lang_index => C4::Search::Query::getIndexName('lang') );

    # use the global setting by default
    if ( C4::Context->preference("expandedSearchOption") == 1 ) {
        $template->param( expanded_options => C4::Context->preference("expandedSearchOption") );
    }

    # but let the user override it
    if ( ( $cgi->param('expanded_options') == 0 ) || ( $cgi->param('expanded_options') == 1 ) ) {
        $template->param( expanded_options => $cgi->param('expanded_options') );
    }

    if ( C4::Context->preference("AdvancedSearchContent") ne '' ) {
	$template->param( AdvancedSearchContent => C4::Context->preference("AdvancedSearchContent") ); 
    }

    $template->param( virtualshelves => C4::Context->preference("virtualshelves") );

    output_html_with_http_headers $cgi, $cookie, $template->output;
    exit;
}

### OK, if we're this far, we're performing a search, not just loading the advanced search page

# Fetch the paramater list as a hash in scalar context:
#  * returns paramater list as tied hash ref
#  * we can edit the values by changing the key
#  * multivalued CGI paramaters are returned as a packaged string separated by "\0" (null)
my $sort_by = $cgi->param('sort_by') || join(' ', grep { defined } ( C4::Context->preference('OPACdefaultSortField')
                                                                   , C4::Context->preference('OPACdefaultSortOrder') ) );
my $sortloop = C4::Search::Engine::Solr::GetSortableIndexes('biblio');
for ( @$sortloop ) { # because html template is stupid
    $_->{'asc_selected'}  = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' asc';
    $_->{'desc_selected'} = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' desc';
}

$template->param(
    'sort_by'  => $sort_by,
    'sortloop' => $sortloop,
);

# Fetch the paramater list as a hash in scalar context:
#  * returns paramater list as tied hash ref
#  * we can edit the values by changing the key
#  * multivalued CGI paramaters are returned as a packaged string separated by "\0" (null)
my $params = $cgi->Vars;
my $tag = $params->{tag};

# Params that can only have one value
my $count            = C4::Context->preference('OPACnumSearchResults') || 20;
my $page             = $cgi->param('page') || 1;

my $hits;
my $expanded_facet = $params->{'expand'};

# Define some global variables
my ( $error, $query, $simple_query, $query_cgi, $query_desc, $limit, $limit_cgi, $limit_desc, $stopwords_removed, $query_type );

if ($@ || $error) {
    $template->param(query_error => $error.$@);
    output_html_with_http_headers $cgi, $cookie, $template->output;
    exit;
}

my @results;

# Rebuild filters hash from GET data
my @fil = $cgi->param('filters');
my %filters;
for ( @fil ) {
    my ($k, $v) = split ':', $_;
    $filters{$k} = $v;
}
$filters{'recordtype'} = 'biblio';

# This array is used to build facets GUI
my @tplfilters;
while ( my ($k, $v) = each %filters) {
    $v =~ s/"//g;
    push @tplfilters, {
        'ind' => $k,
        'val' => $v,
    };
}
$template->param('filters' => \@tplfilters );

# perform the search
my @indexes = $cgi->param('idx');
my @operators = $cgi->param('op');
my @operands = $cgi->param('q');
my @avlists = $cgi->param('avlist');

my $q = C4::Search::Query->buildQuery(\@indexes, \@operands, \@operators);

#build search in authorised value list
if ($params->{'avlist'}) {
   foreach my $i (@indexes) {
     my $val = _getAvlist ($i, $indexandavlist);
     warn ">val:$val";
     if ($val ne '') {
       my $indexname = C4::Search::Query::getIndexName($i);
       my $value = shift (@avlists);
       $q .= " $indexname:$value ";
     }
   }

   sub _getAvlist {
     my ($index, $indexandavlist) = @_;
     foreach my $k (@$indexandavlist){
       if ($k->{'code'} eq $index){
         return $k->{'avlist'};
       }
     }
   }
}

# append year limits if they exist
if ( $params->{'limit-yr'} ) {
    if ( $params->{'limit-yr'} =~ /\d{4}-\d{4}/ ) {
        my ( $yr1, $yr2 ) = split( /-/, $params->{'limit-yr'} );
        $q .= ' AND date_pubdate:["' . C4::Search::Engine::Solr::NormalizeDate($yr1) . '" TO "' . C4::Search::Engine::Solr::NormalizeDate($yr2) . '"]';
    } elsif ( $params->{'limit-yr'} =~ /-\d{4}/ ) {
        $params->{'limit-yr'} =~ /-(\d{4})/;
        $q .= ' AND date_pubdate:[* TO "' . C4::Search::Engine::Solr::NormalizeDate($1) . '"]';
    } elsif ( $params->{'limit-yr'} =~ /\d{4}-/ ) {
        $params->{'limit-yr'} =~ /(\d{4})-/;
        $q .= ' AND date_pubdate:["' . C4::Search::Engine::Solr::NormalizeDate($1) . '" TO *]';
    } elsif ( $params->{'limit-yr'} =~ /\d{4}/ ) {
        $q .= ' AND date_pubdate:"' . C4::Search::Engine::Solr::NormalizeDate($params->{'limit-yr'}) . '"';
    } else {
        #FIXME: Should return a error to the user, incorect date format specified
    }
}

my $res = SimpleSearch( $q, \%filters, $page, $count, $sort_by);
C4::Context->preference("DebugLevel") eq '2' && warn "ProSolrSimpleSearch:q=$q:";

if (!$res){
    $template->param(query_error => "Bad request! help message ?");
    output_with_http_headers $cgi, $cookie, $template->output, 'html';
    exit;
}

my $pager = Data::Pagination->new(
    $res->{'pager'}->{'total_entries'},
    $count,
    20,
    $page,
);

# This array is used to build pagination links
my @pager_params = map { {
    ind => 'filters',
    val => $_->{'ind'}.':"'.$_->{'val'}.'"'
} } @tplfilters;
push @pager_params, { ind => 'q'      , val => $cgi->param('q') };
push @pager_params, { ind => 'sort_by', val => $sort_by         };

# Pager template params
$template->param(
    previous_page => $pager->{'prev_page'},
    next_page     => $pager->{'next_page'},
    PAGE_NUMBERS  => [ map { { page => $_, current => $_ == $page } } @{ $pager->{'numbers_of_set'} } ],
    current_page  => $page,
    pager_params  => \@pager_params,
);

# populate results with records
my @results;
my $itemtypes = C4::Search::getItemTypes();
my $subfieldstosearch = C4::Search::getSubfieldsToSearch();
my $itemtag = C4::Search::getItemTag();
my $b = C4::Search::getBranches();
for my $searchresult ( @{ $res->items } ) {
    my $interface = 'intranet';
    my $biblionumber = $searchresult->{'values'}->{'recordid'};

    my $biblio = C4::Search::getItemsInfos($biblionumber, $interface,
        $itemtypes, $subfieldstosearch, $itemtag, $b);

    my $display = 1;
    if (lc($interface) eq "opac") {
        if (C4::Context->preference('hidelostitems') or C4::Context->preference('hidenoitems')) {
            if (C4::Context->preference('hidelostitems') and $biblio->{itemlostcount} >= $biblio->{items_count}) {
                $display = 0;
            }
            if (C4::Context->preference('hidenoitems') and $biblio->{available_count} == 0) {
                $display = 0;
            }
        }
        if ($display == 1) {
            $biblio->{result_number} = ++$biblio->{shown};
            push( @results, $biblio);
        }
    } else {
        push( @results, $biblio );
    }

}

# build facets
my @facets;
while ( my ($index,$facet) = each %{$res->facets} ) {
    if ( @$facet > 1 ) {
        my @values;
        my ($type, $code) = split /_/, $index;
        for ( my $i = 0 ; $i < scalar(@$facet) ; $i++ ) {
            my $value = $facet->[$i++];
            my $count = $facet->[$i];
            push @values, {
                'value'   => $value,
                'count'   => $count,
                'active'  => $filters{$index} eq "\"$value\"", # TODO fails on diacritics
                'filters' => \@tplfilters,
            };
        }
        push @facets, {
            'index'  => $index,
            'label'  => C4::Search::Engine::Solr::GetIndexLabelFromCode($code),
            'values' => \@values,
        };
    }
}

$template->param(
    'total'          => $res->{'pager'}->{'total_entries'},
    'opacfacets'     => 1,
    'search_error'   => $error,
    'SEARCH_RESULTS' => \@results,
    'facets_loop'    => \@facets,
    'query'          => $params->{'q'},
    'searchdesc'     => $query_desc || $limit_desc,
    'availability'   => $filters{'int_availability'},
    'count'          => C4::Context->preference('OPACnumSearchResults') || 20,
);

# VI. BUILD THE TEMPLATE

# Build drop-down list for 'Add To:' menu...

my $row_count = 10;    # FIXME:This probably should be a syspref
my ( $pubshelves, $total ) = GetRecentShelves( 2, $row_count, undef );
my ( $barshelves, $total ) = GetRecentShelves( 1, undef,      $borrowernumber );

my @pubshelves = @{$pubshelves};
my @barshelves = @{$barshelves};

if (@pubshelves) {
    $template->param( addpubshelves     => scalar(@pubshelves) );
    $template->param( addpubshelvesloop => @pubshelves );
}

if (@barshelves) {
    $template->param( addbarshelves     => scalar(@barshelves) );
    $template->param( addbarshelvesloop => @barshelves );
}

output_html_with_http_headers $cgi, $cookie, $template->output;
