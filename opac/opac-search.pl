#!/usr/bin/perl

# Copyright 2008 Garry Collum and the Koha Koha Development team
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

# Script to perform searching
# Mostly copied from search.pl, see POD there
use strict;    # always use
use warnings;

## STEP 1. Load things that are used in both search page and
# results page and decide which template to load, operations
# to perform, etc.
## load Koha modules
use C4::Context;
use C4::Output;
use C4::Auth qw(:DEFAULT get_session);
use C4::Languages qw(getAllLanguages);
use C4::Search;
use C4::Biblio;    # GetBiblioData
use C4::Koha;
use C4::Tags qw(get_tags);
use C4::Branch;    # GetBranches
use POSIX qw(ceil floor strftime);
use URI::Escape;
use Storable qw(thaw freeze);
use Data::Pagination;

# create a new CGI object
# FIXME: no_undef_params needs to be tested
use CGI qw('-no_undef_params');
my $cgi = new CGI;

BEGIN {
    if ( C4::Context->preference('BakerTaylorEnabled') ) {
        require C4::External::BakerTaylor;
        import C4::External::BakerTaylor qw(&image_url &link_url);
    }
}

my ( $template, $borrowernumber, $cookie );

# decide which template to use
my $template_name;
my $template_type = 'basic';
my @params        = $cgi->param("filters");

my $format = $cgi->param("format") || '';
my $build_grouped_results = C4::Context->preference('OPACGroupResults');
if ( $format =~ /(rss|atom|opensearchdescription)/ ) {
    $template_name = 'opac-opensearch.tmpl';
} elsif ($build_grouped_results) {
    $template_name = 'opac-results-grouped.tmpl';
} elsif ( ( @params >= 1 ) || ( $cgi->param("q") ) || ( $cgi->param('multibranchlimit') ) || ( $cgi->param('limit-yr') ) ) {
    $template_name = 'opac-results.tmpl';
} else {
    $template_name = 'opac-advsearch.tmpl';
    $template_type = 'advsearch';
}

# load the template
( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {   template_name   => $template_name,
        query           => $cgi,
        type            => "opac",
        authnotrequired => 1,
    }
);

if ( $format eq 'rss2' or $format eq 'opensearchdescription' or $format eq 'atom' ) {
    $template->param( $format => 1 );
    $template->param( timestamp => strftime( "%Y-%m-%dT%H:%M:%S-00:00", gmtime ) ) if ( $format eq 'atom' );

    # FIXME - the timestamp is a hack - the biblio update timestamp should be used for each
    # entry, but not sure if that's worth an extra database query for each bib
}
if ( C4::Context->preference("marcflavour") eq "UNIMARC" ) {
    $template->param( 'UNIMARC' => 1 );
} elsif ( C4::Context->preference("marcflavour") eq "MARC21" ) {
    $template->param( 'usmarc' => 1 );
}
$template->param( 'AllowOnShelfHolds' => C4::Context->preference('AllowOnShelfHolds') );

if ( C4::Context->preference('BakerTaylorEnabled') ) {
    $template->param(
        BakerTaylorEnabled      => 1,
        BakerTaylorImageURL     => &image_url(),
        BakerTaylorLinkURL      => &link_url(),
        BakerTaylorBookstoreURL => C4::Context->preference('BakerTaylorBookstoreURL'),
    );
}
if ( C4::Context->preference('TagsEnabled') ) {
    $template->param( TagsEnabled => 1 );
    foreach (qw(TagsShowOnList TagsInputOnList)) {
        C4::Context->preference($_) and $template->param( $_ => 1 );
    }
}

# load the branches
my $mybranch = ( C4::Context->preference('SearchMyLibraryFirst') && C4::Context->userenv && C4::Context->userenv->{branch} ) ? C4::Context->userenv->{branch} : '';
my $branches = GetBranches();    # used later in *getRecords, probably should be internalized by those functions after caching in C4::Branch is established
my $branchloop = GetBranchesLoop( $mybranch, 0 );
unless ($mybranch){
    foreach (@$branchloop){
        $_->{'selected'}=0;
    }
}
$template->param(
    branchloop       => $branchloop,
    searchdomainloop => GetBranchCategories( undef, 'searchdomain' ),
);

# load the language limits (for search)
$template->param( search_languages_loop => getAllLanguages() );

# load the sorting stuff
my $sort_by = $cgi->param('sort_by') || C4::Context->preference('OPACdefaultSortField').' '. C4::Context->preference('OPACdefaultSortOrder');
my $sortloop = C4::Search::GetSortableIndexes('biblio');
for ( @$sortloop ) { # because html template is stupid
    $_->{'asc_selected'}  = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' asc';
    $_->{'desc_selected'} = $sort_by eq $_->{'type'}.'_'.$_->{'code'}.' desc';
}

$template->param(
    'sort_by'  => $sort_by,
    'sortloop' => $sortloop,
);

# load the Type stuff
my $itemtypes = GetItemTypes;

# the index parameter is different for item-level itemtypes
my $itype_or_itemtype = ( C4::Context->preference("item-level_itypes") ) ? 'str_itype' : 'str_itemtype';
my @itemtypesloop;
my $selected = 1;
my $cnt;
my $advanced_search_types = C4::Context->preference("AdvancedSearchTypes");

