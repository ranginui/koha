[% UNLESS ( no_add ) %] <div id="toolbar">
 <script type="text/javascript">
	//<![CDATA[

	// prepare DOM for YUI Toolbar

	 $(document).ready(function() {
[% IF ( AddPatronLists_categorycode ) %]
[% ELSE %]
	 	$("#addchild").parent().remove();
		$("#addprofessional").parent().remove();
		$("#addorganisation").parent().remove();
		$("#addstaff").parent().remove();
		$("#addstatistical").parent().remove();
[% END %]
	    $("#newmenuc").empty();
	    yuiToolbar();
	 });

	// YUI Toolbar Functions

	function yuiToolbar() {

		var newmenu = [
[% IF ( AddPatronLists_categorycode ) %]
[% FOREACH categorie IN categories %]
{ text: "[% categorie.description %]",  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;categorycode=[% categorie.categorycode %]" },
[% END %]
[% ELSE %]
			{ text: _("Adult Member"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=A" },
			{ text: _("Child Member"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=C" },
			{ text: _("Professional Member"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=P" },
			{ text: _("Organisation"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=I" },
			{ text: _("Staff"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=S" },
			{ text: _("Statistical"),  url: "/cgi-bin/koha/members/memberentry.pl?op=add&amp;category_type=X" },
[% END %]
		]

	    new YAHOO.widget.Button({
	        type: "menu",
	        label: _("New"),
	        name: "newmenubutton",
	        menu: newmenu,
	        container: "newmenuc"
	    });

	}

	//]]>
	</script>
 <ul class="toolbar">
 <li id="newmenuc">
 <form action="/cgi-bin/koha/members/memberentry.pl" method="get">
 <input type="hidden" name="op" value="add" />
 <label for="newcategorycode">New Borrower: </label><select name="categorycode" id="newcategorycode">
 [% IF ( AddPatronLists_categorycode ) %] [% FOREACH categorie IN categories %]<option value="[% categorie.categorycode %]">[% categorie.description %]</option>[% END %] [% ELSE %] <option value="A">Adult Member</option>
 <option value="C">Child Member</option>
 <option value="P">Professional Member</option>
 <option value="I">Organisation</option>
 <option value="S">Staff</option>
 <option value="X">Statistical</option>
 [% END %] </select>
 <input type="submit" class="submit" value="Go" />
 </form>
 </li>
</ul>
</div>
[% END %]