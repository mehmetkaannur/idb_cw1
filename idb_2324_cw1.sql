-- Q1 returns (name,born_in,father,mother)
SELECT p1.name, p1.born_in, p2.name AS father, p3.name AS mother
FROM person p1
JOIN person p2 ON p1.father = p2.name
JOIN person p3 ON p1.mother = p3.name
WHERE p1.born_in = p2.born_in AND p1.born_in = p3.born_in
ORDER BY p1.name;

-- Q2 returns (name)
SELECT person.name
FROM person
WHERE person.name NOT IN 
(
    SELECT monarch.name 
    FROM monarch
    UNION
    SELECT prime_minister.name 
    FROM prime_minister 
)
ORDER BY person.name;

-- Q3 returns (name)
WITH KingsAndQueens AS (
  SELECT p.name, p.dod, m.accession, m.house
  FROM person p RIGHT JOIN monarch m
  ON p.name = m.name
  WHERE m.house IS NOT NULL
)
SELECT kaq1.name
FROM KingsAndQueens kaq1
WHERE EXISTS (
  SELECT 1
  FROM KingsAndQueens kaq2
  WHERE kaq2.accession > kaq1.accession
  AND kaq2.accession < kaq1.dod
)
ORDER BY kaq1.name;

-- Q4 returns (house,name,accession)
SELECT m1.house, m1.name, m1.accession
FROM monarch m1
WHERE accession = ALL(
    SELECT MIN(m2.accession)
    FROM monarch m2
    WHERE m2.house = m1.house
)
ORDER BY accession;

-- Q5 returns (name,role,start_date)
SELECT monarch.name, 'Monarch' AS role, monarch.accession AS start_date
FROM monarch
WHERE house IS NOT NULL
UNION
SELECT monarch.name, 'Lord Protector' AS role, monarch.accession AS start_date
FROM monarch
WHERE house IS NULL
UNION
SELECT prime_minister.name, 'Prime Minister' AS role, prime_minister.entry AS start_date
FROM prime_minister
ORDER BY start_date;

-- Q6 returns (first_name,popularity)
WITH NameAndPopularity AS 
(
  SELECT SPLIT_PART(name, ' ', 1) AS first_name, COUNT(*) AS popularity
  FROM person
  GROUP BY first_name HAVING COUNT(*) > 1
)
SELECT nap.first_name, nap.popularity
FROM NameAndPopularity nap
ORDER BY nap.popularity DESC, nap.first_name;

-- Q7 returns (party,seventeenth,eighteenth,nineteenth,twentieth,twentyfirst)
WITH PartyCounter AS 
(
  SELECT
    party,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1700 AND 1799) AS eighteenth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1800 AND 1899) AS nineteenth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1900 AND 1999) AS twentieth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 2000 AND 2099) AS twentyfirst
  FROM prime_minister
  GROUP BY party
)
SELECT pc.party, pc.eighteenth, pc.nineteenth, pc.twentieth, pc.twentyfirst
FROM PartyCounter pc
ORDER BY pc.party; 

-- Q8 returns (mother,child,born)
WITH MotherAndChild AS (
  SELECT person.mother AS mother, person.name AS child, person.dob AS dob
  FROM person
  WHERE person.mother IS NOT NULL
)
SELECT MotherAndChild.mother, MotherAndChild.child, 
RANK() OVER (PARTITION BY MotherAndChild.mother ORDER BY MotherAndChild.dob) AS born
FROM MotherAndChild
UNION
SELECT person.name AS mother, NULL AS child, NULL AS born
FROM person
WHERE person.gender = 'F' AND person.name NOT IN (SELECT mother FROM MotherAndChild)
ORDER BY mother, born, child;

-- Q9 returns (monarch,prime_minister)
WITH monarchs AS 
(
  SELECT m1.name AS monarch, m1.accession, COALESCE(m2.accession, CURRENT_DATE) AS succession
  FROM monarch m1 LEFT JOIN monarch m2 ON m1.name <> m2.name AND m1.accession < m2.accession
  GROUP BY m1.name, m1.accession, m2.accession
  HAVING m2.accession IS NULL OR m2.accession = MIN(m2.accession)
)
, prime_ministers AS 
(
  SELECT p1.name AS prime_minister, p1.party, p1.entry, COALESCE(p2.entry, CURRENT_DATE) AS exit
  FROM prime_minister p1 LEFT JOIN prime_minister p2 ON p1.name <> p2.name AND p1.entry < p2.entry
  GROUP BY p1.name, p1.party, p1.entry, p2.entry
  HAVING p2.entry IS NULL OR p2.entry = MIN(p2.entry)
)
SELECT m.monarch, p.prime_minister, p.party
FROM monarchs m JOIN prime_ministers p ON p.entry BETWEEN m.accession AND m.succession
OR p.exit BETWEEN m.accession AND m.succession
OR (p.entry < m.accession AND p.exit > m.succession)
ORDER BY m.accession, p.entry;

-- Q10 returns (name,entry,period,days)
WITH term_end AS (
  SELECT name, party, entry, LEAD(entry) OVER (ORDER BY entry) AS end
  FROM prime_minister
),
term_days AS (
  SELECT name, party, entry, end, 
  CASE 
    WHEN end IS NULL THEN
      DATE_PART('day', CURRENT_DATE - entry)
    ELSE
      DATE_PART('day', end - entry)
  END AS days
  FROM term_end
),
term_period AS (
  SELECT name, party, entry, end, days, 
  ROW_NUMBER() OVER (PARTITION BY name ORDER BY entry) AS period
  FROM term_days
)
SELECT name, entry, period, days
FROM term_period
ORDER BY days ASC