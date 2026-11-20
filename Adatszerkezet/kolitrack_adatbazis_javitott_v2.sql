-- =========================================================
-- KoliTrack - MySQL Adatbázis sémák és Mintaadatok
-- =========================================================

-- Adatbázis létrehozása és kiválasztása
CREATE DATABASE IF NOT EXISTS kolitrack DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_hungarian_ci;
USE kolitrack;

SET FOREIGN_KEY_CHECKS = 0;

-- Meglévő táblák törlése, ha léteznek
DROP TABLE IF EXISTS tanar_diak;
DROP TABLE IF EXISTS program_diak;
DROP TABLE IF EXISTS kerelmek;
DROP TABLE IF EXISTS rendszeres_tavolletek;
DROP TABLE IF EXISTS programok;
DROP TABLE IF EXISTS hibajelentesek;
DROP TABLE IF EXISTS tanulmanyok;
DROP TABLE IF EXISTS ertesitesek;
DROP TABLE IF EXISTS tajekoztatok;
DROP TABLE IF EXISTS diakok;
DROP TABLE IF EXISTS tanarok;
DROP TABLE IF EXISTS szobak;
DROP TABLE IF EXISTS felhasznalok;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- TÁBLÁK LÉTREHOZÁSA
-- =========================================================

CREATE TABLE felhasznalok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nev VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  jelszo VARCHAR(50) NOT NULL,
  szerepkor ENUM('diak', 'tanar', 'admin') NOT NULL,
  telefonszam VARCHAR(20),
  letrehozva DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE szobak (
  id INT AUTO_INCREMENT PRIMARY KEY,
  szam SMALLINT NOT NULL UNIQUE,
  emelet SMALLINT NOT NULL
);

CREATE TABLE tanarok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  felhasznalo_id INT NOT NULL UNIQUE,
  FOREIGN KEY (felhasznalo_id) REFERENCES felhasznalok(id) ON DELETE CASCADE
);

CREATE TABLE diakok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  felhasznalo_id INT NOT NULL UNIQUE,
  szoba_id INT NOT NULL,
  osztaly VARCHAR(10) NOT NULL,
  szulo_nev VARCHAR(100),
  szulo_telefon VARCHAR(20),
  FOREIGN KEY (felhasznalo_id) REFERENCES felhasznalok(id) ON DELETE CASCADE,
  FOREIGN KEY (szoba_id) REFERENCES szobak(id) ON DELETE RESTRICT
);

CREATE TABLE tanar_diak (
  tanar_id INT NOT NULL,
  diak_id INT NOT NULL,
  PRIMARY KEY (tanar_id, diak_id),
  FOREIGN KEY (tanar_id) REFERENCES tanarok(id) ON DELETE CASCADE,
  FOREIGN KEY (diak_id) REFERENCES diakok(id) ON DELETE CASCADE
);

CREATE TABLE rendszeres_tavolletek (
  id INT AUTO_INCREMENT PRIMARY KEY,
  diak_id INT NOT NULL,
  engedelyezo_tanar_id INT NOT NULL,
  ok VARCHAR(255) NOT NULL,
  nap TINYINT NOT NULL COMMENT '1 = hétfő ... 7 = vasárnap',
  kezdes TIME NOT NULL,
  vege TIME NOT NULL,
  ervenyes_tol DATE NOT NULL,
  ervenyes_ig DATE NOT NULL,
  FOREIGN KEY (diak_id) REFERENCES diakok(id) ON DELETE CASCADE,
  FOREIGN KEY (engedelyezo_tanar_id) REFERENCES tanarok(id) ON DELETE RESTRICT
);

