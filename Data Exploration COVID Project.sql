-- Datasource: https://ourworldindata.org/covid-deaths
-- Updated date: 22/03/2022
-- Analyzed by: Khanh Nguyen

/* There are 2 tables:  CovidDeath and CovidVaccination
1. First look at data
*/

SELECT * 
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccination
WHERE continent IS NOT NULL
ORDER BY 3,4

-- 2. Looking at different continents, countries

SELECT continent, location, count (*)
FROM PortfolioProject..CovidDeath
-- WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 1

-- 3. 
-- Select Data 

SELECT location, date, population, total_cases, total_deaths, new_cases, new_deaths
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- 4.
-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying after being infected

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1,2


-- 5.
-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID

SELECT Location, date, population, total_cases,CAST((total_cases/population)*100 AS numeric(38,4)) AS InfectedPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1,2

-- 6.
-- Show the percentage of infected cases on the population

SELECT Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected desc

-- 7. Calculate the world population

WITH country_pop AS 
(SELECT DISTINCT location, max(population) AS countrypopulation
		FROM PortfolioProject..CovidDeath
		WHERE continent IS NOT NULL
		GROUP BY location)
SELECT sum(countrypopulation) AS worldpopulation FROM country_pop

-- 8. General number (total cases, total deaths, total vaccinations) - Tableau 1

CREATE VIEW generalnumber AS
SELECT SUM(CAST(dea.new_cases AS bigint)) AS totalcases
		, SUM(CAST(dea.new_deaths AS bigint)) AS totaldeaths
		, SUM(CAST(vac.new_vaccinations AS bigint)) AS totalvaccine
		, (SUM(CAST(dea.new_deaths AS numeric(38,4)))/SUM(CAST(dea.new_cases AS numeric(38,4))))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath dea
INNER JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

-- 9. Total cases/Population Table 2

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC

-- 9. Total fully vacinated people/Population Table 3

SELECT dea.location, dea.population, dea.date, MAX(vac.people_fully_vaccinated) AS Highestvacinatedpeople
		, MAX((vac.people_fully_vaccinated/dea.population)) AS PercentFullyvacinated
FROM PortfolioProject..CovidDeath dea
INNER JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population, dea.date
ORDER BY PercentFullyvacinated DESC

-- 10. Total cases and total fully vacinated people Table 4

SELECT dea.location, dea.population, dea.date
		, MAX(dea.total_cases) AS HighestInfectionCount, MAX((dea.total_cases/dea.population)) AS PercentPopulationInfected
		,MAX(vac.people_fully_vaccinated) AS Highestvacinatedpeople
		, MAX((vac.people_fully_vaccinated/dea.population)) AS PercentFullyvacinated
FROM PortfolioProject..CovidDeath dea
INNER JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population, dea.date
ORDER BY PercentFullyvacinated DESC


-- 11. Others exploration.
-- JOIN 2 TABLES AND USE CTE TO CALCULATE ROLLING TOTAL OF VACCINATIONS

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeath dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentagePPLVaccinated
FROM PopvsVac
-- In VIETNAM
WHERE location like '%Viet%nam' ;


-- USING TEMP TABLE

DROP TABLE IF EXISTS #PercenPopulationVaccinated
CREATE TABLE #PercenPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime2,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercenPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeath dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercenPopulationVaccinated