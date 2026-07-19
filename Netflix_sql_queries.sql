CREATE DATABASE netflix_db;
USE netflix_db;

DROP TABLE netflix;
CREATE TABLE netflix 
(
	show_id	VARCHAR(6),
    type	VARCHAR(10),
    title	VARCHAR(150),
    director	VARCHAR(210),
    casts	VARCHAR(1000),
    country	VARCHAR(150),
    date_added	VARCHAR(50),
    release_year	INT,
    rating	VARCHAR(10),
    duration	VARCHAR(21),
    listed_in	VARCHAR(100),
    description VARCHAR(250)
);


LOAD DATA LOCAL INFILE "E:/MYSQL/Netflix_Data_Processing_P3/netflix_titles.csv"
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	@show_id,
    @type,
    @title,
    @director,
    @casts,
    @country,
    @date_added,
    @release_year,
    @rating,
    @duration,
    @listed_in,
    @description
)
SET
show_id  =  NULLIF(@show_id,''),  
type = NULLIF(@type,''), 
title = NULLIF(@title,''), 
director = NULLIF(@director,''), 
casts =  NULLIF(@casts,''), 
country = NULLIF(@country,''), 
date_added = NULLIF(@date_added,''), 
release_year = NULLIF(@release_year,''), 
rating = NULLIF(@rating,''), 
duration = NULLIF(@duration,''), 
listed_in = NULLIF(@listed_in,''), 
description = NULLIF(@description,''); 

SELECT COUNT(*) AS content FROM netflix;
SELECT DISTINCT type FROM netflix;

-- 15 business problems:
 
-- 1. Count the number of Movies vs TV Shows
SELECT 
	type,
    COUNT(type) AS total 
FROM netflix GROUP BY 1;

-- 2. Find the most common rating for movies and TV shows
SELECT 
	type,
    rating
FROM
(
SELECT 
    type,
	rating,
    COUNT(*),
    RANK () OVER(PARTITION BY type ORDER BY COUNT(*) DESC) as Ranking
FROM netflix
GROUP BY 1,2
) AS t1
WHERE Ranking = 1;

-- 3. List all movies released in a specific year (e.g., 2020)
SELECT 
	*
FROM netflix
WHERE type = 'Movie' AND release_year = 2020;

-- 4. Find the top 5 countries with the most content on Netflix
SELECT
    TRIM(j.country) AS new_country,
    COUNT(*) AS total_content
FROM netflix
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(country, ',', '","'), '"]'),
    '$[*]' COLUMNS (
        country VARCHAR(100) PATH '$'
    )
) AS j
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the longest movie
SELECT
    title,
    duration
FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) DESC 
LIMIT 1;

-- 6. Find content added in the last 5 years
SELECT 
	*
FROM netflix
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= CURRENT_DATE() - INTERVAL 5 YEAR;

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT 
	*
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';
-- 8. List all TV shows with more than 5 seasons
SELECT 
	title,
    duration
FROM netflix
WHERE 
	type = 'TV Show'
	AND 
	CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) > 5;
    
-- 9. Count the number of content items in each genre
SELECT
    TRIM(j.listed) AS genre,
    COUNT(*) AS total_content
FROM netflix
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(listed_in, ',', '","'), '"]'),
    '$[*]' COLUMNS (
        listed VARCHAR(100) PATH '$'
    )
) AS j
GROUP BY 1;

-- 10.Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg content release!
SELECT
    country,
    release_year,
    COUNT(*) AS total_release,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM netflix
            WHERE country = 'India'
        ),
        2
    ) AS percentage_release
FROM netflix
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY percentage_release DESC
LIMIT 5;

-- 11. List all movies that are documentaries
SELECT
	title,
    listed_in
FROM netflix
WHERE listed_in LIKE '%documentaries%';

-- 12. Find all content without a director
SELECT 
	*
FROM netflix
WHERE director IS NULL;

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT
    COUNT(*) AS total_movies
FROM netflix
WHERE type = 'Movie'
  AND casts LIKE '%Salman Khan%'
  AND release_year > YEAR(CURDATE()) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT
    TRIM(j.casts) AS casts,
    COUNT(*) AS total_content
FROM netflix
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(casts, ',', '","'), '"]'),
    '$[*]' COLUMNS (
        casts VARCHAR(100) PATH '$'
    )
) AS j
WHERE type = 'Movie' AND country LIKE '%India%'
GROUP BY 1
ORDER BY total_content DESC 
LIMIT 10;


/*15.
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

WITH temp_table
AS
(
SELECT
	*,
    CASE 
		WHEN description LIKE '%kill%' OR description LIKE '%violence%'
        THEN
			'Bad'
		ELSE
			'Good'
	END category
FROM netflix 
)
SELECT 
	category,
    count(*) as total
FROM temp_table
GROUP BY 1;
SELECT title, description
FROM netflix
WHERE description LIKE '%kill%';