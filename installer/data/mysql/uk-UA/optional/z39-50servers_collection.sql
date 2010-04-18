TRUNCATE z3950servers;

INSERT INTO `z3950servers` 
(`host`, `port`, `db`, `userid`, `password`, `name`, `id`, `checked`, `rank`, `syntax`, `icon`, `position`, `type`, `encoding`, `description`) VALUES 
('z3950.bnf.fr', 2211, 'TOUT', 'Z3950', 'Z3950_BNF', 'BNF2', 2, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('62.76.8.149', 210, 'books', '', '', 'НАУЧНАЯ БИБЛИОТЕКА БАШКИРСКОГО ГОСУДАРСТВЕННОГО УНИВЕРСИТЕТА', 3, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('81.30.205.34', 210, 'books', '', '', 'НАЦИОНАЛЬНАЯ БИБЛИОТЕКА ИМ. АХМЕТ-ЗАКИ ВАЛИДИ (БД BOOKS)', 4, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('libor.pstu.ru', 210, 'books', '', '', 'ПЕРМСКИЙ ГОСУДАРСТВЕННЫЙ ТЕХНИЧЕСКИЙ УНИВЕРСИТЕТ (БД BOOKS)', 5, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('212.3.135.157', 210, 'books', '', '', 'СМОЛЕНСКАЯ ОБЛАСТНАЯ УНИВЕРСАЛЬНАЯ БИБЛИОТЕКА (БД BOOKS)', 6, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('212.3.135.157', 210, 'books_r', '', '', 'СМОЛЕНСКАЯ ОБЛАСТНАЯ УНИВЕРСАЛЬНАЯ БИБЛИОТЕКА (БД BOOKS_R)', 63, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', ''),
('212.3.135.157', 210, 'soub', '', '', 'СМОЛЕНСКАЯ ОБЛАСТНАЯ УНИВЕРСАЛЬНАЯ БИБЛИОТЕКА (БД SOUB)', 7, 1, 1, 'UNIMARC', NULL, 'primary', 'zed', 'utf8', '');