if ( !$advanced_search_types or $advanced_search_types eq 'itemtypes' ) {
    foreach my $thisitemtype ( sort { $itemtypes->{$a}->{'description'} cmp $itemtypes->{$b}->{'description'} } keys %$itemtypes ) {
        my %row = (
            number      => $cnt++,
            index       => $itype_or_itemtype,
            code        => $thisitemtype,
            selected    => $selected,
            description => $itemtypes->{$thisitemtype}->{'description'},
            count5      => $cnt % 4,
            imageurl    => getitemtypeimagelocation( 'opac', $itemtypes->{$thisitemtype}->{'imageurl'} ),
        );
        $selected = 0;    # set to zero after first pass through
        push @itemtypesloop, \%row;
    }
} else {
    my $advsearchtypes = GetAuthorisedValues( $advanced_search_types, '', 'opac' );
    for my $thisitemtype (@$advsearchtypes) {
        my %row = (
            number      => $cnt++,
            ccl         => $advanced_search_types,
            code        => $thisitemtype->{authorised_value},
            selected    => $selected,
            description => $thisitemtype->{'lib'},
            count5      => $cnt % 4,
            imageurl    => getitemtypeimagelocation( 'opac', $thisitemtype->{'imageurl'} ),
        );
        push @itemtypesloop, \%row;
    }
}
$template->param( itemtypeloop => \@itemtypesloop );

# # load the itypes (Called item types in the template -- just authorized values for searching)
# my ($itypecount,@itype_loop) = GetCcodes();
# $template->param(itypeloop=>\@itype_loop,);

# The following should only be loaded if we're bringing up the advanced search template
if ( $template_type && $template_type eq 'advsearch' ) {

    # set the default sorting
    my $default_sort_by = C4::Context->preference('OPACdefaultSortField') . "_" . C4::Context->preference('OPACdefaultSortOrder')
      if ( C4::Context->preference('OPACdefaultSortField') && C4::Context->preference('OPACdefaultSortOrder') );
    $template->param( $default_sort_by => 1 );

    # determine what to display next to the search boxes (ie, boolean option
    # shouldn't appear on the first one, scan indexes should, adding a new
    # box should only appear on the last, etc.
    my $indexloop = C4::Search::GetIndexes('biblio');
    my $search_boxes_count = C4::Context->preference("OPACAdvSearchInputCount") || 3;
    my @search_boxes_array = map {{ indexloop => $indexloop }} 1..$search_boxes_count;
    
    $template->param(
        uc( C4::Context->preference("marcflavour") ) => 1,                     # we already did this for UNIMARC
        advsearch                                    => 1,
        search_boxes_loop                            => \@search_boxes_array,
    );

    # use the global setting by default
    if ( C4::Context->preference("expandedSearchOption") == 1 ) {
        $template->param( expanded_options => C4::Context->preference("expandedSearchOption") );
    }

    if ( C4::Context->preference("OpacAdvancedSearchContent") ne '' ) {
        $template->param( OpacAdvancedSearchContent => C4::Context->preference("OpacAdvancedSearchContent") );
    }

    # but let the user override it
    if ( defined $cgi->param('expanded_options') ) {
        if ( ( $cgi->param('expanded_options') == 0 ) || ( $cgi->param('expanded_options') == 1 ) ) {
            $template->param( expanded_options => $cgi->param('expanded_options') );
        }
    }
    output_html_with_http_headers $cgi, $cookie, $template->output;
    exit;
}

### OK, if we're this far, we're performing an actual search

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
my $res = SimpleSearch( $cgi->param('q'), \%filters, $page, $count, $sort_by);

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
push @pager_params, { ind => 'sort_by', val => $sort_by };

# Pager template params
$template->param(
    previous_page => $pager->{'prev_page'},
    next_page     => $pager->{'next_page'},
    PAGE_NUMBERS  => [ map { { page => $_, current => $_ == $page } } @{ $pager->{'numbers_of_set'} } ],
    current_page  => $page,
    pager_params  => \@pager_params,
);

# populate results with records
my @results = map { GetBiblio $_->{'values'}->{'recordid'} } @{ $res->items };

# build facets
my @facets;
while ( my ($index,$facet) = each %{$res->facets} ) {
    if ( @$facet > 1 ) {
        my @values;
        my ($type, $code) = split /_/, $index;

        for ( my $i = 0 ; $i < scalar(@$facet) ; $i++ ) {
            my $value = $facet->[$i++];
            my $count = $facet->[$i];
            utf8::encode($value);
            
            push @values, {
                'value'   => $value,
                'count'   => $count,
                'active'  => $filters{$index} eq "\"$value\"",
                'filters' => \@tplfilters,
            };
        }

        push @facets, {
            'index'  => $index,
            'label'  => C4::Search::GetIndexLabelFromCode($code),
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
    'searchdesc'     => $params->{'q'} || @tplfilters,
    'availability'   => $filters{'int_availability'},
);

# VI. BUILD THE TEMPLATE
# Build drop-down list for 'Add To:' menu...
my $session = get_session( $cgi->cookie("CGISESSID") );
my @addpubshelves;
my $pubshelves = $session->param('pubshelves');
my $barshelves = $session->param('barshelves');
foreach my $shelf (@$pubshelves) {
    next if ( ( $shelf->{'owner'} != ( $borrowernumber ? $borrowernumber : -1 ) ) && ( $shelf->{'category'} < 3 ) );
    push( @addpubshelves, $shelf );
}

if (@addpubshelves) {
    $template->param( addpubshelves     => scalar(@addpubshelves) );
    $template->param( addpubshelvesloop => \@addpubshelves );
}

if ( defined $barshelves ) {
    $template->param( addbarshelves     => scalar(@$barshelves) );
    $template->param( addbarshelvesloop => $barshelves );
}

my $content_type = ( $format eq 'rss' or $format eq 'atom' ) ? $format : 'html';

# If GoogleIndicTransliteration system preference is On Set paramter to load Google's javascript in OPAC search screens
if ( C4::Context->preference('GoogleIndicTransliteration') ) {
    $template->param( 'GoogleIndicTransliteration' => 1 );
}

output_with_http_headers $cgi, $cookie, $template->output, $content_type;
