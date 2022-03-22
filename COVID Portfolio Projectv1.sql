-- Datasource: https://ourworldindata.org/covid-deaths
-- Updated date: 22/03/2022
-- Analyzed by: Khanh Nguyen

/* There are 2 tables:  CovidDeath and CovidVaccination
First look at data
*/

Select * 
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 3,4

Select * 
FROM PortfolioProject..CovidVaccination
ORDER BY 3,4

-- Select Data 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying in VietNam

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE location like '%Viet%nam' AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID -- location is Vietnam

SELECT Location, date, population, total_cases,CAST((total_cases/population)*100 AS numeric(38,4)) AS CovidPercentage
FROM PortfolioProject..CovidDeath
WHERE location like '%Viet%nam' AND continent IS NOT NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS highestinfectionaccount, CONVERT(numeric(38,4),MAX((total_cases/population))*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing countries with highest death count per population

SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
-- There are errors in the continent value as I excluded the NULL value. North America = United States


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS totalcases, SUM(CAST(new_deaths AS INT)) AS totaldeath
, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT Location, date, total_vaccinations
FROM PortfolioProject..CovidVaccination
WHERE location like '%Viet%nam' AND continent IS NOT NULL
ORDER BY 1,2


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


-- Creating View to store data for later visualization
-- VIEW of PercentPopulationVaccinated
CREATE VIEW PercenPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeath dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercenPopulationVaccinated

-- VIEW of Total_Vaccinations by countries
CREATE VIEW TotalVaccinationCountries AS
SELECT Location, date, total_vaccinations
FROM PortfolioProject..CovidVaccination
WHERE continent IS NOT NULL

SELECT * 
FROM TotalVaccinationCountries
ORDER BY Location, date
