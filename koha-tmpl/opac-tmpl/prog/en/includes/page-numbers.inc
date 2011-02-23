<!-- TMPL_IF NAME="PAGE_NUMBERS" -->
    <div class="pages">
       <!-- TMPL_IF NAME="previous_page" -->
          <a class="nav" href="?<!-- TMPL_LOOP NAME="pager_params" --><!-- TMPL_VAR ESCAPE="URL" NAME="ind" -->=<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&amp;<!-- /TMPL_LOOP -->page=<!-- TMPL_VAR ESCAPE="URL" NAME="previous_page" -->">&lt;&lt; Previous</a>
       <!-- /TMPL_IF -->
       <!-- TMPL_LOOP NAME="PAGE_NUMBERS" -->
          <!-- TMPL_IF NAME="current" -->
             <span class="current">
                <!-- TMPL_VAR NAME="page" -->
             </span>
          <!-- TMPL_ELSE -->
             <a class="nav" href="?<!-- TMPL_LOOP NAME="pager_params" --><!-- TMPL_VAR ESCAPE="URL" NAME="ind" -->=<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&amp;<!-- /TMPL_LOOP -->page=<!-- TMPL_VAR NAME="page" -->"><!-- TMPL_VAR NAME="page" --></a>
          <!-- /TMPL_IF -->
       <!-- /TMPL_LOOP -->
       <!-- TMPL_IF NAME="next_page" -->
          <a class="nav" href="?<!-- TMPL_LOOP NAME="pager_params" --><!-- TMPL_VAR ESCAPE="URL" NAME="ind" -->=<!-- TMPL_VAR ESCAPE="URL" NAME="val" -->&amp;<!-- /TMPL_LOOP -->page=<!-- TMPL_VAR NAME="next_page" -->">Next &gt;&gt;</a>
       <!-- /TMPL_IF -->
   </div>
<!-- /TMPL_IF -->
