
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName %]</a></h1><!-- Begin Stopwords Resident Search Box -->
<div id="header_search">
 <div id="stopword_search" class="residentsearch">
 <p class="tip">Stop word search:</p>
 <form action="[% script_name %]" method="post">
 <input type="text" size="40" name="searchfield" value="[% searchfield %]" />
 <input type="submit" name="ok" class="submit" value="Search" />
 </form>
 </div>
 [% INCLUDE 'patron-search-box.inc' %] [% IF ( CAN_user_catalogue ) %] <div id="catalog_search" class="residentsearch" style="display:none;">
 <p class="tip">Enter search keywords:</p>
 <form action="/cgi-bin/koha/catalogue/search.pl"  method="get" id="cat-search-block">
 <input type="text" name="q" id="search-form" size="40" value="" title="Enter the terms you wish to search for." class="form-text" />
 <input type="submit" value="Submit"  class="submit" />
 </form>
 </div>
 [% END %] <ul>
 <li><a href="/cgi-bin/koha/admin/roadtype.pl#stopword_search">Search stop words</a></li>
 [% IF ( CAN_user_circulate ) %]<li><a href="/cgi-bin/koha/circ/circulation.pl#circ_search">Issue</a></li>[% END %] [% IF ( CAN_user_catalogue ) %]<li><a href="/cgi-bin/koha/catalogue/search.pl#catalog_search">Search the catalogue</a></li>[% END %] </ul> 
</div>
<!-- End Stopwords Resident Search Box -->