if (typeof KOHA == "undefined" || !KOHA) {
    var KOHA = {};
}

/**
 * A namespace for local cover related functions.
 */
KOHA.LocalCover = {


    /**
     * Search all:
     *    <div title="biblionumber" id="isbn" class="openlibrary-thumbnail"></div>
     * or
     *    <div title="biblionumber" id="isbn" class="openlibrary-thumbnail-preview"></div>
     * and run a search with all collected isbns to Open Library Book Search.
     * The result is asynchronously returned by OpenLibrary and catched by
     * olCallBack().
     */
    GetCoverFromBibnumber: function(uselink) {
        $("div[id^=local-thumbnail],span[id^=local-thumbnail]").each(function(i) {
            var mydiv = this;
            var message = document.createElement("span");
            $(message).attr("class","no-image");
            $(message).html(NO_LOCAL_JACKET);
            $(mydiv).append(message);
            var img = $("<img />").attr('src',
                '/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=' + $(mydiv).attr("class"))
                .load(function () {
                    if (!this.complete || typeof this.naturalWidth == "undefined" || this.naturalWidth == 0) {
                        //IE HACK
                        try {
                            $(mydiv).append(img);
                            $(mydiv).children('.no-image').remove();
                        }
                        catch(err){
                        };
                    } else {
                        if (uselink) {
                            var a = $("<a />").attr('href', '/cgi-bin/koha/opac-imageviewer.pl?biblionumber=' + $(mydiv).attr("class"));
                            $(a).append(img);
                            $(mydiv).empty().append(a);
                        } else {
                            $(mydiv).empty().append(img);
                        }
                        $(mydiv).children('.no-image').remove();
                    }
                })
        });
    }
};
