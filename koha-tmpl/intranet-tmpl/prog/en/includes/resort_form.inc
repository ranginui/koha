<option value="score asc">Relevance Asc</option>
<option value="score desc">Relevance Desc</option>

<!-- TMPL_LOOP NAME="sortloop" -->
    <option value="<!--TMPL_VAR NAME="type" -->_<!--TMPL_VAR NAME="code" --> asc"  <!-- TMPL_IF NAME="asc_selected"  -->selected="selected"<!-- /TMPL_IF -->><!--TMPL_VAR NAME="label" --> Asc</option>
    <option value="<!--TMPL_VAR NAME="type" -->_<!--TMPL_VAR NAME="code" --> desc" <!-- TMPL_IF NAME="desc_selected" -->selected="selected"<!-- /TMPL_IF -->><!--TMPL_VAR NAME="label" --> Desc</option>
<!-- /TMPL_LOOP -->

