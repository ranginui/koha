--
-- System preferences that differ from the global defaults
--
-- This file is part of Koha.
--
-- Koha is free software; you can redistribute it and/or modify it under the
-- terms of the GNU General Public License as published by the Free Software
-- Foundation; either version 2 of the License, or (at your option) any later
-- version.
-- 
-- Koha is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
-- A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with Koha; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

UPDATE systempreferences SET value = 'incremental' WHERE variable = 'autoBarcode';
UPDATE systempreferences SET value = 'surname|cardnumber' WHERE variable = 'BorrowerMandatoryField';
UPDATE systempreferences SET value = 'Господин|Госпожа|Мистер|Миссис|Уважаемый|Уважаемая|Товарищ|Добродий|Добродийка' WHERE variable = 'BorrowersTitles';
UPDATE systempreferences SET value = 'metric' WHERE variable = 'dateformat';
UPDATE systempreferences SET value = 'udc' WHERE variable = 'DefaultClassificationSource';
UPDATE systempreferences SET value = '1' WHERE variable = 'ExtendedPatronAttributes';
UPDATE systempreferences SET value = '0.20' WHERE variable = 'gist';
UPDATE systempreferences SET value = '942hv' WHERE variable = 'itemcallnumber';
UPDATE systempreferences SET value = 'uk-UA,ru-RU,en,fr-FR,de-DE' WHERE variable = 'language';
UPDATE systempreferences SET value = 'uk-UA,ru-RU,en,fr-FR,de-DE' WHERE variable = 'opaclanguages';
UPDATE systempreferences SET value = 'Вітаємо у АБІС Koha...\r\n<hr>' WHERE variable = 'OpacMainUserBlock';
UPDATE systempreferences SET value = 'Тут будуть важливі посилання.' WHERE variable = 'OpacNav';
UPDATE systempreferences SET value = '1' WHERE variable = 'patronimages';

