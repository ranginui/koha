<!-- TMPL_IF NAME="reserves_waiting" -->
<!-- TMPL_LOOP NAME="reserves_waiting" -->
	<div class="dialog message" id="reserve<!-- TMPL_VAR NAME="biblionumber" -->">
	  <h3>Hold Found: <a href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=<!-- TMPL_VAR NAME="biblionumber" -->"><!-- TMPL_VAR Name="title" escape="html" --></a></h3>
        <!-- TMPL_IF NAME="reservenotes" --><h4>Notes: <!-- TMPL_VAR Name="reservenotes" --></h4><!-- /TMPL_IF -->
        <h5>Hold for:</h5>
		<ul>
            <li><a href="/cgi-bin/koha/members/moremember.pl?borrowernumber=<!-- TMPL_VAR NAME="borrowernumber" -->">
                <!-- TMPL_VAR Name="borsurname" -->, <!-- TMPL_VAR Name="borfirstname" -->
            </a> (<!-- TMPL_VAR Name="borcnum" -->)</li>
            <li><!-- TMPL_VAR Name="boraddress" --><br />
			<!-- TMPL_IF NAME="boraddress2" --><!-- TMPL_VAR NAME="boraddress2" --><br /><!-- /TMPL_IF -->
			<!-- TMPL_VAR Name="borcity" --> <!-- TMPL_VAR NAME="borzip" --></li>
            <!-- TMPL_IF NAME="borphone" --><li><!-- TMPL_VAR Name="borphone" --></li><!-- /TMPL_IF -->
            <!-- TMPL_IF NAME="boremail" --><li><!-- TMPL_IF name="transfertodo" --><!-- TMPL_VAR NAME="boremail" --><!-- TMPL_ELSE --><a id="boremail" href="mailto:<!-- TMPL_VAR NAME="boremail" -->"><!-- TMPL_VAR NAME="boremail" --></a><!-- /TMPL_IF --></li><!-- /TMPL_IF -->
<!-- TMPL_IF NAME="debarred" --><li class="error">Patron is RESTRICTED</li><!-- /TMPL_IF -->
<!-- TMPL_IF NAME="gonenoaddress" --><li class="error">Patron's address is in doubt</li><!-- /TMPL_IF -->
        </ul>
        <!-- TMPL_IF name="transfertodo" -->
            <h4><strong>Transfer to:</strong> <!-- TMPL_VAR Name="destbranchname" --></h4>
		<!-- TMPL_ELSE -->
		<h4><strong>Hold at</strong> <!-- TMPL_VAR Name="destbranchname" --></h4>
        <!-- /TMPL_IF -->
        <form method="post" action="<!-- TMPL_VAR NAME="script_name" -->" class="confirm">
            <!-- TMPL_IF name="transfertodo" -->
		<input type="submit" class="approve" value="Confirm hold and Transfer" />
                <input type="submit" value="Print slip, Transfer, and Confirm" class="print" onclick="Dopop('../circ/hold-transfer-slip.pl?transfer=1&amp;borrowernumber=<!-- TMPL_VAR NAME="borrowernumber" -->&amp;biblionumber=<!-- TMPL_VAR NAME="biblionumber" -->&amp;op=slip'); $('#reserve<!-- TMPL_VAR NAME="biblionumber" -->').hide(); return false;" />
            <!-- TMPL_ELSE -->
		<input type="submit" class="approve" value="Confirm hold" />
                <input type="submit" value="Print Slip and Confirm" class="print" onclick="Dopop('../circ/hold-transfer-slip.pl?borrowernumber=<!-- TMPL_VAR NAME="borrowernumber" -->&amp;biblionumber=<!-- TMPL_VAR NAME="biblionumber" -->&amp;op=slip'); $('#reserve<!-- TMPL_VAR NAME="biblionumber" -->').hide(); return false;" />
            <!-- /TMPL_IF -->
            <input type="hidden" name="itemnumber" value="<!-- TMPL_VAR Name="itemnumber" -->" />
            <input type="hidden" name="borrowernumber" value="<!-- TMPL_VAR Name="circborrowernumber" -->" />
            <input type="hidden" name="resbarcode" value="<!-- TMPL_VAR Name="barcode" -->" />
            <input type="hidden" name="reservenumber" value="<!-- TMPL_VAR Name="reservenumber" -->" />
            <input type="hidden" name="diffBranch" value="<!-- TMPL_VAR Name="destbranch" -->" />
            <input type="hidden" name="exemptfine" value="<!-- TMPL_VAR Name="exemptfine" -->" />
            <input type="hidden" name="dropboxmode" value="<!-- TMPL_VAR Name="dropboxmode" -->" />
        </form>
	</div>
<!--/TMPL_LOOP -->
<!-- /TMPL_IF -->


