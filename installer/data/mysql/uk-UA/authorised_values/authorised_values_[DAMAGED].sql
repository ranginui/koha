DELETE FROM authorised_values WHERE category='DAMAGED';

INSERT INTO `authorised_values` (category, authorised_value, lib) VALUES 
('DAMAGED','0',''),
('DAMAGED','1','Пошкоджено');
