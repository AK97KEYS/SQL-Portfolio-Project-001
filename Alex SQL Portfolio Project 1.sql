
select * from [dbo].[CovidDeaths csv];

select * from [dbo].[CovidVaccinations csv];

-- To filter out World and the 7 continent names from our location column.

select * from [dbo].[CovidDeaths csv]
where continent is not null;

-- Selecting the data to be used for the project

select location, date, total_cases, new_cases, total_deaths, population from [dbo].[CovidDeaths csv]
where continent is not null;

-- Total Cases vs Total Deaths
-- This shows the likelihood of dying if one contacts Covid in his/her country.

alter table [dbo].[CovidDeaths csv]
alter column total_cases float;

alter table [dbo].[CovidDeaths csv]
alter column total_deaths float;

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 'DeathRate%' from [dbo].[CovidDeaths csv] where continent is not null;

-- Total Cases vs Population
-- This shows the percentage of the entire population that contracted Covid.

alter table [dbo].[CovidDeaths csv]
alter column population float;

select location, date, population, total_cases, (total_cases/population)*100 'CasePerPopulationRate%' from [dbo].[CovidDeaths csv]
where continent is not null;

-- Countries with Highest Infection Rate Compared to Population.

select location, date, population, total_cases, (total_cases/population)*100 'CasePerPopulationRate%' from [dbo].[CovidDeaths csv]
where continent is not null
order by date, 'CasePerPopulationRate%' desc;

select location, date, population, total_cases, (total_cases/population)*100 'CasePerPopulationRate%' from [dbo].[CovidDeaths csv]
where continent is not null
order by 'CasePerPopulationRate%' desc;

select location, population, max (total_cases) HighestInfectionCount, max ((total_cases/population)*100) 'CasePerPopulationRate%' from [dbo].[CovidDeaths csv]
where continent is not null
group by location, population
order by 'CasePerPopulationRate%' desc;

-- The Countries with the Highest Death Count per Population.

select location, population, max (total_deaths) HighestDeathCount, max ((total_deaths/population)*100) 'DeathPerPopulationRate%' from [dbo].[CovidDeaths csv]
where continent is not null
group by location, population
order by 'DeathPerPopulationRate%' desc;

select location, population, max (total_deaths) HighestDeathCount, max ((total_deaths/total_cases)*100) 'DeathRate%' from [dbo].[CovidDeaths csv]
where continent is not null
group by location, population
order by 'DeathRate%' desc;

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 'DeathRate%' from [dbo].[CovidDeaths csv] where location = 'Guyana';

select location, max (total_deaths) HighestDeathCount from [dbo].[CovidDeaths csv]
where continent is not null
group by location
order by HighestDeathCount desc;

-- The Continents with the Highest Death Count per Population.

select continent, max (total_deaths) HighestDeathCount from [dbo].[CovidDeaths csv]
where continent is not null
group by continent
order by HighestDeathCount desc;

select location, max (total_deaths) HighestDeathCount from [dbo].[CovidDeaths csv]
where continent is null
group by location
order by HighestDeathCount desc;

-- Global Numbers

alter table [dbo].[CovidDeaths csv]
alter column new_cases float;

alter table [dbo].[CovidDeaths csv]
alter column new_deaths float;

select date, sum (new_cases) TotalNewCases, sum (new_deaths) TotalNewDeaths, ((sum (new_deaths))/(sum (new_cases)))*100 'DeathPercentagee%'
from [dbo].[CovidDeaths csv]
where continent is not null
group by date
order by 1,2;

select sum (new_cases) TotalNewCases, sum (new_deaths) TotalNewDeaths, ((sum (new_deaths))/(sum (new_cases)))*100 'DeathPercentagee%'
from [dbo].[CovidDeaths csv]
where continent is not null
order by 1,2;

select population from [dbo].[CovidDeaths csv]
where location = 'World';

-- Covid Vaccinations Table

select * from [dbo].[CovidVaccinations csv];

-- Joining both tables (CovidDeaths + CovidVaccinations)

select * from [dbo].[CovidDeaths csv] Deaths join [dbo].[CovidVaccinations csv] Vax on
Deaths.location = Vax.location
and Deaths.date = Vax.date
where Deaths.continent is not null;

-- Total Population vs Total Vaccinations

alter table [dbo].[CovidVaccinations csv]
alter column new_vaccinations float;

select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
sum (new_vaccinations) over (partition by Deaths.location order by Deaths.location, Deaths.date) CumulativeDailyNewVax
from [dbo].[CovidDeaths csv] Deaths join [dbo].[CovidVaccinations csv] Vax on
Deaths.location = Vax.location
and Deaths.date = Vax.date
where Deaths.continent is not null
order by 2,3;

-- Using CTE for CumulativeDailyNewVax operations

with PopVsVax (Continent, Location, Date, Population, new_vaccinations, CumulativeDailyNewVax)
as
(
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
sum (new_vaccinations) over (partition by Deaths.location order by Deaths.location, Deaths.date) CumulativeDailyNewVax
from [dbo].[CovidDeaths csv] Deaths join [dbo].[CovidVaccinations csv] Vax on
Deaths.location = Vax.location
and Deaths.date = Vax.date
where Deaths.continent is not null
--order by 2,3
)
select *, (CumulativeDailyNewVax/Population)*100 'CumulativeDailyNewVaxPerPopulationRate%' from PopVsVax;

-- Using Temp Table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent varchar (50),
Location varchar (50),
Date date,
Population float,
New_Vaccinations float,
CumulativeDailyNewVax float
)
insert into #PercentPopulationVaccinated
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
sum (new_vaccinations) over (partition by Deaths.location order by Deaths.location, Deaths.date) CumulativeDailyNewVax
from [dbo].[CovidDeaths csv] Deaths join [dbo].[CovidVaccinations csv] Vax on
Deaths.location = Vax.location
and Deaths.date = Vax.date
where Deaths.continent is not null
--order by 2,3

select *, (CumulativeDailyNewVax/Population)*100 'CumulativeDailyNewVaxPerPopulationRate%' from #PercentPopulationVaccinated;

-- To create a view to store data for later visualisations

create view PercentPopulationVaccinated as
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
sum (new_vaccinations) over (partition by Deaths.location order by Deaths.location, Deaths.date) CumulativeDailyNewVax
from [dbo].[CovidDeaths csv] Deaths join [dbo].[CovidVaccinations csv] Vax on
Deaths.location = Vax.location
and Deaths.date = Vax.date
where Deaths.continent is not null

select * from [dbo].[PercentPopulationVaccinated];



