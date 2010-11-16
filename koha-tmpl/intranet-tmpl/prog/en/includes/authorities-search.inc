<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl"><!-- TMPL_VAR NAME="LibraryName" --></a></h1>
<!-- Begin Authorities Resident Search Box -->
<div id="header_search" class="residentsearch">
    <div id="authority_search" class="residentsearch">
    <p class="tip">Enter authority heading ($a):</p>
    <form action="/cgi-bin/koha/authorities/authorities-home.pl" method="get">
        <input type="hidden" name="op" value="do_search" />

        <select name="authtypecode">
        	<option value="">All Authority Types</option>
        <!-- TMPL_LOOP NAME="authtypesloop" -->
            <!-- TMPL_IF name="selected" -->
            <option value="<!-- TMPL_VAR NAME="value" -->" selected="selected"><!-- TMPL_VAR NAME="authtypetext" --></option>
            <!-- TMPL_ELSE -->
            <option value="<!-- TMPL_VAR NAME="value" -->"><!-- TMPL_VAR NAME="authtypetext" --></option>
            <!-- /TMPL_IF -->
        <!-- /TMPL_LOOP -->
        </select>

        <input id="value_anywhere" type="text" name="value" value="<!-- TMPL_VAR NAME="value" -->" />
        <select name="orderby">
            <option value="">None</option>
            <option value="score desc" selected="selected">Relevance</option>
            <option value="txt_name asc">Name</option>
            <option value="int_usedinxbiblios desc">Usage</option>
         </select>
         <input type="submit" class="submit" value="Submit" />
    </form>
    </div>
    <ul>
        <li><a href="/cgi-bin/koha/authorities/authorities-home.pl#authority_search">Search Authorities</a></li>
    </ul>
</div>
<!-- End Authorities Resident Search Box -->
