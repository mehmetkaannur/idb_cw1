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
JOIN monarch successor ON m.accession < successor.accession
                      AND (m.coronation IS NULL OR m.coronation < successor.accession)
                      AND (m.dod IS NULL OR m.dod > successor.accession)
ORDER BY m.name;

-- Q4 returns (house,name,accession)

;

-- Q5 returns (name,role,start_date)

;

-- Q6 returns (first_name,popularity)

;

-- Q7 returns (party,seventeenth,eighteenth,nineteenth,twentieth,twentyfirst)

; 

-- Q8 returns (mother,child,born)

;

-- Q9 returns (monarch,prime_minister)

;
       
-- Q10 returns (name,entry,period,days)

;

