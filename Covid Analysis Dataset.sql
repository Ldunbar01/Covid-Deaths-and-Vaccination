--Viewing Covid Deaths Dataset
SELECT *
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
ORDER BY 3,4

--Viewing Covid Vaccination Dataset
SELECT *
FROM `covid-deaths-and-vaccines-data.covid_vaccines.cv-dataset`
ORDER BY 3,4

--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
WHERE location LIKE 'United States'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of the population got covid 
SELECT location, date, population, total_cases, (total_cases/population)*100 AS DeathPercentage
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
WHERE location LIKE 'United States'
ORDER BY 1,2

--Looking at Countries with the Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectedCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
WHERE location LIKE 'United States'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--Breaking Down by Continent
--Showing Countries with the Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int64)) AS TotalDeathCount
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Global Numbers
SELECT date, SUM(new_cases) AS total_cases,SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset`
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Showing Total Population vs Vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location)
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset` AS cd
JOIN `covid-deaths-and-vaccines-data.covid_vaccines.cv-dataset` AS cv
  ON cd.location = cv.location
  AND cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2,3

--Using CTE

WITH PopvsVac AS (
  SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations, 
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
  FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset` AS cd
  JOIN `covid-deaths-and-vaccines-data.covid_vaccines.cv-dataset` AS cv
    ON cd.location = cv.location
    AND cd.date = cv.date
  WHERE cd.continent IS NOT NULL
)
SELECT 
  continent, 
  location, 
  date, 
  population, 
  new_vaccinations, 
  RollingPeopleVaccinated, 
  (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM PopvsVac;

--Temporary Table

WITH PercentPopulationVaccinated AS (
    SELECT 
        cd.continent, 
        cd.location, 
        cd.date, 
        cd.population, 
        cv.new_vaccinations, 
        SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
    FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset` AS cd
    JOIN `covid-deaths-and-vaccines-data.covid_vaccines.cv-dataset` AS cv
        ON cd.location = cv.location
        AND cd.date = cv.date
)

SELECT *, 
       (RollingPeopleVaccinated / NULLIF(population, 0)) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

--Creating view to store data for later visualizations

CREATE VIEW `covid-deaths-and-vaccines-data.covid_vaccines.PercentPopulationVaccinated` AS
SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations, 
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
FROM `covid-deaths-and-vaccines-data.covid_deaths.cd-dataset` AS cd
JOIN `covid-deaths-and-vaccines-data.covid_vaccines.cv-dataset` AS cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT *
FROM `covid-deaths-and-vaccines-data.covid_vaccines.PercentPopulationVaccinated`