<script type="text/javascript">
//<![CDATA[
YAHOO.util.Event.onContentReady("header_search", function() {
    new function() {
        // Define a custom formatter function
        this.fnCustomFormatter = function(oResultItem, sQuery) {
            var name        = oResultItem[0];
            var aMarkup = [
                "<div class=\"sample-result\">",
                name,
                "<\/div>"];
            return (aMarkup.join(""));
        };

        // authority_search
        this.authority_search_ds = new YAHOO.widget.DS_XHR("/cgi-bin/koha/authorities/ysearch.pl", ["\n", "\t"]);
        this.authority_search_ds.scriptQueryAppend = "orderby=<!-- TMPL_VAR NAME='name_index_name' --> asc&searchtype=authority_search";
        this.authority_search_ds.responseType = YAHOO.widget.DS_XHR.TYPE_FLAT;
        this.authority_search_ds.maxCacheEntries = 60;
        this.authority_search_ds.queryMatchSubset = false;

        var myInput = document.getElementById('authority_search');
        var myContainer = document.getElementById('authority_search_container');
        this.oAutoComp = new YAHOO.widget.AutoComplete(myInput,myContainer,this.authority_search_ds);
        this.oAutoComp.queryDelay = 1;
        this.oAutoComp.formatResult = this.fnCustomFormatter;
        this.oAutoComp.maxResultsDisplayed = 1000;

        // main_heading
        this.main_heading_ds = new YAHOO.widget.DS_XHR("/cgi-bin/koha/authorities/ysearch.pl", ["\n", "\t"]);
        this.main_heading_ds.scriptQueryAppend = "orderby=<!-- TMPL_VAR NAME='name_index_name' --> asc&searchtype=main_heading";
        this.main_heading_ds.responseType = YAHOO.widget.DS_XHR.TYPE_FLAT;
        this.main_heading_ds.maxCacheEntries = 60;
        this.main_heading_ds.queryMatchSubset = false;

        var myInput = document.getElementById('main_heading');
        var myContainer = document.getElementById('main_heading_container');
        this.oAutoComp = new YAHOO.widget.AutoComplete(myInput,myContainer,this.main_heading_ds);
        this.oAutoComp.queryDelay = 1;
        this.oAutoComp.formatResult = this.fnCustomFormatter;
        this.oAutoComp.maxResultsDisplayed = 1000;


        // all_headings
        this.all_headings_ds = new YAHOO.widget.DS_XHR("/cgi-bin/koha/authorities/ysearch.pl", ["\n", "\t"]);
        this.all_headings_ds.scriptQueryAppend = "orderby=<!-- TMPL_VAR NAME='name_index_name' --> asc&searchtype=all_headings";
        this.all_headings_ds.responseType = YAHOO.widget.DS_XHR.TYPE_FLAT;
        this.all_headings_ds.maxCacheEntries = 60;
        this.all_headings_ds.queryMatchSubset = false;

        var myInput = document.getElementById('all_headings');
        var myContainer = document.getElementById('all_headings_container');
        this.oAutoComp = new YAHOO.widget.AutoComplete(myInput,myContainer,this.all_headings_ds);
        this.oAutoComp.queryDelay = 1;
        this.oAutoComp.formatResult = this.fnCustomFormatter;
        this.oAutoComp.maxResultsDisplayed = 1000;

    }
});
//]]>
</script>

<span id="header_search">
<form name="f" method="get" action="auth_finder.pl">
    <input type="hidden" name="index" value="<!-- TMPL_VAR NAME="index" -->" />
    <input type="hidden" name="op" value="do_search" />
    <fieldset class="rows">
        <ol>
            <li>
                <span class="label">Authority type</span>
                <!-- TMPL_VAR NAME="authtypecode" -->
                <input type="hidden" name="authtypecode" value="<!-- TMPL_VAR ESCAPE="HTML" NAME="authtypecode" -->" />
            </li>
            <li>
                <label for="authority_search">Main entry ($a only): </label>
                <input id="authority_search" style="width:400px;" type="text" name="authority_search" value="<!-- TMPL_VAR ESCAPE="HTML" name="authority_search" -->" />
                <div id="authority_search_container"></div>

            </li>
            <li>
                <label for="main_heading">Main entry: </label>
                <input id="main_heading" style="width:400px;" type="text" name="main_heading" value="<!-- TMPL_VAR ESCAPE="HTML" name="main_heading" -->" />
                <div id="main_heading_container"></div>
            </li>
            <li>
                <label for="all_headings">Anywhere: </label>
                <input id="all_headings" style="width:400px;" type="text" name="all_headings" value="<!-- TMPL_VAR ESCAPE="HTML" name="all_headings" -->" />
                <div id="all_headings_container"></div>
            </li>

            <li>
                <label for="orderby">Sort by </label>
                <select name="orderby" id="orderby">
                    <option value="">No order</option>
                    <option value="<!-- TMPL_VAR NAME="name_index_name" --> asc" selected="selected">Heading Ascendant</option>
                    <option value="<!-- TMPL_VAR NAME="name_index_name" --> desc">Heading Descendant</option>
                    <option value="<!-- TMPL_VAR NAME="usedinxbiblios_index_name" --> asc">Usage Ascendant</option>
                    <option value="<!-- TMPL_VAR NAME="usedinxbiblios_index_name" --> desc">Usage Descendant</option>
                </select>
            </li>
        </ol>
    </fieldset>
    <fieldset class="action"> <input type="submit" value="Start search" class="submit" /> <a class="cancel close" href="#">Cancel</a></fieldset>
</form>
</span>
