-- DROP-uri (pentru rerularea codului)
DROP TABLE tranzactii;
DROP TABLE carduri;
DROP TABLE oferte;
DROP TABLE conturi;
DROP TABLE activitati_online;
DROP TABLE clienti;
DROP TABLE adrese;


-- ADRESE
CREATE TABLE `adrese` (
`id_adresa` int NOT NULL,
  	`strada` varchar(40) NOT NULL,
  	`oras` varchar(30) NOT NULL,
  	`tara` enum('AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'NOT_EU') NOT NULL DEFAULT 'RO',
  	PRIMARY KEY (`id_adresa`),
  	UNIQUE KEY `id_adresa_UNIQUE` (`id_adresa`),
	CONSTRAINT `ID_VALID_AD` CHECK (`id_adresa` > 0)
);

-- CLIENTI
CREATE TABLE `clienti` (
	`CNP` varchar(13) NOT NULL,
	`nume` varchar(50) NOT NULL,
	`prenume` varchar(50) NOT NULL,
	`data_nasterii` date NOT NULL,
	`gen` enum('M','F') NOT NULL,
	`email` varchar(55) DEFAULT NULL,
	`nr_tel` varchar(15) NOT NULL,
	`cetatenie` enum('AUT','BEL','BGR','HRV','CYP','CZE','DNK','EST','FIN','FRA','DEU','GRC','HUN','IRL','ITA','LVA','LTU','LUX','MLT','NLD','POL','PRT','ROU','SVK','SVN','ESP','SWE','NOT_EU') DEFAULT 'ROU',
	`id_adresa` int NOT NULL,
	`salariu` int DEFAULT NULL,
	PRIMARY KEY (`CNP`),
	UNIQUE KEY `CNP_UNIQUE` (`CNP`),
	UNIQUE KEY `nr_tel_UNIQUE` (`nr_tel`),
	UNIQUE KEY `email_UNIQUE` (`email`),
	KEY `FK_CLIENT_ADRESA` (`id_adresa`),
	CONSTRAINT `FK_CLIENT_ADRESA` FOREIGN KEY (`id_adresa`) REFERENCES `adrese` (`id_adresa`),
	CONSTRAINT `GEN_VALID_CNP` CHECK (
		case 
			when `cetatenie` <> 'ROU' then 'EXT' 
			when `cetatenie` = 'ROU' then 
				case 
					when substr(`CNP`,1,1) in ('1','5') and upper(`gen`) = 'M' then 'OK'
					when substr(`CNP`,1,1) in ('2','6') and upper(`gen`) = 'F' then 'OK' 
					else 'NO' 
				end
		end in ('OK','EXT')
  ),
	CONSTRAINT `NASTERE_VALIDA_CNP` CHECK (
		case 
			when `cetatenie` <> 'ROU' then 'EXT' 
			when `cetatenie` = 'ROU' then 
				case 
					when substr(`CNP`,2,6) = date_format(`data_nasterii`,'%y%m%d') then 'OK' 
					else 'NO' 
				end
		end in ('OK','EXT')
	),
	CONSTRAINT `NR_TEL_VALID` CHECK (length(`nr_tel`) > 5),
	CONSTRAINT `SALARIU_VALID` CHECK (`salariu` >= 0),
	CONSTRAINT `STRUCTURA_EMAIL_VALIDA` CHECK (`email` like '%@%.%')
);

-- ACTIVITATI_ONLINE
CREATE TABLE `activitati_online` (
	`CNP` varchar(13) NOT NULL,
	`data_login` timestamp NOT NULL,
	`activitate` enum('interogare_sold','contactare_suport','verificare_istoric','schimbare_setari') DEFAULT NULL,
	PRIMARY KEY (`CNP`,`data_login`),
	CONSTRAINT `FK_ACTIVITATI_CLIENT` FOREIGN KEY (`CNP`) REFERENCES `clienti` (`CNP`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- CONTURI
CREATE TABLE `conturi` (
	`IBAN` varchar(34) NOT NULL,
	`moneda_cont` varchar(3) NOT NULL,
	`CNP` varchar(13) NOT NULL,
	PRIMARY KEY (`IBAN`),
	UNIQUE KEY `IBAN_UNIQUE` (`IBAN`),
	KEY `fk_cont_client_ind` (`CNP`),
	CONSTRAINT `FK_CONT_CLIENT` FOREIGN KEY (`CNP`) REFERENCES `clienti` (`CNP`) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT `MYBANK_IBAN` CHECK (substr(`IBAN`,5,4) = 'MBNK' and substr(`IBAN`,1,2) = 'RO')
);

-- OFERTE
CREATE TABLE `oferte` (
	`id_oferta` int NOT NULL,
	`nume_oferta` varchar(30) NOT NULL,
	`rata_dobanda` decimal(4,2) DEFAULT '0.00',
	PRIMARY KEY (`id_oferta`),
	UNIQUE KEY `id_oferta_UNIQUE` (`id_oferta`),
	UNIQUE KEY `nume_oferta_UNIQUE` (`nume_oferta`),
	CONSTRAINT `DOBANDA_VALIDA` CHECK (`rata_dobanda` >= 0 and `rata_dobanda` <= 20),
	CONSTRAINT `ID_VALID_OF` CHECK (`id_oferta` > 0)
);

-- CARDURI
CREATE TABLE `carduri` (
	`id_card` int NOT NULL,
	`id_oferta` int NOT NULL,
	`cod_card` varchar(16) NOT NULL,
	`tip_card` enum('debit','credit') NOT NULL,
	`IBAN` varchar(34) NOT NULL,
	PRIMARY KEY (`id_card`),
	UNIQUE KEY `cod_card_UNIQUE` (`cod_card`),
	KEY `FK_CARD_CONT` (`IBAN`),
	KEY `FK_CARD_OFERTA` (`id_oferta`),
	CONSTRAINT `FK_CARD_CONT` FOREIGN KEY (`IBAN`) REFERENCES `conturi` (`IBAN`) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT `FK_CARD_OFERTA` FOREIGN KEY (`id_oferta`) REFERENCES `oferte` (`id_oferta`),
	CONSTRAINT `CARD_CODE_LENGTH` CHECK (char_length(`cod_card`) = 16),
	CONSTRAINT `ID_CARD_VALID` CHECK (`id_card` > 0)
);

-- TRANZACTII
CREATE TABLE `tranzactii` (
	`id_tranzactie` int NOT NULL,
	`iban_expeditor` varchar(34) NOT NULL,
	`iban_destinatar` varchar(34) NOT NULL,
	`data_transfer` timestamp NOT NULL,
	`cantitate` int NOT NULL,
	`moneda_transfer` varchar(3) NOT NULL,
	PRIMARY KEY (`id_tranzactie`),
	KEY `FK_CONT_DESTINATAR` (`iban_destinatar`),
	KEY `FK_CONT_EXPEDITOR` (`iban_expeditor`),
	CONSTRAINT `FK_CONT_DESTINATAR` FOREIGN KEY (`iban_destinatar`) REFERENCES `conturi` (`IBAN`),
	CONSTRAINT `FK_CONT_EXPEDITOR` FOREIGN KEY (`iban_expeditor`) REFERENCES `conturi` (`IBAN`),
	CONSTRAINT `CANTITATE_VALIDA` CHECK ((`cantitate` > 0)),
	CONSTRAINT `DIFF_IBAN` CHECK (strcmp(`iban_expeditor`,`iban_destinatar`) <> 0),
	CONSTRAINT `ID_VALID_TRANZ` CHECK (`id_tranzactie` > 0)
);

-- ADRESE - inserare

INSERT INTO ADRESE VALUES(1, "Piscotului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(2, "Fabricii", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(3, "Apeductului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(4, "Orsova", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(5, "Dezrobirii", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(6, "Cernisoara", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(7, "Padureni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(8, "Constructorilor", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(9, "Fratilor", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(10, "9 Mai", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(11, "Lucacesti", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(12, "Calea Plevnei", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(13, "Macedonia", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(14, "Lipova", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(15, "Crisana", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(16, "Transilvaniei", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(17, "Theodor Aman", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(18, "Buzoieni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(19, "Crizantemelor", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(20, "Raureni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(21, "Cutitul de Argint", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(22, "Cornetului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(23, "Anton Colorian", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(24, "Radului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(25, "Alunisului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(26, "Rezonantei", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(27, "Paduroiu", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(28, "Negureni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(29, "Esarfei", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(30, "Gradinarilor", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(31, "Calugareni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(32, "Calea Vitan", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(33, "Vlad Dracul", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(34, "Panait Cerna", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(35, "Anton Pann", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(36, "Barajul Cucuteni", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(37, "Maior Ion Coravu", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(38, "Iezerului", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(39, "Patriei", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(40, "Fortunei", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(41, "Negru Voda", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(42, "Zefirului", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(43, "Miron Costin", "Ploiesti", "RO");
INSERT INTO ADRESE VALUES(44, "Gabriel Popescu", "Targoviste", "RO");
INSERT INTO ADRESE VALUES(45, "Radu cel Mare", "Targoviste", "RO");
INSERT INTO ADRESE VALUES(46, "Egalitatii", "Pitesti", "RO");
INSERT INTO ADRESE VALUES(47, "Dealurilor", "Pitesti", "RO");
INSERT INTO ADRESE VALUES(48, "Stadionului", "Pitesti", "RO");
INSERT INTO ADRESE VALUES(49, "Petuniilor", "Craiova", "RO");
INSERT INTO ADRESE VALUES(50, "Campia Islaz", "Craiova", "RO");
INSERT INTO ADRESE VALUES(51, "Brazda lui Novac", "Craiova", "RO");
INSERT INTO ADRESE VALUES(52, "Vulturi", "Craiova", "RO");
INSERT INTO ADRESE VALUES(53, "Rampei", "Craiova", "RO");
INSERT INTO ADRESE VALUES(54, "Tehnicii", "Craiova", "RO");
INSERT INTO ADRESE VALUES(55, "Teilor", "Calafat", "RO");
INSERT INTO ADRESE VALUES(56, "Traian", "Targu Jiu", "RO");
INSERT INTO ADRESE VALUES(57, "Bradului", "Targu Jiu", "RO");
INSERT INTO ADRESE VALUES(58, "Dealul de Jos", "Brasov", "RO");
INSERT INTO ADRESE VALUES(59, "Dealul Cetatii", "Brasov", "RO");
INSERT INTO ADRESE VALUES(60, "Sitei", "Brasov", "RO");
INSERT INTO ADRESE VALUES(61, "Nicopole", "Brasov", "RO");
INSERT INTO ADRESE VALUES(62, "Grigore Ureche", "Brasov", "RO");
INSERT INTO ADRESE VALUES(63, "Aluminiului", "Brasov", "RO");
INSERT INTO ADRESE VALUES(64, "Metalurgistilor", "Brasov", "RO");
INSERT INTO ADRESE VALUES(65, "Turnului", "Brasov", "RO");
INSERT INTO ADRESE VALUES(66, "Alexandru Sahia", "Brasov", "RO");
INSERT INTO ADRESE VALUES(67, "Carpatilor", "Brasov", "RO");
INSERT INTO ADRESE VALUES(68, "Pictor Pop", "Brasov", "RO");
INSERT INTO ADRESE VALUES(69, "Lunga", "Brasov", "RO");
INSERT INTO ADRESE VALUES(70, "Moldovei", "Sibiu", "RO");
INSERT INTO ADRESE VALUES(71, "Dealului", "Sibiu", "RO");
INSERT INTO ADRESE VALUES(72, "Turismului", "Sibiu", "RO");
INSERT INTO ADRESE VALUES(73, "Romanilor", "Deva", "RO");
INSERT INTO ADRESE VALUES(74, "Armatei", "Deva", "RO");
INSERT INTO ADRESE VALUES(75, "13 Decembrie", "Brasov", "RO");
INSERT INTO ADRESE VALUES(76, "Maslinului", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(77, "Madona", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(78, "Tibrului", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(79, "Balta Verde", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(80, "Dinu Lipatti", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(81, "Franyo Zoltan", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(82, "Nera", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(83, "Martirilor", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(84, "Herculane", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(85, "Eroilor de la Tisa", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(86, "Daliei", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(87, "Octavian Iosif", "Timisoara", "RO");
INSERT INTO ADRESE VALUES(88, "Clujului", "Arad", "RO");
INSERT INTO ADRESE VALUES(89, "Bulevardul Revolutiei", "Arad", "RO");
INSERT INTO ADRESE VALUES(90, "Udrea", "Arad", "RO");
INSERT INTO ADRESE VALUES(91, "Nufarului", "Oradea", "RO");
INSERT INTO ADRESE VALUES(92, "Horea", "Oradea", "RO");
INSERT INTO ADRESE VALUES(93, "Viilor", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(94, "Pajistei", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(95, "Iosif Vulcan", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(96, "Gorunului", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(97, "Crinului", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(98, "Timisului", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(99, "Take Ionescu", "Cluj-Napoca", "RO");
INSERT INTO ADRESE VALUES(100, "Zaharia Boiu", "Sighisoara", "RO");
INSERT INTO ADRESE VALUES(101, "Teilor", "Sighisoara", "RO");
INSERT INTO ADRESE VALUES(102, "Anghel Saligny", "Galati", "RO");
INSERT INTO ADRESE VALUES(103, "Fagului", "Galati", "RO");
INSERT INTO ADRESE VALUES(104, "Slanic", "Galati", "RO");
INSERT INTO ADRESE VALUES(105, "Tineretului", "Braila", "RO");
INSERT INTO ADRESE VALUES(106, "Cutezatorilor", "Braila", "RO");
INSERT INTO ADRESE VALUES(107, "Rahovei", "Braila", "RO");
INSERT INTO ADRESE VALUES(108, "Bucuresti", "Calarasi", "RO");
INSERT INTO ADRESE VALUES(109, "Cumpenei", "Constanta", "RO");
INSERT INTO ADRESE VALUES(110, "Petre Liciu", "Constanta", "RO");
INSERT INTO ADRESE VALUES(111, "Eliberarii", "Constanta", "RO");
INSERT INTO ADRESE VALUES(112, "Dorului", "Constanta", "RO");
INSERT INTO ADRESE VALUES(113, "Frunzelor", "Constanta", "RO");
INSERT INTO ADRESE VALUES(114, "Rosmarin", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(115, "Eternitatii", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(116, "Lavandei", "Targu Mures", "RO");
INSERT INTO ADRESE VALUES(117, "Halmi", "Budapesta", "HU");
INSERT INTO ADRESE VALUES(118, "Maryli", "Gdansk", "PL");
INSERT INTO ADRESE VALUES(119, "Simonet", "Paris", "FR");
INSERT INTO ADRESE VALUES(120, "Gramme", "Paris", "FR");
INSERT INTO ADRESE VALUES(121, "de Suzon", "Bordeaux", "FR");
INSERT INTO ADRESE VALUES(122, "Otechestvo", "Sofia", "BG");
INSERT INTO ADRESE VALUES(123, "Nikolaevska", "Ruse", "BG");
INSERT INTO ADRESE VALUES(124, "Klitias", "Atena", "GR");
INSERT INTO ADRESE VALUES(125, "Vetulonia", "Roma", "IT");
INSERT INTO ADRESE VALUES(126, "Mackensem", "Regensburg", "DE");
INSERT INTO ADRESE VALUES(127, "Gottfried-Keller", "Frankfurt", "DE");
INSERT INTO ADRESE VALUES(128, "Norra Hyllievagen", "Malmo", "SE");
INSERT INTO ADRESE VALUES(129, "Vytauto", "Kaunas", "LT");
INSERT INTO ADRESE VALUES(130, "Udolni", "Brno", "CZ");
INSERT INTO ADRESE VALUES(131, "Bujorului", "Satu Mare", "RO");
INSERT INTO ADRESE VALUES(132, "Clujului", "Satu Mare", "RO");
INSERT INTO ADRESE VALUES(133, "Crinului", "Satu Mare", "RO");
INSERT INTO ADRESE VALUES(134, "Dobrogei", "Baia Mare", "RO");
INSERT INTO ADRESE VALUES(135, "Matei Basarab", "Baia Mare", "RO");
INSERT INTO ADRESE VALUES(136, "Moldovei", "Baia Mare", "RO");
INSERT INTO ADRESE VALUES(137, "13 Decembrie", "Baia Mare", "RO");
INSERT INTO ADRESE VALUES(138, "Nisiparilor", "Baia Mare", "RO");
INSERT INTO ADRESE VALUES(139, "Pacii", "Vatra Dornei", "RO");
INSERT INTO ADRESE VALUES(140, "Dornelor", "Vatra Dornei", "RO");
INSERT INTO ADRESE VALUES(141, "Sondei", "Vatra Dornei", "RO");
INSERT INTO ADRESE VALUES(142, "Izvorului", "Vatra Dornei", "RO");
INSERT INTO ADRESE VALUES(143, "Daciei", "Radauti", "RO");
INSERT INTO ADRESE VALUES(144, "Armeneasca", "Suceava", "RO");
INSERT INTO ADRESE VALUES(145, "Zimbrului", "Suceava", "RO");
INSERT INTO ADRESE VALUES(146, "Zorilor", "Suceava", "RO");
INSERT INTO ADRESE VALUES(147, "Trandafirilor", "Botosani", "RO");
INSERT INTO ADRESE VALUES(148, "Rapsodiei", "Botosani", "RO");
INSERT INTO ADRESE VALUES(149, "Postei", "Dorohoi", "RO");
INSERT INTO ADRESE VALUES(150, "Strugurilor", "Iasi", "RO");
INSERT INTO ADRESE VALUES(151, "Miroslava", "Iasi", "RO");
INSERT INTO ADRESE VALUES(152, "Bistrita", "Iasi", "RO");
INSERT INTO ADRESE VALUES(153, "Florilor", "Iasi", "RO");
INSERT INTO ADRESE VALUES(154, "Garii", "Iasi", "RO");
INSERT INTO ADRESE VALUES(155, "Palat", "Iasi", "RO");
INSERT INTO ADRESE VALUES(156, "Melodiei", "Iasi", "RO");
INSERT INTO ADRESE VALUES(157, "Zimbrului", "Iasi", "RO");
INSERT INTO ADRESE VALUES(158, "Primaverii", "Iasi", "RO");
INSERT INTO ADRESE VALUES(159, "Gradinari", "Iasi", "RO");
INSERT INTO ADRESE VALUES(160, "Stejar", "Iasi", "RO");
INSERT INTO ADRESE VALUES(161, "Soimului", "Bacau", "RO");
INSERT INTO ADRESE VALUES(162, "Ghioceilor", "Bacau", "RO");
INSERT INTO ADRESE VALUES(163, "Stadionului", "Bacau", "RO");
INSERT INTO ADRESE VALUES(164, "Calugareni", "Vaslui", "RO");
INSERT INTO ADRESE VALUES(165, "Tineretului", "Onesti", "RO");
INSERT INTO ADRESE VALUES(166, "Bartok Bela", "Covasna", "RO");
INSERT INTO ADRESE VALUES(167, "Bucegi", "Focsani", "RO");
INSERT INTO ADRESE VALUES(168, "Culturii", "Focsani", "RO");
INSERT INTO ADRESE VALUES(169, "Constructorilor", "Slobozia", "RO");
INSERT INTO ADRESE VALUES(170, "Unirii", "Cernavoda", "RO");
INSERT INTO ADRESE VALUES(171, "Traian", "Medgidia", "RO");
INSERT INTO ADRESE VALUES(172, "Siretului", "Medgidia", "RO");
INSERT INTO ADRESE VALUES(173, "Oituz", "Mangalia", "RO");
INSERT INTO ADRESE VALUES(174, "Banatului", "Mangalia", "RO");
INSERT INTO ADRESE VALUES(175, "Albatros", "Vama Veche", "RO");
INSERT INTO ADRESE VALUES(176, "Armeros", "Toledo", "ES");
INSERT INTO ADRESE VALUES(177, "Buenavista", "Toledo", "ES");
INSERT INTO ADRESE VALUES(178, "de Montesa", "Valencia", "ES");
INSERT INTO ADRESE VALUES(179, "Padre Cruz", "Braga", "PT");
INSERT INTO ADRESE VALUES(180, "Santa Sofia", "Milano", "IT");
INSERT INTO ADRESE VALUES(181, "Carlo Goldoni", "Milano", "IT");
INSERT INTO ADRESE VALUES(182, "Adda", "Milano", "IT");
INSERT INTO ADRESE VALUES(183, "Veglia", "Torino", "IT");
INSERT INTO ADRESE VALUES(184, "Heimweg", "Hamburg", "DE");
INSERT INTO ADRESE VALUES(185, "Nonnestieg", "Hamburg", "DE");
INSERT INTO ADRESE VALUES(186, "Sinkulova", "Praga", "CZ");
INSERT INTO ADRESE VALUES(187, "Podolska", "Praga", "CZ");
INSERT INTO ADRESE VALUES(188, "Baranova", "Praga", "CZ");
INSERT INTO ADRESE VALUES(189, "Slovenska", "Zlin", "CZ");
INSERT INTO ADRESE VALUES(190, "Sokolska", "Katowice", "PL");
INSERT INTO ADRESE VALUES(191, "Ranikivi", "Tartu", "EE");
INSERT INTO ADRESE VALUES(192, "Istarska", "Split", "HR");
INSERT INTO ADRESE VALUES(193, "Sutlanska", "Zagreb", "HR");
INSERT INTO ADRESE VALUES(194, "Krapinska", "Zagreb", "HR");
INSERT INTO ADRESE VALUES(195, "Slinge", "Rotterdam", "NL");
INSERT INTO ADRESE VALUES(196, "du Port", "Charleroi", "BE");
INSERT INTO ADRESE VALUES(197, "Lamartine", "Lille", "FR");
INSERT INTO ADRESE VALUES(198, "Gresset", "Nantes", "FR");
INSERT INTO ADRESE VALUES(199, "Bonne Louise", "Paris", "FR");
INSERT INTO ADRESE VALUES(200, "Jules Vernes", "Paris", "FR");
INSERT INTO ADRESE VALUES(201, "Kohutova", "Bratislava", "SK");
INSERT INTO ADRESE VALUES(202, "Sabarului", "Jilava", "RO");
INSERT INTO ADRESE VALUES(203, "Colonel Pop", "Caracal", "RO");
INSERT INTO ADRESE VALUES(204, "Libertatii", "Slatina", "RO");
INSERT INTO ADRESE VALUES(205, "Victoriei", "Targu Jiu", "RO");
INSERT INTO ADRESE VALUES(206, "Narciselor", "Targu Jiu", "RO");
INSERT INTO ADRESE VALUES(207, "Flacara", "Calarasi", "RO");
INSERT INTO ADRESE VALUES(208, "Luceafarului", "Calarasi", "RO");
INSERT INTO ADRESE VALUES(209, "Podgoriilor", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(210, "Isaccei", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(211, "Gloriei", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(212, "Sabinelor", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(213, "Babadag", "Tulcea", "RO");
INSERT INTO ADRESE VALUES(214, "Musetelului", "Calarasi", "RO");
INSERT INTO ADRESE VALUES(215, "Valea Ialomitei", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(216, "Azurului", "Bucuresti", "RO");
INSERT INTO ADRESE VALUES(217, "Bartok Bela", "Budapesta", "HU");
INSERT INTO ADRESE VALUES(218, "Vorosmarty", "Budapesta", "HU");
INSERT INTO ADRESE VALUES(219, "Vezer", "Budapesta", "HU");
INSERT INTO ADRESE VALUES(220, "Petofi Sandor", "Pecs", "HU");
INSERT INTO ADRESE VALUES(221, "Petrova", "Zagreb", "HR");
INSERT INTO ADRESE VALUES(222, "Atanas Dukov", "Sofia", "BG");
INSERT INTO ADRESE VALUES(223, "Tulcha", "Sofia", "BG");
INSERT INTO ADRESE VALUES(224, "Kanaki", "Salonic", "GR");
INSERT INTO ADRESE VALUES(225, "Diagonal", "Barcelona", "ES");
INSERT INTO ADRESE VALUES(226, "Augusta", "Barcelona", "ES");
INSERT INTO ADRESE VALUES(227, "Beethoven", "Linz", "AT");
INSERT INTO ADRESE VALUES(228, "Muzejna", "Bratislava", "SK");

-- CLIENTI - inserare

INSERT INTO CLIENTI VALUES("0014FE91", "Somogyi", "Andras", "1998-11-22", "M", "somogyi.andras98@outlook.com", "0701748161", "HUN", 220, 16000);
INSERT INTO CLIENTI VALUES("0045AD83", "Racz", "Agnes", "1970-12-24", "F", NULL, "0301458781", "HUN", 117, 8100);
INSERT INTO CLIENTI VALUES("0086GD50", "Halasz", "Janos", "1989-10-12", "M", "halasz89.janos@outlook.com", "0709748134", "HUN", 217, 13000);
INSERT INTO CLIENTI VALUES("1400419277224", "Cojoc", "Ionut", "1940-04-19", "M", "ionut.cojoc@gmail.com", "0706261541", "ROU", 116, NULL);
INSERT INTO CLIENTI VALUES("1480428126141", "Codreanu", "Aurel", "1948-04-28", "M", NULL, "0796275560", "ROU", 6, NULL);
INSERT INTO CLIENTI VALUES("1501015096000", "Ilie", "David", "1950-10-15", "M", NULL, "0748121390", "ROU", 3, NULL);
INSERT INTO CLIENTI VALUES("1531001485753", "Barbu", "Anton", "1953-10-01", "M", NULL, "0745076142", "ROU", 158, NULL);
INSERT INTO CLIENTI VALUES("1550610118834", "Stancu", "Adrian", "1955-06-10", "M", "stancu.adrian@outlook.com", "0712286337", "ROU", 161, 13000);
INSERT INTO CLIENTI VALUES("1560921463023", "Petrescu", "Nicolae", "1956-09-21", "M", NULL, "0707257484", "ROU", 20, 10000);
INSERT INTO CLIENTI VALUES("1570723281056", "Miron", "Gheorghe", "1957-07-23", "M", NULL, "0704842311", "ROU", 168, NULL);
INSERT INTO CLIENTI VALUES("1580901072122", "Cosma", "Horia", "1958-09-01", "M", "cosma.horia@yahoo.com", "0784603737", "ROU", 123, 17800);
INSERT INTO CLIENTI VALUES("1590225261442", "Tanase", "Beniamin", "1959-02-25", "M", NULL, "0784432873", "ROU", 78, NULL);
INSERT INTO CLIENTI VALUES("1610929305189", "Stanescu", "Lucian", "1961-09-29", "M", NULL, "0707153315", "ROU", 170, NULL);
INSERT INTO CLIENTI VALUES("1620414516332", "Pasztor", "Andras", "1962-04-14", "M", NULL, "0770206046", "ROU", 17, NULL);
INSERT INTO CLIENTI VALUES("1650410221867", "Popovici", "Radu", "1965-04-10", "M", NULL, "0713778770", "ROU", 209, NULL);
INSERT INTO CLIENTI VALUES("1651017469726", "Bogza", "Claudiu", "1965-10-17", "M", NULL, "0732115484 ", "ROU", 76, 13700);
INSERT INTO CLIENTI VALUES("1690612392587", "Puscas", "Vasile", "1969-06-12", "M", "vasile.puscas@outlook.com", "0795761762", "ROU", 107, 16100);
INSERT INTO CLIENTI VALUES("1710303474924", "Ilie", "Claudiu", "1971-03-03", "M", "claudiu.ilie@yahoo.com", "0775263687", "ROU", 47, 17000);
INSERT INTO CLIENTI VALUES("1720112113128", "Ilie", "Catalin", "1972-01-12", "M", "catalin.ilie1972@outlook.com", "0785820128", "ROU", 12, 7600);
INSERT INTO CLIENTI VALUES("1720830019023", "Cazacu", "Mihai", "1972-08-30", "M", "mihaicazacu@gmail.com", "0745457006", "ROU", 169, 8200);
INSERT INTO CLIENTI VALUES("1730506181852", "Banu", "Costin", "1973-05-06", "M", NULL, "0763424027", "ROU", 14, 8500);
INSERT INTO CLIENTI VALUES("174780184F", "Paez", "Adara", "1994-02-16", "F", "adarapaez94@gmail.com", "0720498194", "ESP", 226, 12000);
INSERT INTO CLIENTI VALUES("1750426262233", "Tanase", "Miron", "1975-04-26", "M", "miron.tanase@outlook.com", "0733335957", "ROU", 3, 3600);
INSERT INTO CLIENTI VALUES("175810949D", "Lerida", "Alfonso", "2000-03-06", "M", NULL, "0729011857", "ESP", 178, 0);
INSERT INTO CLIENTI VALUES("1760607290263", "Costache", "Iosif", "1976-06-07", "M", "iosif.costache76@gmail.com", "0710147801", "ROU", 32, 6400);
INSERT INTO CLIENTI VALUES("1761213049185", "Vieru", "Mircea", "1976-12-13", "M", "vierumircea@gmail.com", "0775582881", "ROU", 119, 4500);
INSERT INTO CLIENTI VALUES("1770609255111", "Florea", "Sorin", "1977-06-09", "M", NULL, "0772253851", "ROU", 130, 7300);
INSERT INTO CLIENTI VALUES("1771216220833", "Fieraru", "Remus", "1977-12-16", "M", "fieraru.remus@outlook.com", "0767450827", "ROU", 88, 10100);
INSERT INTO CLIENTI VALUES("1780720348698", "Marin", "Horia", "1978-07-20", "M", "horia.marin78@yahoo.com", "0710185210", "ROU", 43, 5700);
INSERT INTO CLIENTI VALUES("1780802489659", "Serbanescu", "Daniel", "1978-08-02", "M", "daniel.serbanescu@outlook.com", "0794932296", "ROU", 50, 14400);
INSERT INTO CLIENTI VALUES("1780822181387", "Popovici", "Vladimir", "1978-08-22", "M", "popo.vlad78@yahoo.com", "0759393992", "ROU", 148, 3900);
INSERT INTO CLIENTI VALUES("1790605257477", "Stolojan", "Petru", "1979-06-05", "M", "petru.stolojan1979@yahoo.com", "0733482080", "ROU", 86, 10500);
INSERT INTO CLIENTI VALUES("1790919198227", "Croitoru", "George", "1979-09-19", "M", "croitorugeorge@yahoo.com", "0769351587", "ROU", 172, 7400);
INSERT INTO CLIENTI VALUES("1800409337422", "Poienaru", "Silviu", "1980-04-09", "M", "silviu.poienaru@outlook.com", "0741805322", "ROU", 173, 10900);
INSERT INTO CLIENTI VALUES("1810920141043", "Dumitrescu", "Teodor", "1981-09-20", "M", "teo.dumitrescu@yahoo.com", "0714784607", "ROU", 162, 15000);
INSERT INTO CLIENTI VALUES("1830307160761", "Cernea", "Sebastian", "1983-03-07", "M", "sebastian.cernea@yahoo.com", "0779563258", "ROU", 64, 4700);
INSERT INTO CLIENTI VALUES("1830324326511", "Balcescu", "Gabriel", "1983-03-24", "M", "balcescu.gabi83@yahoo.com", "0713137267", "ROU", 49, 8600);
INSERT INTO CLIENTI VALUES("1830809325279", "Vasilescu", "Ovidiu", "1983-08-09", "M", "ovidiu.vasile@outlook.com", "0738040488", "ROU", 51, 9100);
INSERT INTO CLIENTI VALUES("1830923035027", "Stoica", "Vladimir", "1983-09-23", "M", "vlad.stoica83@yahoo.com", "0784192436", "ROU", 170, 17500);
INSERT INTO CLIENTI VALUES("1831128105949", "Lupu", "Gabriel", "1983-11-28", "M", "gabriel.lupu@yahoo.com", "0786399699", "ROU", 115, 8100);
INSERT INTO CLIENTI VALUES("1840629205045", "Marcu", "Daniel", "1984-06-29", "M", "dani.marcu@yahoo.com", "0753458942", "ROU", 137, 17900);
INSERT INTO CLIENTI VALUES("1840817147778", "Dumitru", "Aurel", "1984-08-17", "M", "aurel.dumitru84@yahoo.com", "0769849067", "ROU", 138, 5600);
INSERT INTO CLIENTI VALUES("1850615202921", "Apostol", "Daniel", "1985-06-15", "M", "apostol.daniel@outlook.com", "0701658162", "ROU", 131, 10600);
INSERT INTO CLIENTI VALUES("1851227027050", "Popescu", "Felix", "1985-12-27", "M", "popescu.felix85@yahoo.com", "0729075026", "ROU", 15, 5100);
INSERT INTO CLIENTI VALUES("1860410010990", "Ionescu", "Iulian", "1986-04-10", "M", "iulian.ionesco@yahoo.com", "0755663432", "ROU", 154, 13800);
INSERT INTO CLIENTI VALUES("1870427192885", "Ionescu", "Dragos", "1987-04-27", "M", "dragos.ionescu87@yahoo.com", "0709896718", "ROU", 222, 6200);
INSERT INTO CLIENTI VALUES("1881204450766", "Rotaru", "Dan", "1988-12-04", "M", "dan.rotaru8@gmail.com", "0744899838", "ROU", 69, 16000);
INSERT INTO CLIENTI VALUES("1890525049232", "Codreanu", "Emanuel", "1989-05-25", "M", "codru.emanuel@gmail.com", "0789273216", "ROU", 37, 17300);
INSERT INTO CLIENTI VALUES("1901031482215", "Cojocaru", "Marcel", "1990-10-31", "M", "cojoc.marcel99@gmail.com", "0750141651", "ROU", 114, 12200);
INSERT INTO CLIENTI VALUES("1930625367430", "Moisuc", "Ciprian", "1993-06-25", "M", "ciprian.moisuc@yahoo.com", "0784811749", "ROU", 143, 3900);
INSERT INTO CLIENTI VALUES("1950908192156", "Popescu", "Mircea", "1995-09-08", "M", "mircea.popescu.oficial@outlook.com", "0787750165", "ROU", 115, 13400);
INSERT INTO CLIENTI VALUES("1960228489327", "Codreanu", "Stefan", "1996-02-28", "M", "stefan.codreanu96@gmail.com", "0761167510", "ROU", 171, 12300);
INSERT INTO CLIENTI VALUES("1960914162747", "Toma", "Radu", "1996-09-14", "M", "radu.toma96@outlook.com", "0738616408", "ROU", 162, 5600);
INSERT INTO CLIENTI VALUES("1970419320579", "Oprea", "Aurel", "1997-04-19", "M", "oprea.au97@yahoo.com", "0724676590", "ROU", 74, 12400);
INSERT INTO CLIENTI VALUES("1970606153693", "Apostol", "Ion", "1997-06-06", "M", "ionapostol97@yahoo.com", "0723224019", "ROU", 8, 16600);
INSERT INTO CLIENTI VALUES("2480703323387", "Cernat", "Mirela", "1948-07-03", "F", NULL, "0728018906", "ROU", 53, NULL);
INSERT INTO CLIENTI VALUES("2541210145136", "Negrescu", "Alina", "1954-12-10", "F", NULL, "0796886863 ", "ROU", 99, NULL);
INSERT INTO CLIENTI VALUES("2570301403692", "Popescu", "Mihaela", "1957-03-01", "F", NULL, "0790474608", "ROU", 145, NULL);
INSERT INTO CLIENTI VALUES("2571004253129", "Vladu", "Ioana", "1957-10-04", "F", NULL, "0701515920", "ROU", 162, NULL);
INSERT INTO CLIENTI VALUES("2580426162435", "Popescu", "Sorina", "1958-04-26", "F", NULL, "0733255788", "ROU", 1, 6700);
INSERT INTO CLIENTI VALUES("2580624147407", "Ionescu", "Floriana", "1958-06-24", "F", NULL, "0707416729", "ROU", 103, NULL);
INSERT INTO CLIENTI VALUES("2590106203573", "Teodorescu", "Maria", "1959-01-06", "F", NULL, "0774483745", "ROU", 132, 6400);
INSERT INTO CLIENTI VALUES("2590211213795", "Winter", "Frieda", "1959-02-11", "F", NULL, "0798732018", "ROU", 116, 3500);
INSERT INTO CLIENTI VALUES("2660625496985", "Calinescu", "Luiza", "1966-06-25", "F", NULL, "0710797296", "ROU", 161, NULL);
INSERT INTO CLIENTI VALUES("2660715141925", "Ursu", "Marinela", "1966-07-15", "F", "marinela.ursu66@gmail.com", "0748526968", "ROU", 58, 15000);
INSERT INTO CLIENTI VALUES("2671125122714", "Cazacu", "Ramona", "1967-11-25", "F", "ramona.cazacu67@outlook.com", "0741652787", "ROU", 10, NULL);
INSERT INTO CLIENTI VALUES("2700728442083", "Tataru", "Sabina", "1970-07-28", "F", "tataru.sabina@outlook.com", "0752876941", "ROU", 96, 13200);
INSERT INTO CLIENTI VALUES("2710911018202", "Szekeres", "Greta", "1971-09-11", "F", "gretaszekeres@gmail.com", "0783437815", "ROU", 145, 18600);
INSERT INTO CLIENTI VALUES("2721010177130", "Leonte", "Andreea", "1972-10-10", "F", "andreea.leonte72@outlook.com", "0717977841", "ROU", 36, 18000);
INSERT INTO CLIENTI VALUES("2740517139998", "Diaconescu", "Margareta", "1974-05-17", "F", "marga.diaconescu@outlook.com", "0742819385", "ROU", 93, 5100);
INSERT INTO CLIENTI VALUES("2750207237659", "Lazarescu", "Luiza", "1975-02-07", "F", "lazarescu.luiza75@yahoo.com", "0739418364", "ROU", 14, 13500);
INSERT INTO CLIENTI VALUES("2750316082960", "Bursuc", "Ileana", "1975-03-16", "F", "ileana.bursuc@gmail.com", "0734900982", "ROU", 66, 8000);
INSERT INTO CLIENTI VALUES("2770716209801", "Rudeanu", "Anastasia", "1977-07-16", "F", "anastasia.rudeanu@yahoo.com", "0753232274", "ROU", 139, 7800);
INSERT INTO CLIENTI VALUES("2771110526477", "Avramescu", "Veronica", "1977-11-10", "F", "veronica.avramescu77@outlook.com", "0775884587", "ROU", 15, 16400);
INSERT INTO CLIENTI VALUES("2781106429223", "Petrescu", "Elena", "1978-11-06", "F", NULL, "0718821901 ", "ROU", 24, 8200);
INSERT INTO CLIENTI VALUES("2800619247972", "Balan", "Laura", "1980-06-19", "F", "laurabalan8@yahoo.com", "0740869285", "ROU", 83, 8900);
INSERT INTO CLIENTI VALUES("2811202514813", "Anghelescu", "Corina", "1981-12-02", "F", "anghelescu.corina@yahoo.com", "0741614192", "ROU", 184, 18500);
INSERT INTO CLIENTI VALUES("2820211053885", "Funariu", "Cosmina", "1982-02-11", "F", "cosmina.funariu@yahoo.com", "0797693591", "ROU", 159, 7100);
INSERT INTO CLIENTI VALUES("2820509200564", "Sandu", "Inesa", "1982-05-09", "F", "inesandu@yahoo.com", "0791753008", "ROU", 169, 17300);
INSERT INTO CLIENTI VALUES("2830621436251", "Stirbei", "Mihaela", "1983-06-21", "F", "mihaela.stirbei@outlook.com", "0744061004", "ROU", 27, 18600);
INSERT INTO CLIENTI VALUES("2840123528336", "Ciobanu", "Ema", "1984-01-23", "F", "ema.ciobanu84@gmail.com", "0732654517", "ROU", 75, 5000);
INSERT INTO CLIENTI VALUES("2840623470497", "Stefanescu", "Daria", "1984-06-23", "F", "dariastef84@yahoo.com", "0771222904", "ROU", 112, 18000);
INSERT INTO CLIENTI VALUES("2851016463188", "Enache", "Iuliana", "1985-10-16", "F", "enacheiuliana@yahoo.com", "0722242468", "ROU", 156, 4800);
INSERT INTO CLIENTI VALUES("2870120336898", "Petric", "Ioana", "1987-01-20", "F", "petricioana87@gmail.com", "0731834472", "ROU", 165, 4300);
INSERT INTO CLIENTI VALUES("2870228199148", "Pirvulescu", "Raluca", "1987-02-28", "F", "pirvulescu.raluca@yahoo.com", "0744562289", "ROU", 109, 3900);
INSERT INTO CLIENTI VALUES("2881018410338", "Predoiu", "Ligia", "1988-10-18", "F", "predoiu.ligia88@outlook.com", "0745578227", "ROU", 199, 12600);
INSERT INTO CLIENTI VALUES("2881126174275", "Munteanu", "Magdalena", "1988-11-26", "F", "munteanu.magda@yahoo.com", "0703060311", "ROU", 119, 19200);
INSERT INTO CLIENTI VALUES("2911008288717", "Stanescu", "Ecaterina", "1991-10-08", "F", "caterina.stanescu@gmail.com", "0714840824", "ROU", 135, 5200);
INSERT INTO CLIENTI VALUES("2911224168862", "Blaga", "Anamaria", "1991-12-24", "F", "blaganamaria@yahoo.com", "0799719892", "ROU", 17, 9100);
INSERT INTO CLIENTI VALUES("2930721402998", "Cernea", "Marilena", "1993-07-21", "F", "cernea.marilena93@gmail.com", "0717800723", "ROU", 216, 16300);
INSERT INTO CLIENTI VALUES("2940826377526", "Matei", "Adriana", "1994-08-26", "F", "adriana.matei@yahoo.com", "0764048006", "ROU", 117, 7000);
INSERT INTO CLIENTI VALUES("2950126339363", "Lungu", "Georgiana", "1995-01-26", "F", "lungu.georgiana95@yahoo.com", "0744436870", "ROU", 145, 11600);
INSERT INTO CLIENTI VALUES("2951113447967", "Chiriac", "Daniela", "1995-11-13", "F", "daniela.chiriac@yahoo.com", "0784158896", "ROU", 212, 18700);
INSERT INTO CLIENTI VALUES("2960418064881", "Ghita", "Valentina", "1996-04-18", "F", "ghita.valentina@yahoo.com", "0784333061", "ROU", 71, 5100);
INSERT INTO CLIENTI VALUES("5000409495853", "Wendl", "Julius", "2000-04-09", "M", "wendl.juli2@outlook.com", "0732321310", "ROU", 84, 4840);
INSERT INTO CLIENTI VALUES("5000508516123", "Zamfirescu", "Anton", "2000-05-08", "M", "anton.zamfi85@yahoo.com", "0754508474", "ROU", 44, 3120);
INSERT INTO CLIENTI VALUES("5000510409112", "Balan", "Alexandru", "2000-05-10", "M", "mayboyalex@gmail.com", "0771987763", "ROU", 137, NULL);
INSERT INTO CLIENTI VALUES("5000630020931", "Boca", "Cristian", "2000-06-30", "M", "cristiboca21@gmail.com", "0769904907", "ROU", 48, NULL);
INSERT INTO CLIENTI VALUES("5001201414361", "Radnitz", "Victor", "2000-12-01", "M", "victorradnitz@yahoo.com", "0750716264", "ROU", 33, 3550);
INSERT INTO CLIENTI VALUES("5001214247726", "Diaconescu", "Emilian", "2000-12-14", "M", "emil.diacon@gmail.com", "0753528215", "ROU", 141, 4790);
INSERT INTO CLIENTI VALUES("5001228095793", "Maniu", "Florentin", "2000-12-28", "M", "maniuflori2@gmail.com", "0749478787", "ROU", 87, 3250);
INSERT INTO CLIENTI VALUES("5010430235606", "Negrescu", "Eugen", "2001-04-30", "M", "eunegrescu@yahoo.com", "0785408353", "ROU", 44, 4270);
INSERT INTO CLIENTI VALUES("5010703324568", "Simion", "Stefan", "2001-07-03", "M", "stef.simion1@yahoo.com", "0789000438", "ROU", 93, NULL);
INSERT INTO CLIENTI VALUES("5010827396429", "Ionescu", "Carol", "2001-08-27", "M", "carol.intai.ionescu@gmail.com", "0799844961", "ROU", 49, 4700);
INSERT INTO CLIENTI VALUES("5020311449762", "Teodosie", "Constantin", "2002-03-11", "M", "costi.teo1103@gmail.com", "0740516269", "ROU", 93, 4320);
INSERT INTO CLIENTI VALUES("5020512139315", "Cuza", "Alexandru", "2002-05-12", "M", "alex.cuza22@yahoo.com", "0754784183", "ROU", 131, 4370);
INSERT INTO CLIENTI VALUES("5020801467176", "Andreescu", "Dragos", "2002-08-01", "M", "dragondreescu@gmail.com", "0723304466", "ROU", 85, NULL);
INSERT INTO CLIENTI VALUES("5020805217120", "Martinescu", "Valentin", "2002-08-05", "M", "vali.martie@gmail.com", "0737026005", "ROU", 114, 3920);
INSERT INTO CLIENTI VALUES("5020822078429", "Barbulescu", "Emanuel", "2002-08-22", "M", "barbu.emanuel@yahoo.com", "0790232250", "ROU", 35, 3960);
INSERT INTO CLIENTI VALUES("5030227190909", "Niculescu", "Radu", "2003-02-27", "M", "radu.nicule03@yahoo.com", "0781630626", "ROU", 164, 4390);
INSERT INTO CLIENTI VALUES("5030310206668", "Sirbu", "Marius", "2003-03-10", "M", "mariussirbu@yahoo.com", "0708857932", "ROU", 152, 4830);
INSERT INTO CLIENTI VALUES("5030328315622", "Eliade", "Robert", "2003-03-28", "M", "roberteliade@gmail.com", "0768867326", "ROU", 207, NULL);
INSERT INTO CLIENTI VALUES("5030701105081", "Cojocaru", "Alin", "2003-07-01", "M", "cojocaru.alin@gmail.com", "0723050746", "ROU", 94, 3610);
INSERT INTO CLIENTI VALUES("5030705288224", "Cristea", "David", "2003-07-05", "M", "david.cristea@gmail.com", "0732867916", "ROU", 25, 3490);
INSERT INTO CLIENTI VALUES("5031121270125", "Mihalache", "Octavian", "2003-11-21", "M", NULL, "0701531315", "ROU", 2, 4330);
INSERT INTO CLIENTI VALUES("5040115083586", "Apostol", "Bogdan", "2004-01-15", "M", "apostobog@gmail.com", "0714516565", "ROU", 5, 3900);
INSERT INTO CLIENTI VALUES("5040116067899", "Vasiliu", "Nicolae", "2004-01-16", "M", "niconico4@gmail.com", "0749351400", "ROU", 108, NULL);
INSERT INTO CLIENTI VALUES("5040513224064", "Vasilescu", "Filip", "2004-05-13", "M", "filippino24@gmail.com", "0702087932", "ROU", 4, NULL);
INSERT INTO CLIENTI VALUES("5041004362347", "Caraiman", "Boris", "2004-10-04", "M", "borris.carayman@gmail.com", "0781769166", "ROU", 140, 3600);
INSERT INTO CLIENTI VALUES("5041206211742", "Predoiu", "Darius", "2004-12-06", "M", "darius.predoiu04@gmail.com", "0707769136", "ROU", 207, NULL);
INSERT INTO CLIENTI VALUES("5050504322271", "Groza", "Gheorghe", "2005-05-04", "M", "ggroza2005@yahoo.com", "0789449036", "ROU", 118, NULL);
INSERT INTO CLIENTI VALUES("5050719275891", "Groza", "Daniel", "2005-07-19", "M", "danigroza.vu@gmail.com", "0704685994", "ROU", 151, NULL);
INSERT INTO CLIENTI VALUES("5051030101299", "Stanescu", "Tudor", "2005-10-30", "M", "tudorgaming555@gmail.com", "0708563914", "ROU", 32, NULL);
INSERT INTO CLIENTI VALUES("5060514521774", "Muresan", "Flavius", "2006-05-14", "M", "flavius.muresan@outlook.com", "0714724315", "ROU", 174, NULL);
INSERT INTO CLIENTI VALUES("5070226117188", "Diaconescu", "Adrian", "2007-02-26", "M", "adidiaconescu@gmail.com", "0724526135", "ROU", 86, NULL);
INSERT INTO CLIENTI VALUES("5070612214767", "Voicu", "Virgil", "2007-06-12", "M", "virgilvv7@gmail.com", "0779197909", "ROU", 74, NULL);
INSERT INTO CLIENTI VALUES("6000331133180", "Barbu", "Elena", "2000-03-31", "F", "barbelena@gmail.com", "0744058829", "ROU", 131, 3120);
INSERT INTO CLIENTI VALUES("6000718149401", "Dinulescu", "Miruna", "2000-07-18", "F", "miri.dinulescu20@gmail.com", "0717494687", "ROU", 175, 4710);
INSERT INTO CLIENTI VALUES("6000831371932", "Voiculet", "Silvia", "2000-08-31", "F", "silvia.voiculet@protonmail.com", "0762583804", "ROU", 185, 3410);
INSERT INTO CLIENTI VALUES("6010312322193", "Funariu", "Denisa", "2001-03-12", "F", "funar.denisa@gmail.com", "0710242331", "ROU", 16, 4360);
INSERT INTO CLIENTI VALUES("6010414040528", "Lazarescu", "Roxana", "2001-04-14", "F", "roxie.laser@gmail.com", "0733156894", "ROU", 22, 4910);
INSERT INTO CLIENTI VALUES("6010831365563", "Musat", "Carmen", "2001-08-31", "F", "carmaen.musat@gmail.com", "0737381062", "ROU", 150, 4240);
INSERT INTO CLIENTI VALUES("6011203069081", "Nistor", "Ema", "2001-12-03", "F", "emanistor21@gmail.com", "0723062331", "ROU", 50, 3040);
INSERT INTO CLIENTI VALUES("6020203406336", "Ungureanu", "Izabela", "2002-02-03", "F", "izabela.ungureanu02@outlook.com", "0756881364", "ROU", 113, 4280);
INSERT INTO CLIENTI VALUES("6020629368336", "Florea", "Ana", "2002-06-29", "F", "anaflorea292@yahoo.com", "0792446154", "ROU", 77, 4730);
INSERT INTO CLIENTI VALUES("6021103428518", "Stolojan", "Olivia", "2002-11-03", "F", "stololivia22@gmail.com", "0722630567", "ROU", 134, 4240);
INSERT INTO CLIENTI VALUES("6021111373596", "Lupu", "Ana", "2002-11-11", "F", "analupu@yahoo.com", "0701879876", "ROU", 174, NULL);
INSERT INTO CLIENTI VALUES("6030322358219", "Chitu", "Gabriela", "2003-03-22", "F", "gabicitsu3@gmail.com", "0737459642", "ROU", 2, NULL);
INSERT INTO CLIENTI VALUES("6030716279800", "Cretu", "Erica", "2003-07-16", "F", "ericacretu03@gmail.com", "0716960305", "ROU", 55, NULL);
INSERT INTO CLIENTI VALUES("6030727124438", "Toma", "Violeta", "2003-07-27", "F", "violetatoma03@gmail.com", "0770501062", "ROU", 26, NULL);
INSERT INTO CLIENTI VALUES("6031017410138", "Toma", "Iuliana", "2003-10-17", "F", "iulitoma203@gmail.com", "0761190378", "ROU", 173, 4020);
INSERT INTO CLIENTI VALUES("6040108111871", "Lupu", "Cristina", "2004-01-08", "F", "cristina.lupu4@gmail.com", "0748392473", "ROU", 166, 3180);
INSERT INTO CLIENTI VALUES("6040210165911", "Stolojan", "Ionela", "2004-02-10", "F", "ionela.stolojan4@gmail.com", "0748255130", "ROU", 154, 3160);
INSERT INTO CLIENTI VALUES("6041123293702", "Cojocaru", "Victoria", "2004-11-23", "F", "vicojocaru40@gmail.com", "0791410841", "ROU", 114, NULL);
INSERT INTO CLIENTI VALUES("6041206042503", "Balauru", "Floriana", "2004-12-06", "F", NULL, "0704759445", "ROU", 202, NULL);
INSERT INTO CLIENTI VALUES("6050408161391", "Manole", "Cosmina", "2005-04-08", "F", "manolecosmina5@gmail.com", "0759543541", "ROU", 12, NULL);
INSERT INTO CLIENTI VALUES("6050805173700", "Maniu", "Aurora", "2005-08-05", "F", "auroraprincess05@gmail.com", "0793571381", "ROU", 48, 0);
INSERT INTO CLIENTI VALUES("6051218455634", "Lazarescu", "Ana", "2005-12-18", "F", "analazarana@gmail.com", "0729422802", "ROU", 73, NULL);
INSERT INTO CLIENTI VALUES("6060116123561", "Manole", "Maria", "2006-01-16", "F", "mari.manole6@gmail.com", "0755271716", "ROU", 149, NULL);
INSERT INTO CLIENTI VALUES("6060117222954", "Calinescu", "Raluca", "2006-01-17", "F", "raluca.calinescu06@yahoo.com", "0781659762", "ROU", 34, NULL);
INSERT INTO CLIENTI VALUES("6060206389256", "Manea", "Angelica", "2006-02-06", "F", "diamonangel06@gmail.com", "0773591639", "ROU", 56, NULL);
INSERT INTO CLIENTI VALUES("6060312529954", "Piturca", "Stefania", "2006-03-12", "F", NULL, "0746406788", "ROU", 146, NULL);
INSERT INTO CLIENTI VALUES("6060807436974", "Musat", "Corina", "2006-08-07", "F", "corinam2006@gmail.com", "0761111876", "ROU", 175, NULL);
INSERT INTO CLIENTI VALUES("6070209396895", "Dobrescu", "Ramona", "2007-02-09", "F", "rami.dobrescu@yahoo.com", "0779864750", "ROU", 17, NULL);
INSERT INTO CLIENTI VALUES("607031935865", "Covaci", "Valeria", "2007-03-19", "F", "valeria.covacs@gmail.com", "0712524735", "ROU", 114, NULL);
INSERT INTO CLIENTI VALUES("6070729202564", "Baicu", "Lucia", "2007-07-29", "F", "baicu.lucia07@gmail.com", "0774409061", "ROU", 78, NULL);
INSERT INTO CLIENTI VALUES("615378U1D100", "Deramo", "Ottaviano", "1997-05-14", "M", "deramottaviano@outlook.com", "0671690134", "ITA", 181, 10000);
INSERT INTO CLIENTI VALUES("68251085A", "Serrano", "Salvador", "1999-01-20", "M", "salvadorserrano9@yahoo.com", "0720158010", "ESP", 225, 11900);
INSERT INTO CLIENTI VALUES("880692310285", "Berthier", "Corine", "1965-12-06", "F", NULL, "0716824086", "FRA", 121, 21000);
INSERT INTO CLIENTI VALUES("9714FFA478719", "Scorsone", "Ianira", "1989-06-17", "F", NULL, "0741629756", "ITA", 183, NULL);
INSERT INTO CLIENTI VALUES("9811150570", "Lubostchovitch", "Luka", "1998-11-15", "M", "lukalobost98@gmail.com", "0783951772", "CZE", 187, 9900);
INSERT INTO CLIENTI VALUES("F56194613", "Speraki", "Penelope", "1977-07-16", "F", "penelopesperaki@gmail.com", "0201224918", "GRC", 224, 4600);
INSERT INTO CLIENTI VALUES("H90176599", "Politoglou", "Michalis", "1981-02-20", "M", "michapolitoglou@gmail.com", "0225719487", "GRC", 124, 7800);
INSERT INTO CLIENTI VALUES("L01TX00L47", "Havenstein", "Henry", "1988-12-15", "M", "havenstein1988@yahoo.com", "0759371476", "DEU", 185, 15600);
INSERT INTO CLIENTI VALUES("OA856104", "Koleno", "Daniel", "2001-08-10", "M", "kolenodani@gmail.com", "0421759104", "SVK", 228, 0);
INSERT INTO CLIENTI VALUES("X4RTBPFW46", "Martin", "Marie", "1990-07-13", "F", "mariemartin@yahoo.com", "0741719501", "FRA", 200, 6000);

-- ACTIVITATI_ONLINE - inserare

INSERT INTO ACTIVITATI_ONLINE VALUES("1480428126141", "2023-12-25 17:12:29", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1570723281056", "2023-12-25 17:10:51", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("1690612392587", "2023-12-25 17:11:37", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1720112113128", "2023-12-25 17:12:17", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1720112113128", "2023-12-25 17:19:49", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1760607290263", "2023-12-25 17:24:25", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("1761213049185", "2023-12-25 17:22:03", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1780720348698", "2023-12-25 17:11:08", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("1780822181387", "2023-12-25 17:14:32", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1790919198227", "2023-12-25 17:24:33", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1831128105949", "2023-12-25 17:14:23", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1831128105949", "2023-12-25 17:19:45", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1831128105949", "2023-12-25 17:23:45", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1850615202921", "2023-12-25 17:10:17", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1850615202921", "2023-12-25 17:23:24", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("1851227027050", "2023-12-25 17:11:17", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1851227027050", "2023-12-25 17:23:06", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("1890525049232", "2023-12-25 17:12:35", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("1960228489327", "2023-12-25 17:11:28", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("1960228489327", "2023-12-25 17:22:45", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("1960914162747", "2023-12-25 17:14:10", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("2590106203573", "2023-12-25 17:14:03", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("2660715141925", "2023-12-25 17:21:54", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("2721010177130", "2023-12-25 17:09:17", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("2750316082960", "2023-12-25 17:10:59", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("2770716209801", "2023-12-25 17:09:31", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("2870228199148", "2023-12-25 17:10:12", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("2870228199148", "2023-12-25 17:12:24", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("2911224168862", "2023-12-25 17:23:31", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("2960418064881", "2023-12-25 17:24:16", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("5000508516123", "2023-12-25 17:10:32", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5000508516123", "2023-12-25 17:12:09", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("5001201414361", "2023-12-25 17:12:56", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("5001201414361", "2023-12-25 17:23:53", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5010703324568", "2023-12-25 17:21:46", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5020311449762", "2024-01-04 17:51:31", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("5020311449762", "2024-01-09 19:14:42", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("5020311449762", "2024-01-10 20:09:10", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("5020512139315", "2023-12-25 17:24:09", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5020822078429", "2023-12-25 16:54:33", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5020822078429", "2023-12-25 17:12:47", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("5031121270125", "2023-12-25 17:14:18", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("5040115083586", "2023-12-25 17:23:15", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("5040116067899", "2023-12-25 17:23:38", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("5041004362347", "2023-12-25 17:22:52", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("5050719275891", "2023-12-25 17:12:41", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("5070612214767", "2023-12-25 17:20:51", "schimbare_setari");
INSERT INTO ACTIVITATI_ONLINE VALUES("5070612214767", "2023-12-25 17:23:00", "contactare_suport");
INSERT INTO ACTIVITATI_ONLINE VALUES("6011203069081", "2023-12-25 17:07:51", NULL);
INSERT INTO ACTIVITATI_ONLINE VALUES("6021111373596", "2023-12-25 17:20:43", "verificare_istoric");
INSERT INTO ACTIVITATI_ONLINE VALUES("6030716279800", "2023-12-25 17:13:47", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("9714FFA478719", "2023-12-25 17:10:42", "interogare_sold");
INSERT INTO ACTIVITATI_ONLINE VALUES("X4RTBPFW46", "2023-12-25 17:24:02", "schimbare_setari");

-- CONTURI - inserare

INSERT INTO CONTURI VALUES("RO01MBNKRONJNORRQSSSEUO7", "RON", "1750426262233");
INSERT INTO CONTURI VALUES("RO02MBNKUSD65S1220T8B076", "USD", "1850615202921");
INSERT INTO CONTURI VALUES("RO04MBNKEURGSXV1OJUU4O17", "EUR", "1770609255111");
INSERT INTO CONTURI VALUES("RO06MBNKRONG5F0ZWKDROF1I", "RON", "5010827396429");
INSERT INTO CONTURI VALUES("RO08MBNKRON217DCT3NG8K10", "RON", "6070209396895");
INSERT INTO CONTURI VALUES("RO08MBNKRON620C9JCYO27L1", "RON", "2781106429223");
INSERT INTO CONTURI VALUES("RO08MBNKRONZ47G137XZ307J", "RON", "1690612392587");
INSERT INTO CONTURI VALUES("RO08MBNKUSDJT2S50VMT037C", "USD", "2881126174275");
INSERT INTO CONTURI VALUES("RO09MBNKRON87ZLC3Y4FQLL2", "RON", "5051030101299");
INSERT INTO CONTURI VALUES("RO09MBNKUSDZ2Q2NQI3CF62O", "USD", "1620414516332");
INSERT INTO CONTURI VALUES("RO13MBNKRON4N05824S1S5JC", "RON", "5010827396429");
INSERT INTO CONTURI VALUES("RO15MBNKUSDGYXFD59VAVM98", "USD", "1770609255111");
INSERT INTO CONTURI VALUES("RO16MBNKEURGHX03KINP67T0", "EUR", "1800409337422");
INSERT INTO CONTURI VALUES("RO16MBNKRON54J5V1MW134YQ", "RON", "1550610118834");
INSERT INTO CONTURI VALUES("RO16MBNKUSDPFJMS33QHJWF8", "USD", "5001214247726");
INSERT INTO CONTURI VALUES("RO17MBNKEURO546IYV3539EX", "EUR", "1780822181387");
INSERT INTO CONTURI VALUES("RO17MBNKUSDEP5NYZC24DX9C", "USD", "6070209396895");
INSERT INTO CONTURI VALUES("RO18MBNKRONLOQ091GB777E9", "RON", "L01TX00L47");
INSERT INTO CONTURI VALUES("RO19MBNKEURTNI7FDD23K3T9", "EUR", "1840817147778");
INSERT INTO CONTURI VALUES("RO21MBNKRON34300KZJ006R3", "RON", "5040115083586");
INSERT INTO CONTURI VALUES("RO21MBNKRONW454R93XE483L", "RON", "6070729202564");
INSERT INTO CONTURI VALUES("RO22MBNKUSDHZR3M3ITCOM1R", "USD", "2750207237659");
INSERT INTO CONTURI VALUES("RO23MBNKRON94XY692JI0135", "RON", "2771110526477");
INSERT INTO CONTURI VALUES("RO23MBNKRONMHSHJSQUMUBJ0", "RON", "1850615202921");
INSERT INTO CONTURI VALUES("RO24MBNKUSD67N048VCG996K", "USD", "2870120336898");
INSERT INTO CONTURI VALUES("RO26MBNKEUR4092Q939O71CO", "EUR", "1970606153693");
INSERT INTO CONTURI VALUES("RO26MBNKRON1220X0R69Z3NI", "RON", "5040116067899");
INSERT INTO CONTURI VALUES("RO27MBNKRONU9YMIOIOI7OLZ", "RON", "5020805217120");
INSERT INTO CONTURI VALUES("RO27MBNKUSDPO5W3K2L25NY3", "USD", "1890525049232");
INSERT INTO CONTURI VALUES("RO33MBNKEURX6F01012T5RT3", "EUR", "1720112113128");
INSERT INTO CONTURI VALUES("RO33MBNKRONT3RK8EW27CH76 ", "RON", "2820211053885");
INSERT INTO CONTURI VALUES("RO33MBNKRONTWINEGOOBBP54", "RON", "2840123528336");
INSERT INTO CONTURI VALUES("RO35MBNKEURE443BRFN7RCUK", "EUR", "1831128105949");
INSERT INTO CONTURI VALUES("RO35MBNKRONYOC6S3Q0VALWJ", "RON", "1901031482215");
INSERT INTO CONTURI VALUES("RO36MBNKRONC9M29GOP9KGUK", "RON", "1720112113128");
INSERT INTO CONTURI VALUES("RO36MBNKRONWVGPZI363NGH5", "RON", "5000510409112");
INSERT INTO CONTURI VALUES("RO38MBNKRON79062WW1PHK38", "RON", "5041206211742");
INSERT INTO CONTURI VALUES("RO39MBNKRONBCSIR2LQHAT86", "RON", "6010414040528");
INSERT INTO CONTURI VALUES("RO41MBNKRON1ON77BV7AGAUR", "RON", "2881018410338");
INSERT INTO CONTURI VALUES("RO41MBNKRONA1QG9290AOVLZ", "RON", "6000331133180");
INSERT INTO CONTURI VALUES("RO41MBNKRONDTLJR9KMKTTE4 ", "RON", "1881204450766");
INSERT INTO CONTURI VALUES("RO43MBNKRONSZ5KTEKGPS5WT", "RON", "1970419320579");
INSERT INTO CONTURI VALUES("RO44MBNKRON2P19389Q600V5", "RON", "1970419320579");
INSERT INTO CONTURI VALUES("RO44MBNKRONC823J6OHBDNPY", "RON", "9714FFA478719");
INSERT INTO CONTURI VALUES("RO45MBNKUSDFDZ8T0P5EH9WC", "USD", "5020822078429");
INSERT INTO CONTURI VALUES("RO46MBNKRON5V9N9FH5P9EV9", "RON", "615378U1D100");
INSERT INTO CONTURI VALUES("RO47MBNKRON27V46S9AX7A54", "RON", "OA856104");
INSERT INTO CONTURI VALUES("RO47MBNKUSDJSDBR8R17IXMO", "USD", "2870228199148");
INSERT INTO CONTURI VALUES("RO49MBNKEUR4PHZ17MN6430A", "EUR", "2930721402998");
INSERT INTO CONTURI VALUES("RO49MBNKRONSCHC8BW5QZOF8", "RON", "1620414516332");
INSERT INTO CONTURI VALUES("RO49MBNKUSDTVMR6WTJ0CKZX", "USD", "1780720348698");
INSERT INTO CONTURI VALUES("RO50MBNKUSDJ91F9NFTTLOZV", "USD", "1780822181387");
INSERT INTO CONTURI VALUES("RO51MBNKRON088Q6WQOE2HSO", "RON", "5030310206668");
INSERT INTO CONTURI VALUES("RO51MBNKRON13U0LNCCTF22E", "RON", "1550610118834");
INSERT INTO CONTURI VALUES("RO51MBNKRON7Z8NK7NBK2RG7", "RON", "2820211053885");
INSERT INTO CONTURI VALUES("RO53MBNKRONDU793WOMDU01Q ", "RON", "1610929305189");
INSERT INTO CONTURI VALUES("RO54MBNKUSDQEV23FQXRAFQP", "USD", "6011203069081");
INSERT INTO CONTURI VALUES("RO55MBNKRONAC0GX9M6P1N3Q", "RON", "5040115083586");
INSERT INTO CONTURI VALUES("RO55MBNKRONJC97VH7V63HF9", "RON", "2740517139998");
INSERT INTO CONTURI VALUES("RO55MBNKRONLSCRWBLQ430Z5", "RON", "5001201414361");
INSERT INTO CONTURI VALUES("RO56MBNKUSD53KDJGCM7GFTC", "USD", "1780720348698");
INSERT INTO CONTURI VALUES("RO57MBNKEUR1O13J53U57H4H ", "EUR", "6040108111871");
INSERT INTO CONTURI VALUES("RO57MBNKRONIDJUI1VE6VL5W", "RON", "5040513224064");
INSERT INTO CONTURI VALUES("RO57MBNKRONOGT4YOX048OBN", "RON", "2840123528336");
INSERT INTO CONTURI VALUES("RO58MBNKRONBSS9B6AC1G875", "RON", "6010831365563");
INSERT INTO CONTURI VALUES("RO60MBNKEUR6XTI8CQSHOWGM", "EUR", "6051218455634");
INSERT INTO CONTURI VALUES("RO60MBNKRONR69S3YF0BV290", "RON", "6050805173700");
INSERT INTO CONTURI VALUES("RO60MBNKRONUK8EJQJDFZBU8", "RON", "1780822181387");
INSERT INTO CONTURI VALUES("RO61MBNKEUROJI2KCLWT9CFT", "EUR", "1790919198227");
INSERT INTO CONTURI VALUES("RO61MBNKRONRJ921EZDQBBE7", "RON", "1830307160761");
INSERT INTO CONTURI VALUES("RO63MBNKEUR9XC7R1EU6Z8R9", "EUR", "1620414516332");
INSERT INTO CONTURI VALUES("RO63MBNKRONB76MTHXRS8535", "RON", "2580426162435");
INSERT INTO CONTURI VALUES("RO63MBNKUSDYJ9NAQ6LIPOUJ", "USD", "2911008288717");
INSERT INTO CONTURI VALUES("RO66MBNKUSD885UDR298QM8H", "USD", "1760607290263");
INSERT INTO CONTURI VALUES("RO67MBNKEUR58A6UH7231P2X", "EUR", "2851016463188");
INSERT INTO CONTURI VALUES("RO68MBNKRONTPGEHM5LJKP4R", "RON", "2870228199148");
INSERT INTO CONTURI VALUES("RO69MBNKRONUCMVO8DIM6HW2", "RON", "1610929305189");
INSERT INTO CONTURI VALUES("RO70MBNKRON3LLJWKMGLP6QJ", "RON", "6050805173700");
INSERT INTO CONTURI VALUES("RO71MBNKEURQ3QM2M9T9CRQP", "EUR", "2750316082960");
INSERT INTO CONTURI VALUES("RO71MBNKRONC60867LUXZL7Y", "RON", "1771216220833");
INSERT INTO CONTURI VALUES("RO71MBNKRONDVCQVKX7DPRK2", "RON", "5070612214767");
INSERT INTO CONTURI VALUES("RO71MBNKUSDIFHOUAA7JPJ7A ", "USD", "1950908192156");
INSERT INTO CONTURI VALUES("RO72MBNKEURUT0A9T9OZCKDL", "EUR", "1780822181387");
INSERT INTO CONTURI VALUES("RO73MBNKEURZDRJ43XYH62YR", "EUR", "2840123528336");
INSERT INTO CONTURI VALUES("RO74MBNKEUR50Y61YZAK453B", "EUR", "2571004253129");
INSERT INTO CONTURI VALUES("RO74MBNKEURDLQQ6NXWYPGJV", "EUR", "1790605257477");
INSERT INTO CONTURI VALUES("RO74MBNKRON793E8K60D4422", "RON", "1881204450766");
INSERT INTO CONTURI VALUES("RO75MBNKEURVQZ5UPDJ1J4K1", "EUR", "5020822078429");
INSERT INTO CONTURI VALUES("RO75MBNKRON2ZAMWFJO52MXZ", "RON", "1830923035027");
INSERT INTO CONTURI VALUES("RO75MBNKRONS6R0APAXRAFI4", "RON", "X4RTBPFW46");
INSERT INTO CONTURI VALUES("RO77MBNKEURBS6KH2728JSK3", "EUR", "1651017469726");
INSERT INTO CONTURI VALUES("RO77MBNKEURERTJFI2OGAIR0", "EUR", "5041004362347");
INSERT INTO CONTURI VALUES("RO77MBNKRON1R603YN9P5H83", "RON", "880692310285");
INSERT INTO CONTURI VALUES("RO78MBNKRON645V1F1R8503K", "RON", "1930625367430");
INSERT INTO CONTURI VALUES("RO80MBNKEUR775RX0R222NZD", "EUR", "5070612214767");
INSERT INTO CONTURI VALUES("RO80MBNKRON73OOKC98WAD21", "RON", "2840623470497");
INSERT INTO CONTURI VALUES("RO81MBNKRONK59QD16184GRX", "RON", "6030322358219");
INSERT INTO CONTURI VALUES("RO82MBNKEURIS2RKYFO6I4CR", "EUR", "2480703323387");
INSERT INTO CONTURI VALUES("RO82MBNKRONPNR6LABG7H87S", "RON", "1790605257477");
INSERT INTO CONTURI VALUES("RO82MBNKUSD53XSXT0BH7SXX", "USD", "6021103428518");
INSERT INTO CONTURI VALUES("RO82MBNKUSD9VN8QAQLG2BA6", "USD", "1730506181852");
INSERT INTO CONTURI VALUES("RO83MBNKRONGK2G6287QB07B", "RON", "1870427192885");
INSERT INTO CONTURI VALUES("RO83MBNKUSDYJKUXGQ3NXAS5", "USD", "6020629368336");
INSERT INTO CONTURI VALUES("RO84MBNKRON4XP5VHXKQX549", "RON", "6041123293702");
INSERT INTO CONTURI VALUES("RO87MBNKUSDEWM9LC4BA82I5", "USD", "6011203069081");
INSERT INTO CONTURI VALUES("RO88MBNKRONS4NO6FKH83T7R", "RON", "1570723281056");
INSERT INTO CONTURI VALUES("RO88MBNKUSD0EV373HH1NF1M", "USD", "2660625496985");
INSERT INTO CONTURI VALUES("RO89MBNKEURU1GT3BE7Q90AS", "EUR", "2950126339363");
INSERT INTO CONTURI VALUES("RO89MBNKUSD4B64OCDL999ME", "USD", "1851227027050");
INSERT INTO CONTURI VALUES("RO91MBNKEURL5EAAQ5ERC2P5", "EUR", "1960914162747");
INSERT INTO CONTURI VALUES("RO93MBNKEURO00B85OA157J2", "EUR", "2570301403692");
INSERT INTO CONTURI VALUES("RO93MBNKRONODO9QOXDPNI8U", "RON", "6040210165911");
INSERT INTO CONTURI VALUES("RO93MBNKUSDGP0O6XECWAFY6", "USD", "2960418064881");
INSERT INTO CONTURI VALUES("RO96MBNKUSDM700BZM203P6E", "USD", "9714FFA478719");
INSERT INTO CONTURI VALUES("RO97MBNKUSDK2QD9J48HLAW4", "USD", "1560921463023");
INSERT INTO CONTURI VALUES("RO98MBNKRONUTGDZZPQ32C5V", "RON", "5020822078429");
INSERT INTO CONTURI VALUES("RO99MBNKEUR391F6F3Z5G53O", "EUR", "1851227027050");
INSERT INTO CONTURI VALUES("RO99MBNKEURWUKVCW44QPFKW", "EUR", "1501015096000");
INSERT INTO CONTURI VALUES("RO99MBNKUSDQ7U4V1QUI0PG8", "USD", "2881018410338");

-- OFERTE - inserare

INSERT INTO OFERTE VALUES(1, "Standard RO", 1);
INSERT INTO OFERTE VALUES(2, "Standard EU", 1.2);
INSERT INTO OFERTE VALUES(3, "Gold RO", 2);
INSERT INTO OFERTE VALUES(4, "Gold EU", 2.5);
INSERT INTO OFERTE VALUES(5, "Gold Star", 3);
INSERT INTO OFERTE VALUES(6, "Omni", 0.5);
INSERT INTO OFERTE VALUES(7, "Platinum", 5);
INSERT INTO OFERTE VALUES(8, "Basic", 0.5);
INSERT INTO OFERTE VALUES(9, "Platinum Star", 5.5);

-- CARDURI - inserare

INSERT INTO CARDURI VALUES(1, 3, "5094196869280858", "debit", "RO51MBNKRON13U0LNCCTF22E");
INSERT INTO CARDURI VALUES(2, 2, "3966011307917811", "debit", "RO08MBNKRON620C9JCYO27L1");
INSERT INTO CARDURI VALUES(3, 1, "5791451737437729", "credit", "RO41MBNKRONDTLJR9KMKTTE4 ");
INSERT INTO CARDURI VALUES(4, 5, "9754986537624342", "debit", "RO27MBNKRONU9YMIOIOI7OLZ");
INSERT INTO CARDURI VALUES(5, 1, "7084212977997431", "debit", "RO99MBNKEURWUKVCW44QPFKW");
INSERT INTO CARDURI VALUES(6, 6, "9857765463566144", "credit", "RO75MBNKEURVQZ5UPDJ1J4K1");
INSERT INTO CARDURI VALUES(7, 4, "8009873873079989", "credit", "RO50MBNKUSDJ91F9NFTTLOZV");
INSERT INTO CARDURI VALUES(8, 8, "5002172053851334", "debit", "RO87MBNKUSDEWM9LC4BA82I5");
INSERT INTO CARDURI VALUES(9, 9, "1043468448788565", "debit", "RO22MBNKUSDHZR3M3ITCOM1R");
INSERT INTO CARDURI VALUES(10, 9, "5657771788311906", "debit", "RO99MBNKEURWUKVCW44QPFKW");
INSERT INTO CARDURI VALUES(11, 6, "5453084254217188", "credit", "RO69MBNKRONUCMVO8DIM6HW2");
INSERT INTO CARDURI VALUES(12, 8, "2550925937147248", "debit", "RO75MBNKRON2ZAMWFJO52MXZ");
INSERT INTO CARDURI VALUES(13, 3, "5365698023410467", "credit", "RO57MBNKRONOGT4YOX048OBN");
INSERT INTO CARDURI VALUES(14, 7, "1198871189486895", "credit", "RO15MBNKUSDGYXFD59VAVM98");
INSERT INTO CARDURI VALUES(15, 2, "9549917556813861", "debit", "RO63MBNKEUR9XC7R1EU6Z8R9");
INSERT INTO CARDURI VALUES(16, 3, "8844775844287937", "debit", "RO06MBNKRONG5F0ZWKDROF1I");
INSERT INTO CARDURI VALUES(17, 1, "2264136265167906", "credit", "RO60MBNKEUR6XTI8CQSHOWGM");
INSERT INTO CARDURI VALUES(18, 5, "8596085599340472", "credit", "RO99MBNKEURWUKVCW44QPFKW");
INSERT INTO CARDURI VALUES(19, 2, "2558736240251952", "debit", "RO51MBNKRON088Q6WQOE2HSO");
INSERT INTO CARDURI VALUES(20, 7, "6552975199155183", "debit", "RO57MBNKRONIDJUI1VE6VL5W");
INSERT INTO CARDURI VALUES(21, 1, "9681919471758951", "credit", "RO50MBNKUSDJ91F9NFTTLOZV");
INSERT INTO CARDURI VALUES(22, 8, "7348339934177380", "credit", "RO54MBNKUSDQEV23FQXRAFQP");
INSERT INTO CARDURI VALUES(23, 4, "4349175506816265", "debit", "RO17MBNKUSDEP5NYZC24DX9C");
INSERT INTO CARDURI VALUES(24, 6, "8564264304946985", "debit", "RO77MBNKRON1R603YN9P5H83");
INSERT INTO CARDURI VALUES(25, 7, "1427369524470347", "debit", "RO82MBNKEURIS2RKYFO6I4CR");
INSERT INTO CARDURI VALUES(26, 2, "1679983958077950", "credit", "RO35MBNKEURE443BRFN7RCUK");
INSERT INTO CARDURI VALUES(27, 2, "1924960110024728", "credit", "RO26MBNKEUR4092Q939O71CO");
INSERT INTO CARDURI VALUES(28, 5, "9310532993680551", "credit", "RO55MBNKRONAC0GX9M6P1N3Q");
INSERT INTO CARDURI VALUES(29, 7, "7177488562866751", "debit", "RO69MBNKRONUCMVO8DIM6HW2");
INSERT INTO CARDURI VALUES(30, 3, "2498115429164854", "debit", "RO81MBNKRONK59QD16184GRX");
INSERT INTO CARDURI VALUES(31, 7, "5642613627242604", "debit", "RO21MBNKRON34300KZJ006R3");
INSERT INTO CARDURI VALUES(32, 3, "3710639812795656", "debit", "RO66MBNKUSD885UDR298QM8H");
INSERT INTO CARDURI VALUES(33, 1, "8172219060512054", "debit", "RO08MBNKRON620C9JCYO27L1");
INSERT INTO CARDURI VALUES(34, 6, "2063178638544282", "credit", "RO35MBNKEURE443BRFN7RCUK");
INSERT INTO CARDURI VALUES(35, 9, "8785513162060588", "credit", "RO99MBNKEUR391F6F3Z5G53O");
INSERT INTO CARDURI VALUES(36, 4, "8759044374359868", "debit", "RO46MBNKRON5V9N9FH5P9EV9");
INSERT INTO CARDURI VALUES(37, 9, "5726971167772835", "credit", "RO08MBNKRON217DCT3NG8K10");
INSERT INTO CARDURI VALUES(38, 1, "4363794503314375", "debit", "RO61MBNKRONRJ921EZDQBBE7");
INSERT INTO CARDURI VALUES(39, 1, "2070087092325239", "debit", "RO39MBNKRONBCSIR2LQHAT86");
INSERT INTO CARDURI VALUES(40, 1, "5990455107666903", "credit", "RO09MBNKRON87ZLC3Y4FQLL2");
INSERT INTO CARDURI VALUES(41, 1, "5275247717539337", "debit", "RO71MBNKRONC60867LUXZL7Y");
INSERT INTO CARDURI VALUES(42, 1, "4096713275176902", "credit", "RO17MBNKUSDEP5NYZC24DX9C");
INSERT INTO CARDURI VALUES(43, 2, "3935880487015161", "credit", "RO93MBNKEURO00B85OA157J2");
INSERT INTO CARDURI VALUES(44, 2, "9956787802074546", "debit", "RO06MBNKRONG5F0ZWKDROF1I");
INSERT INTO CARDURI VALUES(45, 2, "9747131573481843", "credit", "RO68MBNKRONTPGEHM5LJKP4R");
INSERT INTO CARDURI VALUES(46, 2, "6451791174881882", "debit", "RO60MBNKRONR69S3YF0BV290");
INSERT INTO CARDURI VALUES(47, 2, "3022389916334930", "debit", "RO77MBNKEURBS6KH2728JSK3");
INSERT INTO CARDURI VALUES(48, 2, "2500107462756890", "debit", "RO41MBNKRON1ON77BV7AGAUR");
INSERT INTO CARDURI VALUES(49, 3, "8757300309288801", "debit", "RO77MBNKEURERTJFI2OGAIR0");
INSERT INTO CARDURI VALUES(50, 3, "9984396403110659", "credit", "RO16MBNKEURGHX03KINP67T0");
INSERT INTO CARDURI VALUES(51, 3, "9824748364203991", "debit", "RO71MBNKUSDIFHOUAA7JPJ7A ");
INSERT INTO CARDURI VALUES(52, 3, "7674095909511710", "credit", "RO63MBNKUSDYJ9NAQ6LIPOUJ");
INSERT INTO CARDURI VALUES(53, 4, "8331085097960327", "credit", "RO82MBNKRONPNR6LABG7H87S");
INSERT INTO CARDURI VALUES(54, 4, "3796266438478048", "debit", "RO88MBNKUSD0EV373HH1NF1M");
INSERT INTO CARDURI VALUES(55, 5, "2643392244285420", "credit", "RO71MBNKRONDVCQVKX7DPRK2");

-- TRANZACTII - inserare

INSERT INTO TRANZACTII VALUES(1, "RO39MBNKRONBCSIR2LQHAT86", "RO93MBNKRONODO9QOXDPNI8U", "2023-12-25 20:16:10", 2600, "RON");
INSERT INTO TRANZACTII VALUES(2, "RO23MBNKRON94XY692JI0135", "RO50MBNKUSDJ91F9NFTTLOZV", "2023-12-25 20:22:22", 5130, "RON");
INSERT INTO TRANZACTII VALUES(3, "RO36MBNKRONC9M29GOP9KGUK", "RO51MBNKRON088Q6WQOE2HSO", "2023-12-25 21:00:01", 7800, "EUR");
INSERT INTO TRANZACTII VALUES(4, "RO75MBNKRON2ZAMWFJO52MXZ", "RO06MBNKRONG5F0ZWKDROF1I", "2023-12-25 21:10:11", 1000, "USD");
INSERT INTO TRANZACTII VALUES(5, "RO74MBNKEURDLQQ6NXWYPGJV", "RO08MBNKRON620C9JCYO27L1", "2023-12-25 21:11:15", 110, "RON");
INSERT INTO TRANZACTII VALUES(6, "RO49MBNKUSDTVMR6WTJ0CKZX", "RO23MBNKRONMHSHJSQUMUBJ0", "2023-12-25 21:15:30", 25, "USD");
INSERT INTO TRANZACTII VALUES(7, "RO22MBNKUSDHZR3M3ITCOM1R", "RO75MBNKRONS6R0APAXRAFI4", "2023-12-28 19:49:16", 4700, "EUR");
INSERT INTO TRANZACTII VALUES(8, "RO57MBNKRONOGT4YOX048OBN", "RO69MBNKRONUCMVO8DIM6HW2", "2023-12-28 19:50:55", 9500, "USD");
INSERT INTO TRANZACTII VALUES(9, "RO87MBNKUSDEWM9LC4BA82I5", "RO60MBNKRONUK8EJQJDFZBU8", "2023-12-28 19:51:49", 8300, "RON");
INSERT INTO TRANZACTII VALUES(10, "RO49MBNKRONSCHC8BW5QZOF8", "RO01MBNKRONJNORRQSSSEUO7", "2023-12-28 19:52:24", 2600, "USD");
INSERT INTO TRANZACTII VALUES(11, "RO75MBNKEURVQZ5UPDJ1J4K1", "RO74MBNKEURDLQQ6NXWYPGJV", "2023-12-28 19:53:38", 530, "EUR");
INSERT INTO TRANZACTII VALUES(12, "RO69MBNKRONUCMVO8DIM6HW2", "RO22MBNKUSDHZR3M3ITCOM1R", "2023-12-28 19:54:04", 50, "RON");
INSERT INTO TRANZACTII VALUES(13, "RO66MBNKUSD885UDR298QM8H", "RO26MBNKEUR4092Q939O71CO", "2023-12-28 19:54:34", 800, "RON");
INSERT INTO TRANZACTII VALUES(14, "RO71MBNKEURQ3QM2M9T9CRQP", "RO88MBNKRONS4NO6FKH83T7R", "2023-12-28 19:55:07", 350, "EUR");
INSERT INTO TRANZACTII VALUES(15, "RO63MBNKEUR9XC7R1EU6Z8R9", "RO77MBNKEURERTJFI2OGAIR0", "2023-12-21 18:29:59", 150, "RON");
INSERT INTO TRANZACTII VALUES(16, "RO47MBNKUSDJSDBR8R17IXMO", "RO83MBNKUSDYJKUXGQ3NXAS5", "2023-12-10 17:54:53", 2300, "RON");
INSERT INTO TRANZACTII VALUES(17, "RO23MBNKRONMHSHJSQUMUBJ0", "RO41MBNKRONDTLJR9KMKTTE4 ", "2023-12-17 10:14:05", 2500, "RON");
INSERT INTO TRANZACTII VALUES(18, "RO63MBNKUSDYJ9NAQ6LIPOUJ", "RO75MBNKRON2ZAMWFJO52MXZ", "2023-12-20 09:41:09", 100, "USD");
INSERT INTO TRANZACTII VALUES(19, "RO87MBNKUSDEWM9LC4BA82I5", "RO74MBNKEUR50Y61YZAK453B", "2023-12-27 23:31:24", 14000, "USD");
INSERT INTO TRANZACTII VALUES(20, "RO93MBNKEURO00B85OA157J2", "RO18MBNKRONLOQ091GB777E9", "2023-12-24 17:07:18", 2150, "EUR");
INSERT INTO TRANZACTII VALUES(21, "RO75MBNKRON2ZAMWFJO52MXZ", "RO77MBNKEURERTJFI2OGAIR0", "2023-12-11 03:30:06", 75, "EUR");
INSERT INTO TRANZACTII VALUES(22, "RO68MBNKRONTPGEHM5LJKP4R", "RO02MBNKUSD65S1220T8B076", "2023-12-03 06:10:34", 600, "RON");
INSERT INTO TRANZACTII VALUES(23, "RO60MBNKRONR69S3YF0BV290", "RO66MBNKUSD885UDR298QM8H", "2023-12-11 17:59:16", 4600, "RON");
INSERT INTO TRANZACTII VALUES(24, "RO36MBNKRONC9M29GOP9KGUK", "RO66MBNKUSD885UDR298QM8H", "2023-12-19 14:53:10", 450, "RON");
INSERT INTO TRANZACTII VALUES(25, "RO93MBNKEURO00B85OA157J2", "RO56MBNKUSD53KDJGCM7GFTC", "2023-12-10 11:16:15", 10, "EUR");
INSERT INTO TRANZACTII VALUES(26, "RO72MBNKEURUT0A9T9OZCKDL", "RO60MBNKRONUK8EJQJDFZBU8", "2023-12-08 11:37:21", 50, "EUR");
INSERT INTO TRANZACTII VALUES(27, "RO08MBNKRON217DCT3NG8K10", "RO75MBNKEURVQZ5UPDJ1J4K1", "2023-12-13 20:23:53", 6000, "RON");
INSERT INTO TRANZACTII VALUES(28, "RO77MBNKEURBS6KH2728JSK3", "RO33MBNKEURX6F01012T5RT3", "2023-12-27 19:45:19", 1200, "EUR");
INSERT INTO TRANZACTII VALUES(29, "RO08MBNKRON217DCT3NG8K10", "RO49MBNKRONSCHC8BW5QZOF8", "2023-12-31 06:17:18", 40, "RON");
INSERT INTO TRANZACTII VALUES(30, "RO50MBNKUSDJ91F9NFTTLOZV", "RO75MBNKRONS6R0APAXRAFI4", "2023-12-10 16:38:51", 50, "USD");
INSERT INTO TRANZACTII VALUES(31, "RO60MBNKRONUK8EJQJDFZBU8", "RO06MBNKRONG5F0ZWKDROF1I", "2023-12-04 16:39:45", 100, "RON");
INSERT INTO TRANZACTII VALUES(32, "RO80MBNKRON73OOKC98WAD21", "RO02MBNKUSD65S1220T8B076", "2023-12-16 21:15:47", 4000, "RON");
INSERT INTO TRANZACTII VALUES(33, "RO84MBNKRON4XP5VHXKQX549", "RO73MBNKEURZDRJ43XYH62YR", "2023-12-18 13:10:52", 230, "RON");
INSERT INTO TRANZACTII VALUES(34, "RO71MBNKEURQ3QM2M9T9CRQP", "RO09MBNKUSDZ2Q2NQI3CF62O", "2023-12-16 03:13:29", 35, "EUR");
INSERT INTO TRANZACTII VALUES(35, "RO33MBNKEURX6F01012T5RT3", "RO41MBNKRONA1QG9290AOVLZ", "2023-12-25 08:27:35", 15, "EUR");
INSERT INTO TRANZACTII VALUES(36, "RO63MBNKEUR9XC7R1EU6Z8R9", "RO80MBNKEUR775RX0R222NZD", "2023-12-08 17:12:09", 5, "EUR");
INSERT INTO TRANZACTII VALUES(37, "RO47MBNKUSDJSDBR8R17IXMO", "RO46MBNKRON5V9N9FH5P9EV9", "2023-12-28 17:44:09", 50, "RON");
INSERT INTO TRANZACTII VALUES(38, "RO66MBNKUSD885UDR298QM8H", "RO58MBNKRONBSS9B6AC1G875", "2023-12-25 12:26:45", 150, "USD");
INSERT INTO TRANZACTII VALUES(39, "RO88MBNKUSD0EV373HH1NF1M", "RO98MBNKRONUTGDZZPQ32C5V", "2023-12-04 13:34:12", 3600, "RON");
INSERT INTO TRANZACTII VALUES(40, "RO08MBNKUSDJT2S50VMT037C", "RO75MBNKRONS6R0APAXRAFI4", "2023-12-25 16:32:52", 1200, "RON");
INSERT INTO TRANZACTII VALUES(41, "RO45MBNKUSDFDZ8T0P5EH9WC", "RO18MBNKRONLOQ091GB777E9", "2023-12-06 09:08:53", 800, "RON");
INSERT INTO TRANZACTII VALUES(42, "RO93MBNKUSDGP0O6XECWAFY6", "RO33MBNKRONTWINEGOOBBP54", "2023-12-18 12:49:26", 1000, "USD");
INSERT INTO TRANZACTII VALUES(43, "RO71MBNKRONC60867LUXZL7Y", "RO41MBNKRONDTLJR9KMKTTE4 ", "2023-12-12 18:47:49", 600, "RON");