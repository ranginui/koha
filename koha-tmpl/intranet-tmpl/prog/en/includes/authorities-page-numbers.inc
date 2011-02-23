<!-- TMPL_IF NAME="PAGE_NUMBERS" -->
    <div class="pages">
       <!-- Row of numbers corresponding to search result pages -->
       <!-- TMPL_IF NAME="previous_page" -->
          <a class="nav" href="/cgi-bin/koha/authorities/authorities-home.pl?op=do_search&amp;searchtype=<!-- TMPL_VAR ESCAPE="URL" NAME="searchtype" -->&amp;value=<!-- TMPL_VAR ESCAPE="URL" NAME="value" -->&amp;<!-- TMPL_IF NAME="orderby" -->orderby=<!-- TMPL_VAR ESCAPE="URL" NAME="orderby" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR ESCAPE="URL" NAME="previous_page" -->">&lt;&lt; Previous</a>
       <!-- /TMPL_IF -->
       <!-- TMPL_LOOP NAME="PAGE_NUMBERS" -->
          <!-- TMPL_IF NAME="current" -->
             <span class="current">
                <!-- TMPL_VAR NAME="page" -->
             </span>
          <!-- TMPL_ELSE -->
             <a class="nav" href="/cgi-bin/koha/authorities/authorities-home.pl?op=do_search&amp;searchtype=<!-- TMPL_VAR ESCAPE="URL" NAME="searchtype" -->&amp;value=<!-- TMPL_VAR ESCAPE="URL" NAME="value" -->&amp;<!-- TMPL_IF NAME="orderby" -->orderby=<!-- TMPL_VAR ESCAPE="URL" NAME="orderby" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR NAME="page" -->"><!-- TMPL_VAR NAME="page" --></a>
          <!-- /TMPL_IF -->
       <!-- /TMPL_LOOP -->
       <!-- TMPL_IF NAME="next_page" -->
          <a class="nav" href="/cgi-bin/koha/authorities/authorities-home.pl?op=do_search&amp;searchtype=<!-- TMPL_VAR ESCAPE="URL" NAME="searchtype" -->&amp;value=<!-- TMPL_VAR ESCAPE="URL" NAME="value" -->&amp;<!-- TMPL_IF NAME="orderby" -->orderby=<!-- TMPL_VAR ESCAPE="URL" NAME="orderby" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR NAME="next_page" -->">Next &gt;&gt;</a>
       <!-- /TMPL_IF -->
   </div>
<!-- /TMPL_IF -->