CREATE TABLE kerelmek (
  id INT AUTO_INCREMENT PRIMARY KEY,
  diak_id INT NOT NULL,
  tipus ENUM('kimeno', 'hianyzas') NOT NULL,
  indoklas TEXT NOT NULL,
  tavozas DATETIME NOT NULL,
  erkezes DATETIME NOT NULL,
  statusz ENUM('fuggoben', 'jovahagyva', 'elutasitva') NOT NULL DEFAULT 'fuggoben',
  elbiralo_tanar_id INT NOT NULL,
  elbiralva DATETIME,
  rendszeres_tavollet_id INT NOT NULL,
  letrehozva DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (diak_id) REFERENCES diakok(id) ON DELETE CASCADE,
  FOREIGN KEY (elbiralo_tanar_id) REFERENCES tanarok(id) ON DELETE RESTRICT,
  FOREIGN KEY (rendszeres_tavollet_id) REFERENCES rendszeres_tavolletek(id) ON DELETE RESTRICT
);

CREATE TABLE programok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  letrehozo_tanar_id INT NOT NULL,
  nev VARCHAR(150) NOT NULL,
  leiras TEXT,
  helyszin VARCHAR(150),
  kezdes DATETIME NOT NULL,
  kotelezo BOOLEAN NOT NULL DEFAULT FALSE,
  mindenkinek BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'false = csak a program_diak-ban szereplő diákoknak',
  FOREIGN KEY (letrehozo_tanar_id) REFERENCES tanarok(id) ON DELETE CASCADE
);

CREATE TABLE program_diak (
  program_id INT NOT NULL,
  diak_id INT NOT NULL,
  jelentkezett DATETIME COMMENT 'NULL = csak meghívott',
  resztvett BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (program_id, diak_id),
  FOREIGN KEY (program_id) REFERENCES programok(id) ON DELETE CASCADE,
  FOREIGN KEY (diak_id) REFERENCES diakok(id) ON DELETE CASCADE
);

CREATE TABLE hibajelentesek (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bejelento_id INT NOT NULL,
  szoba_id INT NOT NULL,
  helyszin VARCHAR(150) COMMENT 'ha nem szobában van a hiba',
  leiras TEXT NOT NULL,
  statusz ENUM('uj', 'folyamatban', 'megoldva') NOT NULL DEFAULT 'uj',
  letrehozva DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (bejelento_id) REFERENCES felhasznalok(id) ON DELETE CASCADE,
  FOREIGN KEY (szoba_id) REFERENCES szobak(id) ON DELETE RESTRICT
);

CREATE TABLE tanulmanyok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  diak_id INT NOT NULL,
  tantargy VARCHAR(100) NOT NULL,
  jegy TINYINT NOT NULL,
  datum DATE NOT NULL,
  FOREIGN KEY (diak_id) REFERENCES diakok(id) ON DELETE CASCADE
);

CREATE TABLE ertesitesek (
  id INT AUTO_INCREMENT PRIMARY KEY,
  felhasznalo_id INT NOT NULL,
  cim VARCHAR(150) NOT NULL,
  uzenet TEXT,
  olvasva BOOLEAN NOT NULL DEFAULT FALSE,
  letrehozva DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (felhasznalo_id) REFERENCES felhasznalok(id) ON DELETE CASCADE
);

CREATE TABLE tajekoztatok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  szerzo_tanar_id INT NOT NULL,
  cim VARCHAR(150) NOT NULL,
  tartalom TEXT NOT NULL,
  letrehozva DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (szerzo_tanar_id) REFERENCES tanarok(id) ON DELETE CASCADE
);

-- =========================================================
-- MINTAADATOK BESZÚRÁSA
-- =========================================================

-- Szobák
INSERT INTO szobak (szam, emelet) VALUES
(101, 1), (102, 1), (103, 1),
(201, 2), (202, 2);

-- Felhasználók (1 Admin, 2 Tanár, 3 Diák)
INSERT INTO felhasznalok (nev, email, jelszo, szerepkor, telefonszam) VALUES
('Rendszer Admin', 'admin@kolitrack.hu', 'admin123', 'admin', '+36301234567'),
('Kovács Nevelő', 'kovacs.nevelo@kolitrack.hu', 'tanar123', 'tanar', '+36201112233'),
('Szabó Nevelő', 'szabo.nevelo@kolitrack.hu', 'tanar123', 'tanar', '+36202223344'),
('Nagy Péter', 'nagy.peter@diak.hu', 'diak123', 'diak', '+36709876543'),
('Tóth Anna', 'toth.anna@diak.hu', 'diak123', 'diak', '+36701239876'),
('Horváth Bence', 'horvath.bence@diak.hu', 'diak123', 'diak', '+36308761234');

