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
SELECT m.name
FROM monarch m
WHERE m.name <> (SELECT MAX(name) FROM monarch)
AND NOT EXISTS (SELECT 1 FROM monarch s WHERE s.house = m.house AND s.accession > m.accession)
ORDER BY m.name;


-- Q4 returns (house,name,accession)
SELECT m1.house, m1.name, m1.accession
FROM monarch m1
WHERE accession = ALL 
(
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
WITH mother_child AS (
  SELECT person.mother AS mother, person.name AS child, person.dob AS dob
  FROM person
  WHERE person.mother IS NOT NULL
)
SELECT mother_child.mother, mother_child.child, RANK() OVER (PARTITION BY mother_child.mother ORDER BY mother_child.dob) AS born
FROM mother_child
UNION
SELECT person.name AS mother, NULL AS child, NULL AS born
FROM person
WHERE person.gender = 'F' AND person.name NOT IN (SELECT mother FROM mother_child)
ORDER BY mother, born, child;

-- Q9 returns (monarch,prime_minister)
SELECT m.name AS monarch, p.name AS prime_minister
FROM monarch m
JOIN prime_minister p ON p.entry BETWEEN m.accession AND COALESCE(
  (SELECT accession FROM monarch m2 WHERE m2.accession > m.accession ORDER BY accession LIMIT 1),
  CURRENT_DATE
)
ORDER BY m.accession, p.entry;
       
-- Q10 returns (name,entry,period,days)
WITH current_date AS (
  SELECT DATE '2023-11-12' AS today
),
next_entry AS (
  SELECT p1.name, p1.entry, MIN(p2.entry) AS next_entry
  FROM prime_minister p1
  LEFT JOIN prime_minister p2
  ON p1.name <> p2.name AND p1.entry < p2.entry
  GROUP BY p1.name, p1.entry
),
days_in_office AS 
(
  SELECT n.name, n.entry, n.next_entry, 
  CASE
    WHEN n.next_entry IS NULL THEN c.today - n.entry -- Current prime minister
    ELSE n.next_entry - n.entry -- Previous prime ministers
  END AS days
  FROM next_entry n
  CROSS JOIN current_date c
),
periods AS (
  SELECT d.name, d.entry, d.days, 
  ROW_NUMBER() OVER (PARTITION BY d.name ORDER BY d.entry) AS period
  FROM days_in_office d
)
SELECT p.name, p.entry, p.period, p.days
FROM periods p
ORDER BY p.days;