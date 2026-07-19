# 🎬 Netflix Movies and TV Shows Data Analysis using SQL

<p align="center">
  <img width="100%" alt="Netflix Logo" src="https://github.com/user-attachments/assets/3fa4f98f-55b1-4683-9566-5e35b80eadbd">
</p>

## 📖 Overview

This project analyzes the **Netflix Movies and TV Shows** dataset using **MySQL** to answer real-world business questions and extract meaningful insights. The analysis explores trends in content distribution, ratings, release years, countries, genres, directors, actors, and other important attributes.

The project demonstrates the practical use of SQL concepts such as:

- Data Import & Cleaning
- Aggregate Functions
- GROUP BY & HAVING
- Window Functions
- Common Table Expressions (CTEs)
- JSON_TABLE()
- Date Functions
- String Functions
- Conditional Logic (CASE)
- Subqueries

---

# 🎯 Objectives

The primary objectives of this project are to:

- Analyze the distribution of Movies and TV Shows available on Netflix.
- Identify the most common content ratings across different content types.
- Explore content based on release year, country, duration, genre, director, and cast.
- Perform country-wise and genre-wise content analysis.
- Extract insights using SQL aggregations, window functions, and CTEs.
- Practice solving real-world business problems using SQL.
- Demonstrate data cleaning and preprocessing during CSV import.
- Build a portfolio-ready SQL project showcasing intermediate to advanced SQL skills.

---

# 📂 Dataset

The dataset used in this project is publicly available on Kaggle.

**Dataset:** Netflix Movies and TV Shows

https://www.kaggle.com/datasets/shivamb/netflix-shows

---

# 🛠️ Database Schema

```sql
CREATE DATABASE netflix_db;
USE netflix_db;

CREATE TABLE netflix
(
    show_id VARCHAR(6),
    type VARCHAR(10),
    title VARCHAR(150),
    director VARCHAR(210),
    casts VARCHAR(1000),
    country VARCHAR(150),
    date_added VARCHAR(50),
    release_year INT,
    rating VARCHAR(10),
    duration VARCHAR(21),
    listed_in VARCHAR(100),
    description VARCHAR(250)
);
```

---

# 📥 Import Dataset

```sql
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
show_id = NULLIF(@show_id,''),
type = NULLIF(@type,''),
title = NULLIF(@title,''),
director = NULLIF(@director,''),
casts = NULLIF(@casts,''),
country = NULLIF(@country,''),
date_added = NULLIF(@date_added,''),
release_year = NULLIF(@release_year,''),
rating = NULLIF(@rating,''),
duration = NULLIF(@duration,''),
listed_in = NULLIF(@listed_in,''),
description = NULLIF(@description,'');

SELECT COUNT(*) AS content
FROM netflix;
```

---

# 📊 Business Problems and Solutions

## **1. Count the number of Movies vs TV Shows**

```sql
SELECT
    type,
    COUNT(type) AS total
FROM netflix
GROUP BY 1;
```

---

## **2. Find the most common rating for Movies and TV Shows**

```sql
SELECT
    type,
    rating
FROM
(
SELECT
    type,
    rating,
    COUNT(*),
    RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS Ranking
FROM netflix
GROUP BY 1,2
) AS t1
WHERE Ranking = 1;
```

---

## **3. List all Movies released in a specific year (2020)**

```sql
SELECT *
FROM netflix
WHERE type = 'Movie'
AND release_year = 2020;
```

---

## **4. Find the Top 5 countries with the most content on Netflix**

```sql
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
```

---

## **5. Identify the longest Movie**

```sql
SELECT
    title,
    duration
FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) DESC
LIMIT 1;
```

---

## **6. Find content added in the last 5 years**

```sql
SELECT *
FROM netflix
WHERE STR_TO_DATE(date_added,'%M %d, %Y')
>= CURRENT_DATE() - INTERVAL 5 YEAR;
```

---

## **7. Find all Movies and TV Shows directed by Rajiv Chilaka**

```sql
SELECT *
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';
```

---

## **8. List all TV Shows with more than 5 seasons**

```sql
SELECT
    title,
    duration
FROM netflix
WHERE type='TV Show'
AND CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) > 5;
```

---

## **9. Count the number of content items in each genre**

```sql
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
```

---

## **10. Find each year and the percentage of content released in India. Return the Top 5 years.**

```sql
SELECT
    country,
    release_year,
    COUNT(*) AS total_release,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM netflix
            WHERE country='India'
        ),
        2
    ) AS percentage_release
FROM netflix
WHERE country='India'
GROUP BY country,release_year
ORDER BY percentage_release DESC
LIMIT 5;
```

---

## **11. List all Documentary Movies**

```sql
SELECT
    title,
    listed_in
FROM netflix
WHERE listed_in LIKE '%documentaries%';
```

---

## **12. Find all content without a director**

```sql
SELECT *
FROM netflix
WHERE director IS NULL;
```

---

## **13. Find how many Movies Salman Khan appeared in during the last 10 years**

```sql
SELECT
    COUNT(*) AS total_movies
FROM netflix
WHERE type='Movie'
AND casts LIKE '%Salman Khan%'
AND release_year > YEAR(CURDATE())-10;
```

---

## **14. Find the Top 10 actors appearing in the highest number of Indian Movies**

```sql
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
WHERE type='Movie'
AND country LIKE '%India%'
GROUP BY 1
ORDER BY total_content DESC
LIMIT 10;
```

---

## **15. Categorize content based on the keywords 'kill' and 'violence' in the description**

```sql
WITH temp_table AS
(
SELECT
    *,
    CASE
        WHEN description LIKE '%kill%'
          OR description LIKE '%violence%'
        THEN 'Bad'
        ELSE 'Good'
    END AS category
FROM netflix
)

SELECT
    category,
    COUNT(*) AS total
FROM temp_table
GROUP BY 1;
```

---

# 💡 SQL Concepts Used

- DDL Commands
- LOAD DATA LOCAL INFILE
- Aggregate Functions
- GROUP BY
- HAVING
- ORDER BY
- LIMIT
- Window Functions (RANK)
- Common Table Expressions (CTEs)
- CASE Statements
- JSON_TABLE()
- Date Functions
- String Functions
- Subqueries

---

# 📌 Key Insights

- Netflix offers significantly more Movies than TV Shows.
- TV Shows and Movies have different dominant maturity ratings.
- The United States and India contribute a substantial portion of Netflix's catalog.
- Documentaries form a significant content category.
- Some titles do not have director information available.
- Long-running TV Shows (more than five seasons) represent a relatively small portion of the library.
- Indian cinema features several recurring actors with multiple Netflix titles.

---

# 🚀 Skills Demonstrated

- SQL Query Writing
- Data Cleaning
- Data Analysis
- Business Problem Solving
- Window Functions
- CTEs
- JSON Data Handling
- Date Manipulation
- Database Design
- MySQL Workbench