-- Tanárok
INSERT INTO tanarok (felhasznalo_id) VALUES
(2), (3);

-- Diákok
INSERT INTO diakok (felhasznalo_id, szoba_id, osztaly, szulo_nev, szulo_telefon) VALUES
(4, 1, '10.A', 'Nagy Gábor', '+36301112222'),
(5, 4, '9.B', 'Tóthné Mária', '+36303334444'),
(6, 2, '11.C', 'Horváth István', '+36305556666');

-- Nevelőtanár - Diák összerendelés (N:M)
INSERT INTO tanar_diak (tanar_id, diak_id) VALUES
(1, 1), (1, 2), -- Kovács Nevelő (ID 1) diákjai
(2, 3);         -- Szabó Nevelő (ID 2) diákja

-- Rendszeres távollétek
INSERT INTO rendszeres_tavolletek (diak_id, engedelyezo_tanar_id, ok, nap, kezdes, vege, ervenyes_tol, ervenyes_ig) VALUES
(1, 1, 'Foci edzés', 2, '16:00:00', '18:00:00', '2023-09-01', '2024-06-15'),
(2, 1, 'Zeneiskola', 4, '15:30:00', '17:00:00', '2023-09-01', '2024-06-15');

-- Kérelmek
INSERT INTO kerelmek (diak_id, tipus, indoklas, tavozas, erkezes, statusz, elbiralo_tanar_id, elbiralva, rendszeres_tavollet_id) VALUES
(1, 'kimeno', 'Foci edzésre megyek', '2023-11-21 15:45:00', '2023-11-21 18:15:00', 'jovahagyva', 1, '2023-11-20 10:00:00', 1),
(3, 'hianyzas', 'Családi okok', '2023-11-24 14:00:00', '2023-11-26 18:00:00', 'fuggoben', 2, NULL, 1);

-- Programok
INSERT INTO programok (letrehozo_tanar_id, nev, leiras, helyszin, kezdes, kotelezo, mindenkinek) VALUES
(1, 'Kollégiumi gyűlés', 'Havi kötelező megbeszélés', 'Díszterem', '2023-12-01 19:00:00', TRUE, TRUE),
(2, 'Társasjáték est', 'Szabadon választható játékos est', 'Klubszoba', '2023-11-25 18:00:00', FALSE, FALSE);

-- Program - Diák összerendelés
INSERT INTO program_diak (program_id, diak_id, jelentkezett, resztvett) VALUES
(1, 1, NULL, FALSE), (1, 2, NULL, FALSE), (1, 3, NULL, FALSE),
(2, 2, '2023-11-20 14:30:00', FALSE),
(2, 3, '2023-11-20 16:45:00', FALSE);

-- Hibajelentések
INSERT INTO hibajelentesek (bejelento_id, szoba_id, helyszin, leiras, statusz) VALUES
(4, 1, NULL, 'A radiátor csöpög a 101-es szobában.', 'uj'),
(5, 4, 'Folyosó 2. emelet', 'Kiégett a villanykörte.', 'folyamatban');

-- Tanulmányok
INSERT INTO tanulmanyok (diak_id, tantargy, jegy, datum) VALUES
(1, 'Matematika', 4, '2023-11-15'),
(2, 'Történelem', 5, '2023-11-18'),
(3, 'Fizika', 3, '2023-11-19');

-- Értesítések
INSERT INTO ertesitesek (felhasznalo_id, cim, uzenet, olvasva) VALUES
(4, 'Kérelem elfogadva', 'A kimenő kérelmedet jóváhagyták.', FALSE),
(5, 'Új program', 'Új program került meghirdetésre: Társasjáték est.', TRUE);

-- Tájékoztatók
INSERT INTO tajekoztatok (szerzo_tanar_id, cim, tartalom) VALUES
(1, 'Házirend frissítés', 'A kimenő kéréseket ezentúl 24 órával előre kell leadni.');
