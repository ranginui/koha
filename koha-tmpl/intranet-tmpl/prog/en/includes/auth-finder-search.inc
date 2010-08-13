<form name="f" method="get" action="auth_finder.pl">
    <input type="hidden" name="index" value="<!-- TMPL_VAR NAME="index" -->" />
    <fieldset class="rows">
        <ol>
            <li>
                <span class="label">Authority type</span>
                <!-- TMPL_VAR NAME="authtypecode" -->
                <input type="hidden" name="authtypecode" value="<!-- TMPL_VAR NAME="authtypecode" -->" />
            </li>
            <li>
                <label for="value_mainstr">Search terms:</label>
                    <input type="text" name="value_mainstr" value="<!-- TMPL_VAR ESCAPE="HTML" name="value_mainstr" -->" />
            </li>
            <li>
                <label for="orderby">Sort by </label>
                <select name="orderby" id="orderby">
                    <option value="">No order</option>
                    <option value="name asc" selected="selected">Heading Ascendant</option>
                    <option value="name desc">Heading Descendant</option>
                </select>
            </li>
        </ol>
    </fieldset>
    <fieldset class="action"> <input type="submit" value="Start search" class="submit" /> <a class="cancel close" href="#">Cancel</a></fieldset>
</form>
