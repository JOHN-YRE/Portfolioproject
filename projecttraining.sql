	SELECT location,date, total_cases, new_cases, total_deaths, population
	FROM [dbo].[coviddeath2]
	ORDER BY 2,1

--HOW many cases are there in this country and how many died; total case vs total death
SELECT location,date, total_cases, new_cases, total_deaths, (CAST (total_deaths AS FLOAT)/(total_cases)) *100 AS  deathpercentages
FROM [dbo].[coviddeath2]
ORDER BY 1,2 

--shows the likelihood of dying if you have covid in your country
SELECT location,date, total_cases, new_cases, total_deaths,(CAST (total_deaths AS FLOAT)/(total_cases)) *100 AS  deathpercentages
FROM [dbo].[coviddeath2]
WHERE location LIKE '%Nigeria%'
ORDER BY 1,2 

--looking at total cases vs population
--shows what percentage of population got covid
SELECT location,date, total_cases, new_cases, population, (total_cases/population) *100 AS  percentofpopulation
FROM [dbo].[coviddeath2]
WHERE location LIKE '%Nigeria%'
ORDER BY 1,2 

--when we want to look at the highest number of infected in a country to the general world population 
--looking at countries with highest iinfection rate compared to population
SELECT location, population, MAX(total_cases) as highinfectioncount,  MAX ((total_cases/population)) *100 AS  percentpopulationinfected
FROM [dbo].[coviddeath2]
--WHERE location LIKE '%Nigeria%'
GROUP BY location, population
ORDER BY percentpopulationinfected desc

--looking at countries with highest death compared to population
SELECT location, MAX(total_deaths) as highdeathcount
FROM [dbo].[coviddeath2]
--WHERE location LIKE '%Nigeria%'
WHERE continent is not null
GROUP BY location
ORDER BY highdeathcount desc

--LOOK ATAN FROM THE CONTIENT ANGLE
SELECT continent, MAX(total_deaths) as highdeathcount
FROM [dbo].[coviddeath2]
--WHERE location LIKE '%Nigeria%'
WHERE continent is NOT null
GROUP BY continent
ORDER BY highdeathcount desc

--GLOBAL NUMBER

SELECT  SUM(new_cases) as total_cases, SUM(new_deaths) as total_death 
FROM [dbo].[coviddeath2]
where continent is not null


--to join vaccination and death table
SELECT *
FROM [dbo].[coviddeath2] AS dea
JOIN [dbo].[covidvaccination2] AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--looking at total population vs vaccination, how many pple got vaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.Date) AS RollingpeopleVaccinated
FROM [dbo].[coviddeath2] AS dea
JOIN [dbo].[covidvaccination2] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;	
--we have the rollingpeoplevaccinated above, that is number of pple vaccinated in day 1 plus day 2 etc but to use the max number at the end of each country
--to get the percentage numbeer of people vaccinated vs total popuulation in that country we then create a CTE or a temp table because we can't use
--the new coulmn name created which is rollingpeoplevaccinated in this case

--using CTE
WITH popvsvac(continent, location, date, population, new_vaccination, RollingpeopleVaccinated)
AS
(
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.Date) AS RollingpeopleVaccinated
FROM [dbo].[coviddeath2] AS dea
JOIN [dbo].[covidvaccination2] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;	
)

SELECT *, (RollingpeopleVaccinated/population)*100 AS PERCENTAGEPEOPLEVACCCINATED
FROM popvsvac
--now that we have created the cte table we can then do the caculation

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION 

CREATE VIEW percentpopulationvaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.Date) AS RollingpeopleVaccinated
FROM [dbo].[coviddeath2] AS dea
JOIN [dbo].[covidvaccination2] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;	

SELECT *
FROM percentpopulationvaccinated

--JUST  as above create more views