UPDATE systempreferences SET value = '#200|<h2>Заголовок: |{200a}{. 200c}{ : 200e}{200d}{. 200h}{. 200i}|</h2>\r\n#500|<label class="ipt">Уніфікована назва: </label>|{500a}{. 500i}{. 500h}{. 500m}{. 500q}{. 500k}<br/>|\r\n#517|<label class="ipt"> </label>|{517a}{ : 517e}{. 517h}{, 517i}<br/>|\r\n#541|<label class="ipt"> </label>|{541a}{ : 541e}<br/>|\r\n#200||<label class="ipt">Автори: </label><br/>|\r\n#700||<a href="opac-search.pl?op=do_search&marclist=7009&operator==&type=intranet&value={7009}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{700c}{ 700b}{ 700a}{ 700d}{ (700f)}{. 7004}<br/>|\r\n#701||<a href="opac-search.pl?op=do_search&marclist=7009&operator==&type=intranet&value={7019}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{701c}{ 701b}{ 701a}{ 701d}{ (701f)}{. 7014}<br/>|\r\n#702||<a href="opac-search.pl?op=do_search&marclist=7009&operator==&type=intranet&value={7029}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{702c}{ 702b}{ 702a}{ 702d}{ (702f)}{. 7024}<br/>|\r\n#710||<a href="opac-search.pl?op=do_search&marclist=7109&operator==&type=intranet&value={7109}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{710a}{ (710c)}{. 710b}{ : 710d}{ ; 710f}{ ; 710e}<br/>|\r\n#711||<a href="opac-search.pl?op=do_search&marclist=7109&operator==&type=intranet&value={7119}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{711a}{ (711c)}{. 711b}{ : 711d}{ ; 711f}{ ; 711e}<br/>|\r\n#712||<a href="opac-search.pl?op=do_search&marclist=7109&operator==&type=intranet&value={7129}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за автором"></a>{712a}{ (712c)}{. 712b}{ : 712d}{ ; 712f}{ ; 712e}<br/>|\r\n#210|<label class="ipt">Уніфікована форма назви: </label>|{ 210a}<br/>|\r\n#210|<label class="ipt">Видавець: </label>|{ 210c}<br/>|\r\n#210|<label class="ipt">Дата публікації: </label>|{ 210d}<br/>|\r\n#215|<label class="ipt">Фізичний опис: </label>|{215a}{ : 215c}{ ; 215d}{ + 215e}|<br/>\r\n#225|<label class="ipt">Серія:</label>|<a href="opac-search.pl?op=do_search&marclist=225a&operator==&type=intranet&value={225a}"> <img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {225a}"></a>{ (225a}{ = 225d}{ : 225e}{. 225h}{. 225i}{ / 225f}{, 225x}{ ; 225v}|)<br/>\r\n#200||<label class="ipt">Предметні рубрики: </label><br/>|\r\n#600||<a href="opac-search.pl?op=do_search&marclist=6009&operator==&type=intranet&value={6009}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6009}"></a>{ 600c}{ 600b}{ 600a}{ 600d}{ (600f)} {-- 600x }{-- 600z }{-- 600y}<br />|\r\n#604||<a href="opac-search.pl?op=do_search&marclist=6049&operator==&type=intranet&value={6049}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6049}"></a>{ 604a}{. 604t}<br />|\r\n#601||<a href="opac-search.pl?op=do_search&marclist=6019&operator==&type=intranet&value={6019}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6019}"></a>{ 601a}{ (601c)}{. 601b}{ : 601d} { ; 601f}{ ; 601e}{ -- 601x }{-- 601z }{-- 601y}<br />|\r\n#605||<a href="opac-search.pl?op=do_search&marclist=6059&operator==&type=intranet&value={6059}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6059}"></a>{ 605a}{. 605i}{. 605h}{. 605k}{. 605m}{. 605q} {-- 605x }{-- 605z }{-- 605y }{-- 605l}<br />|\r\n#606||<a href="opac-search.pl?op=do_search&marclist=6069&operator==&type=intranet&value={6069}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6069}">xx</a>{ 606a}{-- 606x }{-- 606z }{606y }<br />|\r\n#607||<a href="opac-search.pl?op=do_search&marclist=6079&operator==&type=intranet&value={6079}"><img border="0" src="/opac-tmpl/css/en/images/filefind.png" height="15" title="Пошук за {6079}"></a>{ 607a}{-- 607x}{-- 607z}{-- 607y}<br />|\r\n#010|<label class="ipt">ISBN: </label>|{010a}|<br/>\r\n#011|<label class="ipt">ISSN: </label>|{011a}|<br/>\r\n#200||<label class="ipt">Нотатки: </label>|<br/>\r\n#300||{300a}|<br/>\r\n#320||{320a}|<br/>\r\n#327||{327a}|<br/>\r\n#328||{328a}|<br/>\r\n#200||<br/><h2>Примірники</h2>|\r\n#200|<table>|<th>Місцезнаходження</th><th>Cote</th>|\r\n#995||<tr><td>{995e}&nbsp;&nbsp;</td><td> {995k}</td></tr>|\r\n#200|||</table>' WHERE variable = 'ISBD';

UPDATE systempreferences SET value = "
        'title' => '200a,200c,200d,200e,225a,225d,225e,225f,225h,225i,225v,500*,501*,503*,510*,512*,513*,514*,515*,516*,517*,518*,519*,520*,530*,531*,532*,540*,541*,545*,604t,610t,605a',
        'author' => '200f,600a,601a,604a,700a,700b,700c,700d,700a,701b,701c,701d,702a,702b,702c,702d,710a,710b,710c,710d,711a,711b,711c,711d,712a,712b,712c,712d',
        'se' => '225a',
        'isbn' => '010a',
        'issn' => '011a',
        'biblionumber' => '9999',
        'itemtype' => '200b,942c,952y',
        'language' => '101a',
        'pl' => '210a',
        'publisher' => '210c',
        'date' => '210d',
        'note' => '300a,301a,302a,303a,304a,305a,306az,307a,308a,309a,310a,311a,312a,313a,314a,315a,316a,317a,318a,319a,320a,321a,322a,323a,324a,325a,326a,327a,328a,330a,332a,333a,336a,337a,345a',
        'Koha-Auth-Number' => '6009,6019,6029,6039,6049,6059,6069,6109,7009,7019,7029,7109,7119,7129',
        'subject' => '600*,601*,606*,610*',
        'an' => '6009,6019,6069,6109,6079',
        'su' => '600a,601a,606a,610a,607a,608a',
        'lcn' => '686a,952o',
        'yr' => '210d',
        'mt' => '200b',
        'dewey' => '676a',
        'bc' => '952p',
        'callnum' => '952o',
        'homebranch' => '952a,952c',
        'host-item' => '992b,992c',
        'keyword' => '200*,600*,700*,400*,210*' 
" WHERE variable = 'NoZebraIndexes';
