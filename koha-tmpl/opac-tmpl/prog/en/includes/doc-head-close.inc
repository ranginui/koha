</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="generator" content="Koha [% Version %]" /> <!-- leave this for stats -->
<link rel="shortcut icon" href="[% themelang %]/includes/favicon.ico" type="image/x-icon" />
[% IF opacstylesheet %]
<link rel="stylesheet" type="text/css" href="[% opacstylesheet %]" />
[% ELSIF opaclayoutstylesheet %]
<link rel="stylesheet" type="text/css" href="[% themelang %]/css/[% opaclayoutstylesheet %]" />
[% ELSE %]
<link rel="stylesheet" type="text/css" href="[% themelang %]/css/opac.css" />
[% END %]

[% IF opaccolorstylesheet %]
<link rel="stylesheet" type="text/css" href="[% themelang %]/css/[% opaccolorstylesheet %]" />
[% END %]
<link rel="stylesheet" type="text/css" media="print" href="[% themelang %]/css/print.css" />
<link rel="stylesheet" type="text/css" href="[% themelang %]/lib/jquery/plugins/ui.tabs.css" />
[% IF OPACUserCSS %]
<style type="text/css">[% OPACUserCSS %]</style>
[% END %]
<!-- yui js --> 
<script type="text/javascript" src="[% yuipath %]/utilities/utilities.js"></script> 
<script type="text/javascript" src="[% yuipath %]/container/container-min.js"></script> 
<script type="text/javascript" src="[% yuipath %]/menu/menu-min.js"></script> 
<script type="text/javascript" src="[% themelang %]/lib/jquery/jquery.js"></script>
<script type="text/javascript" src="[% themelang %]/lib/jquery/plugins/ui.tabs.js"></script>
<script type="text/javascript" src="[% themelang %]/lib/jquery/plugins/jquery.dimensions-min.js"></script>
<script type="text/javascript" src="[% themelang %]/lib/jquery/plugins/jquery.hoverIntent.minified.js"></script>
<script type="text/javascript" src="[% themelang %]/lib/jquery/plugins/jquery.dropshadow-min.js"></script>
<script type="text/javascript" language="javascript" src="[% themelang %]/js/script.js"></script>
[% IF OPACAmazonCoverImages %]
<script type="text/javascript" language="javascript">//<![CDATA[
		var NO_AMAZON_IMAGE = _("No cover image available");
	//]]>
</script>
<script type="text/javascript" language="javascript" src="[% themelang %]/js/amazonimages.js"></script>
[% END %]
[% IF SyndeticsCoverImages %]
<script type="text/javascript" language="javascript">//<![CDATA[
        var NO_AMAZON_IMAGE = _("No cover image available");
    //]]>
</script>
<script type="text/javascript" language="javascript" src="[% themelang %]/js/amazonimages.js"></script>
[% END %]
<script type="text/javascript" language="javascript"
[% IF opacbookbag %]
src="[% themelang %]/js/basket.js">
[% ELSIF virtualshelves %]
src="[% themelang %]/js/basket.js">
[% ELSE %]
>var readCookie;
[% END %]
</script>
[% IF TagsEnabled %]
<script type="text/javascript" language="javascript" src="[% themelang %]/js/tags.js"></script>
[% END %]
<script type="text/javascript" language="javascript">
	//<![CDATA[
    [% IF opacbookbag %]var MSG_BASKET_EMPTY = _("Your cart is currently empty");
    var MSG_RECORD_IN_BASKET = _("This item is already in your cart");
    var MSG_RECORD_ADDED = _("This item has been added to your cart");
    var MSG_NRECORDS_ADDED = _(" item(s) added to your cart");
    var MSG_NRECORDS_IN_BASKET = _("already in your cart");
    var MSG_NO_RECORD_SELECTED = _("No item was selected");
    var MSG_NO_RECORD_ADDED = _("No item was added to your cart");
    var MSG_CONFIRM_DEL_BASKET = _("Are you sure you want to empty your cart?");
    var MSG_CONFIRM_DEL_RECORDS = _("Are you sure you want to remove the selected items?");
	$("#cartDetails").ready(function(){ $("#cmspan").html("<a href=\"#\" id=\"cartmenulink\" class=\"\"><i></i><span><i></i><span></span><img src=\"/opac-tmpl/prog/images/cart.gif\" width=\"14\" height=\"14\" alt=\"\" border=\"0\" /> "+_("Cart")+"<span id=\"basketcount\"></span></span></a>"); }); [% END %]
	[% IF OPACAmazonCoverImages %]$(window).load(function() {
		 	verify_images();
		 });[% END %]
	[% IF SyndeticsCoverImages %]$(window).load(function() {
            verify_images();
         });[% END %]
	[% IF opacuserjs %][% opacuserjs %][% END %]
	//]]>
</script><script type="text/javascript" language="javascript"
[% IF opacbookbag %]src="[% themelang %]/js/basket.js">[% ELSIF virtualshelves %]src="[% themelang %]/js/basket.js">[% ELSE %]>var readCookie;[% END %]</script>
[% IF TagsEnabled %]<script type="text/javascript" language="javascript" src="[% themelang %]/js/tags.js"></script>[% END %]
[% IF GoogleJackets %]
<script type="text/javascript" language="javascript" src="[% themelang %]/js/google-jackets.js"></script>
<script type="text/javascript" language="javascript">
	//<![CDATA[
	var NO_GOOGLE_JACKET = _("No cover image available");
	//]]>
</script>
[% END %]
[% IF BakerTaylorEnabled %]<script type="text/javascript" language="javascript" src="[% themelang %]/js/bakertaylorimages.js"></script>
<script type="text/javascript" language="javascript">
	//<![CDATA[
	var NO_BAKERTAYLOR_IMAGE = _("No cover image available");
	$(window).load(function(){
		bt_verify_images();
	});
	//]]>
</script>[% END %]
<link rel="unapi-server" type="application/xml" title="unAPI" href="[% OPACBaseURL %]/cgi-bin/koha/unapi" />
