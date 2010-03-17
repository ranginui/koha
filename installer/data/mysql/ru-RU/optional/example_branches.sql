TRUNCATE branches;
TRUNCATE branchcategories;
TRUNCATE branchrelations;

INSERT INTO `branches` (`branchcode`, `branchname`, `branchaddress1`, `branchaddress2`, `branchaddress3`, `branchphone`, `branchfax`, `branchemail`, `issuing`, `branchip`, `branchprinter`) VALUES
('AB',   'Абонемент', 
             'Украина', 'г. Тернополь', 'кабинет 53 (2-ой этаж)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('ABH',  'Абонемент художественной литературы', 
             'Украина', 'г. Тернополь', 'кабинет 53 (2-ой этаж)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('CHZ',  'Читательский зал', 
             'Украина', 'г. Тернополь', 'кабинет 58 (3-ий этаж)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('CHZP', 'Читательский зал периодики, каталог', 
             'Украина', 'г. Тернополь', 'кабинет 2 (1-ый этаж)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('ECHZ', 'Электронный читательский зал',
             'Украина', 'г. Тернополь', 'кабинет 54 (2-ой этаж)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('LNSL', 'Львовская национальная научная библиотека им. В.Стефаника НАНУ', 
             'Украина', 'г. Львов', 'ул. Стефаника 2', '8 (032) 272-45-36', '', 'library@library.lviv.ua', NULL, '', NULL),
('STL',  'Научно-техническая библиотека Тернопольского государственного техниеского университета им. Ив Пулюя', 
             'Украина', 'м. Тернопіль', 'ул. Руська 56, кабинет 5 (второй корпус)', '8 (0352) 52-53-45', '', 'lib@tu.edu.te.ua', NULL, '', NULL),
('NPLU', 'Национальная парламентская библиотека Украины', 
             'Украина', 'г. Киев', 'ул. Грушевского, 1', '38 (044) 278-85-12', '38 (044) 278-85-12', 'office@nplu.org', NULL, '192.168.1.*', NULL);

INSERT INTO `branchcategories` (`categorycode`, `categoryname`, `codedescription`, `categorytype`) VALUES
('HOME',   'Дом',                        'Может устанавливаться как домашняя библиотека', 'properties'),
('ISSUE',  'Книговыдача',                'Может выдавать книги',                          'properties'),
('NATIOS', 'Национальные библиотеки',    'Поисковая область национальных библиотек',      'searchdomain'),
('PUBLS',  'Публичные библиотеки',       'Поисковая область публичных библиотек',         'searchdomain'),
('UNIVS',  'Университетские библиотеки', 'Поисковая область университетских библиотек',   'searchdomain');

INSERT INTO `branchrelations` (`branchcode`, `categorycode`) VALUES
('AB',   'ISSUE'),
('ABH',  'ISSUE'),
('LNSL', 'HOME'),
('LNSL', 'NATIOS'),
('NPLU', 'HOME'),
('NPLU', 'NATIOS'),
('STL',  'HOME'),
('STL',  'UNIVS');
