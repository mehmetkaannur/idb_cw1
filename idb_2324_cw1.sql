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
WHERE person.name NOT IN (
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
SELECT m1.name, 'Monarch' AS role, m1.accession AS start_date
FROM monarch m1
WHERE house IS NOT NULL
UNION
SELECT m2.name, 'Lord Protector' AS role, m2.accession AS start_date
FROM monarch m2
WHERE house IS NULL
UNION
SELECT pm1.name, 'Prime Minister' AS role, pm1.entry AS start_date
FROM prime_minister pm1
ORDER BY start_date;

-- Q6 returns (first_name,popularity)
WITH NameAndPopularity AS (
  SELECT SPLIT_PART(name, ' ', 1) AS first_name, COUNT(*) AS popularity
  FROM person
  GROUP BY first_name HAVING COUNT(*) > 1
)
SELECT nap.first_name, nap.popularity
FROM NameAndPopularity nap
ORDER BY nap.popularity DESC, nap.first_name;

-- Q7 returns (party,seventeenth,eighteenth,nineteenth,twentieth,twentyfirst)
WITH PartyCounter AS (
  SELECT party,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1700 AND 1799) 
      AS eighteenth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1800 AND 1899) 
      AS nineteenth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 1900 AND 1999) 
      AS twentieth,
    COUNT(*) FILTER(WHERE EXTRACT(YEAR FROM entry) BETWEEN 2000 AND 2099) 
      AS twentyfirst
  FROM prime_minister
  GROUP BY party
)
SELECT pc.party, pc.eighteenth, pc.nineteenth, pc.twentieth, pc.twentyfirst
FROM PartyCounter pc
ORDER BY pc.party; 

-- Q8 returns (mother,child,born)
WITH MotherChild AS (
  SELECT p1.mother AS mother, p1.name AS child, p1.dob AS dob
  FROM person p1
  WHERE p1.mother IS NOT NULL
)
SELECT mc.mother, mc.child, 
  RANK() OVER (PARTITION BY mc.mother ORDER BY mc.dob) AS born
FROM MotherChild mc
UNION
SELECT p2.name AS mother, NULL AS child, NULL AS born
FROM person p2
WHERE p2.gender = 'F' AND p2.name NOT IN (SELECT mother FROM MotherChild)
ORDER BY mother, born, child;

-- Q9 returns (monarch,prime_minister)
SELECT DISTINCT mt.name AS monarch, pmt.name AS prime_minister
FROM(
  SELECT name, accession, 
    COALESCE(LEAD(accession) OVER (ORDER BY accession), '9999-12-31') AS NextAccession
  FROM monarch
) AS MonarchTable mt
JOIN (
  SELECT name, entry, 
    COALESCE(LEAD(entry) OVER (ORDER BY entry), '9999-12-31') AS NextEntry
  FROM prime_minister
) AS PMtable pmt
ON (pmt.entry >= mt.accession AND pmt.entry < mt.NextAccession)
  OR (pmt.entry <= mt.accession AND pmt.NextEntry > mt.accession)
ORDER BY monarch, prime_minister;

-- Q10 returns (name,entry,period,days)
WITH EndOfTerm AS (
  SELECT name, party, entry, LEAD(entry) OVER (ORDER BY entry) AS term_end
  FROM prime_minister
),
DayCounter AS (
  SELECT name, party, entry, term_end, 
  CASE 
    WHEN term_end IS NULL
    THEN
      CAST(CURRENT_DATE AS date) - CAST(entry AS date)
    ELSE
      CAST(term_end AS date) - CAST(entry AS date)
  END AS days
  FROM EndOfTerm
),
PeriodCounter AS (
  SELECT name, party, entry, term_end, days, 
    ROW_NUMBER() OVER (PARTITION BY name ORDER BY entry) AS period
  FROM DayCounter
)
SELECT name, entry, period, days
FROM PeriodCounter
ORDER BY days;