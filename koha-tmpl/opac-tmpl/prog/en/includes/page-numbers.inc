<!-- TMPL_IF NAME="PAGE_NUMBERS" -->
    <div class="pages">
       <!-- Row of numbers corresponding to search result pages -->
       <!-- TMPL_IF NAME="previous_page" -->
          <a class="nav" href="/cgi-bin/koha/opac-search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" -->&amp;filters=<!-- TMPL_VAR NAME="ind" -->:&quot;<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&quot;<!-- /TMPL_LOOP -->&amp;<!-- TMPL_IF NAME="sort_by" -->sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR ESCAPE="URL" NAME="previous_page" -->">&lt;&lt; Previous</a>
       <!-- /TMPL_IF -->
       <!-- TMPL_LOOP NAME="PAGE_NUMBERS" -->
          <!-- TMPL_IF NAME="current" -->
             <span class="current">
                <!-- TMPL_VAR NAME="page" -->
             </span>
          <!-- TMPL_ELSE -->
             <a class="nav" href="/cgi-bin/koha/opac-search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" -->&amp;filters=<!-- TMPL_VAR NAME="ind" -->:&quot;<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&quot;<!-- /TMPL_LOOP -->&amp;<!-- TMPL_IF NAME="sort_by" -->sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR NAME="page" -->"><!-- TMPL_VAR NAME="page" --></a>
          <!-- /TMPL_IF -->
       <!-- /TMPL_LOOP -->
       <!-- TMPL_IF NAME="next_page" -->
          <a class="nav" href="/cgi-bin/koha/opac-search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" -->&amp;filters=<!-- TMPL_VAR NAME="ind" -->:&quot;<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&quot;<!-- /TMPL_LOOP -->&amp;<!-- TMPL_IF NAME="sort_by" -->sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->&amp;page=<!-- TMPL_VAR NAME="next_page" -->">Next &gt;&gt;</a>
       <!-- /TMPL_IF -->
   </div>
<!-- /TMPL_IF -->
