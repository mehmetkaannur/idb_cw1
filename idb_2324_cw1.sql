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
SELECT m1.name
FROM monarch m1
JOIN monarch m2 ON m1.name = m2.name
LEFT JOIN person p1 ON m1.name = p1.name
LEFT JOIN person p2 ON m2.name = p2.name
WHERE m1.accession < m2.accession AND p1.dod > m2.accession
ORDER BY m1.name;


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
SELECT mother.name AS mother,
       child.name AS child,
       ROW_NUMBER() OVER (PARTITION BY mother.name ORDER BY child.dob) AS born
FROM person AS mother
LEFT JOIN person AS child ON mother.name = child.mother AND mother.gender = 'F'
ORDER BY mother.name, born, child.dob, child.name;

-- Q9 returns (monarch,prime_minister)
SELECT m.name AS monarch, p.name AS prime_minister
FROM monarch m
JOIN prime_minister p ON p.entry BETWEEN m.accession AND COALESCE(m.coronation, CURRENT_DATE)
ORDER BY m.name, p.entry;
       
-- Q10 returns (name,entry,period,days)
SELECT
  pm.name,
  pm.party,
  pm.entry,
  ROW_NUMBER() OVER (PARTITION BY pm.name ORDER BY pm.entry) AS period,
  COALESCE(pm2.entry, CURRENT_DATE) AS end_date,
  TIMESTAMPDIFF(DAY, pm.entry, COALESCE(pm2.entry, CURRENT_DATE)) AS days
FROM
  prime_minister pm
  LEFT JOIN prime_minister pm2 ON pm.name = pm2.name AND pm.entry < pm2.entry
ORDER BY days;
