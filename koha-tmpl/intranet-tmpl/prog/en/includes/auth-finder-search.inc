<form name="f" method="get" action="auth_finder.pl">
    <input type="hidden" name="index" value="<!-- TMPL_VAR NAME="index" -->" />
    <input type="hidden" name="op" value="do_search" />
    <fieldset class="rows">
        <ol>
            <li>
                <span class="label">Authority type</span>
                <!-- TMPL_VAR NAME="authtypecode" -->
                <input type="hidden" name="authtypecode" value="<!-- TMPL_VAR NAME="authtypecode" -->" />
            </li>
            <li>
                <label for="mainmainentry">Main entry ($a only): </label>
                <input type="hidden" name="marclist" value="mainmainentry" />
                <input type="text" name="authority_search" value="<!-- TMPL_VAR ESCAPE="HTML" name="authority_search" -->" />

            </li>
            <li>
                <label for="mainentry">Main entry: </label>
                <input type="hidden" name="marclist" value="mainentry" />
                <input type="text" name="main_heading" value="<!-- TMPL_VAR ESCAPE="HTML" name="main_heading" -->" />
            </li>
            <li>
                <label for="marclist">Anywhere: </label>
                <input type="hidden" name="marclist" value="" />
                <input type="text" name="all_headings" value="<!-- TMPL_VAR ESCAPE="HTML" name="value_any" -->" />
            </li>

            <li>
                <label for="orderby">Sort by </label>
                <select name="orderby" id="orderby">
                    <option value="">No order</option>
                    <option value="txt_name asc" selected="selected">Heading Ascendant</option>
                    <option value="txt_name desc">Heading Descendant</option>
                    <option value="int_usedinxbiblios asc">Usage Ascendant</option>
                    <option value="int_usedinxbiblios desc">Usage Descendant</option>
                </select>
            </li>
        </ol>
    </fieldset>
    <fieldset class="action"> <input type="submit" value="Start search" class="submit" /> <a class="cancel close" href="#">Cancel</a></fieldset>
</form>
