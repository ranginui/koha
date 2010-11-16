<!-- TMPL_IF NAME="opacfacets" -->
<!-- TMPL_IF NAME="facets_loop" -->
<div id="search-facets">
    <h4>Refine your search</h4>
    <ul>
	    <li>Availability
	        <ul>
	            <li>
	                <!-- TMPL_IF NAME="availability" -->
	                Showing only <strong>available</strong> items.
	                <a href="/cgi-bin/koha/catalogue/search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" --><!-- TMPL_UNLESS EXPR="ind eq 'int_availability'" -->&amp;filters=<!--TMPL_VAR ESCAPE="URL" NAME="ind"-->:&quot;<!--TMPL_VAR ESCAPE="URL" NAME="val"-->&quot;<!-- /TMPL_UNLESS --><!-- /TMPL_LOOP --><!-- TMPL_IF NAME="sort_by" -->&amp;sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->">Show all items</a>
	                <!-- TMPL_ELSE -->
	                Limit to <a href="/cgi-bin/koha/catalogue/search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" --><!-- TMPL_UNLESS EXPR="ind eq index" -->&amp;filters=<!--TMPL_VAR ESCAPE="URL" NAME="ind"-->:&quot;<!--TMPL_VAR ESCAPE="URL" NAME="val"-->&quot;<!-- /TMPL_UNLESS --><!-- /TMPL_LOOP -->&amp;filters=int_availability:&quot;1&quot;<!-- TMPL_IF NAME="sort_by" -->&amp;sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->">currently available items.</a>
	                <!-- /TMPL_IF -->
	            </li>
	        </ul>
	        <!-- TMPL_IF NAME="related" -->
	        <li>(related searches: <!-- TMPL_LOOP NAME="related" --><!-- TMPL_VAR NAME="related_search" --><!-- /TMPL_LOOP -->)</li>
	        <!-- /TMPL_IF -->
	    </li>
        <!-- TMPL_LOOP NAME="facets_loop" -->
        <li>
            <!-- TMPL_VAR NAME="label" -->
            <ul>
                <!-- TMPL_LOOP NAME="values" -->
                <li>
                    <!-- TMPL_IF NAME="active" -->
                        <!-- TMPL_VAR NAME="value" -->
                        (<!-- TMPL_VAR NAME="count" -->)
                        [<a href="/cgi-bin/koha/catalogue/search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" --><!-- TMPL_UNLESS EXPR="ind eq index && val eq value" -->&amp;filters=<!--TMPL_VAR ESCAPE="URL" NAME="ind"-->:&quot;<!--TMPL_VAR ESCAPE="URL" NAME="val"-->&quot;<!-- /TMPL_UNLESS --><!-- /TMPL_LOOP --><!-- TMPL_IF NAME="sort_by" -->&amp;sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->">x</a>]
                    <!-- TMPL_ELSE -->
                        <a href="/cgi-bin/koha/catalogue/search.pl?q=<!-- TMPL_VAR ESCAPE="URL" NAME="query" --><!-- TMPL_LOOP NAME="filters" --><!-- TMPL_UNLESS EXPR="ind eq index" -->&amp;filters=<!--TMPL_VAR ESCAPE="URL" NAME="ind"-->:&quot;<!--TMPL_VAR ESCAPE="URL" NAME="val"-->&quot;<!-- /TMPL_UNLESS --><!-- /TMPL_LOOP -->&amp;filters=<!--TMPL_VAR ESCAPE="URL" NAME="index"-->:&quot;<!-- TMPL_VAR ESCAPE="URL" NAME="value" -->&quot;<!-- TMPL_IF NAME="sort_by" -->&amp;sort_by=<!-- TMPL_VAR ESCAPE="URL" NAME="sort_by" --><!-- /TMPL_IF -->">
                            <!-- TMPL_VAR NAME="value" -->
                        </a>
                        (<!-- TMPL_VAR NAME="count" -->)
                    <!-- /TMPL_IF -->
                </li>
                <!-- /TMPL_LOOP -->
            </ul>
        </li>
        <!-- /TMPL_LOOP -->
    </ul>
</div>
<!-- /TMPL_IF -->
<!-- /TMPL_IF -->
