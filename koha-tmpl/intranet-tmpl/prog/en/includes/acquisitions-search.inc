
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName %]</a></h1><!-- Begin Acquisitions Resident Search Box -->
<div id="header_search">
<div id="supplier_search" class="residentsearch">
	<p class="tip">Search vendors:</p>
        <form name="findsupplier" action="/cgi-bin/koha/acqui/booksellers.pl" method="post">
           <input type="text" size="25" name="supplier" id="supplier" class="focus" />
            <input type="submit" class="submit" value="Submit" /></form>
</div>
	<div id="orders_search" class="residentsearch" style="display:none;">
	<p class="tip">Search orders:</p>
	
		<form action="/cgi-bin/koha/acqui/histsearch.pl" method="post">
		<label for="title">Title: </label><input type="text" id="title" name="title" size="15" value="[% title %]" /> <label for="searchsupplier">Vendor:</label> <input type="text" id="searchsupplier" name="name" size="15" value="[% name|html %]" />
        <span class="filteraction" id="filteraction_off" style="display:none"> <a href="#" onclick="$('#filters').toggle();$('.filteraction').hide();">[-]</a></span>
        <span class="filteraction" id="filteraction_on"> <a href="#" onclick="$('#filters').show();$('.filteraction').toggle();">[+]</a></span>
	<input value="Submit" class="submit" type="submit" /> <a href="/cgi-bin/koha/acqui/histsearch.pl">Advanced Search</a>
    <p id="filters" style="display:none">
      <label for="basket">Basket: </label><input type="text" name="basket" id="basket" />
      <label for="booksellerinvoicenumber">Invoice No.: </label><input type="text" name="booksellerinvoicenumber" id="booksellerinvoicenumber" />
    </p>
	</form>
	</div>	
			<ul id="tabtriggers">
			<li><a href="/cgi-bin/koha/acqui/booksellers.pl#supplier_search">Vendor Search</a></li>
			<li><a href="/cgi-bin/koha/acqui/histsearch.pl#orders_search">Orders Search</a></li>
			</ul>	
</div>
<!-- End Acquisitions Resident Search Box -->
