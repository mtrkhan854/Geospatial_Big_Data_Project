--------------------------------------------------------********************************************
----- DATA EXPLORATION, FILTERING AND CLEANING ---------********************************************
--------------------------------------------------------********************************************

-----------------------------------
-- FILTERING FOR GIDs: 1, 3, 9, 14:
-----------------------------------

-- cabs table:

create table cabs_gid as
select * from cabs
where (zone_id_pickup = 1 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 3 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 3 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 3 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 9 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 3 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 14 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 3 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14));

-- nymc table: 
create table nymc_gid as
select * from nymc
where gid = 1 OR gid = 3 OR gid = 9 OR gid = 14;

---------------------------
-- checking the GID ranges:
---------------------------

-- cabs_gid table:
select distinct zone_id_pickup, zone_id_dropoff
from  cabs_gid
order by zone_id_pickup, zone_id_dropoff;

-- nymic_gid table:
select distinct gid
from  nymc_gid
order by gid;

-- checking total amount is sum of all other fares or not:
select fare_amount, 
		fare_amount + extra + mta_tax + improvement_surcharge + tip_amount + tolls_amount AS "calculated total",
		total_amount,
		(fare_amount + extra + mta_tax + improvement_surcharge + tip_amount + tolls_amount) - total_amount AS "difference"
from cabs_gid
order by "difference" desc
limit 5;

--checking the number of data-points in cabs and cabs_gid before cleaning:
select count(*) from cabs_gid;
select count(*) from cabs;

-- checking total amount = calculated amount OR not:
select fare_amount, 
		extra,
		mta_tax,
		improvement_surcharge,
		tip_amount,
		tolls_amount,
		fare_amount + extra + mta_tax + improvement_surcharge + tip_amount + tolls_amount AS "calculated total",
		total_amount,
		(fare_amount + extra + mta_tax + improvement_surcharge + tip_amount + tolls_amount) - total_amount AS "difference"
from cabs
order by "difference" asc
limit 10;

--cleaning cabs_gid to produce cabs_gid_cleaned:

create table cabs_gid_cleaned as
select * from cabs_gid
where ((fare_amount + extra + mta_tax + improvement_surcharge + tip_amount + tolls_amount) - total_amount) = 0;

select * from cabs_gid_cleaned
limit 5;

-- the number of records in the cleaned tables -> only 4 regions included (1, 3, 9, 14)
select count(*) from cabs_gid_cleaned;

-- counting any NULL values in the entire cabs_gid_cleaned table:
select count(*) from cabs_gid_cleaned
where pickup_datetime is NULL or
	  dropoff_datetime is NULL or
	  passenger_count is NULL or
	  trip_distance is NULL or
	  pickup_pt is NULL or
	  zone_id_pickup is NULL or
	  dropoff_pt is NULL or
	  zone_id_dropoff is NULL or
	  ratecode_id is NULL or
	  payment_type is NULL or
	  fare_amount is NULL or
	  extra is NULL or
	  mta_tax is NULL or
	  improvement_surcharge is NULL or
	  tip_amount is NULL or
	  tolls_amount is NULL or
	  total_amount is NULL;

-- checking if any of the INT or NUMERIC colmns have any negative values:
select count(*) from cabs_gid_cleaned
where passenger_count < 0 or
	  trip_distance < 0 or
	  zone_id_pickup < 0 or
	  zone_id_dropoff < 0 or
	  ratecode_id < 0 or
	  payment_type < 0 or

-- checking if any of the "COST" colmns have any negative values:
select count(*) from cabs_gid_cleaned
where 
	  fare_amount < 0 or
	  extra < 0 or
	  mta_tax < 0 or
	  improvement_surcharge < 0 or
	  tip_amount < 0 or
	  tolls_amount < 0 or
	  total_amount < 0;

-- fare_amount, extra, mta_tax, improvement_surcharge, tip_amount, tolls_amount, total_amount (ie. any instance where pickup_datetime > dropoff_datetime)

--Checking if there is any discrepancy in pickup_datetime and dropoff_datetime
select * from cabs_gid_cleaned
where EXTRACT(epoch FROM (dropoff_datetime - pickup_datetime)) < 0;

delete from cabs_gid_cleaned
where fare_amount < 0 or
	  extra < 0 or
	  mta_tax < 0 or
	  improvement_surcharge < 0 or
	  tip_amount < 0 or
	  tolls_amount < 0 or
	  total_amount < 0 or
	  EXTRACT(epoch FROM (dropoff_datetime - pickup_datetime)) < 0;

-- FINAL ROW COUNT/SIZE of cabs_gid_cleaned:
select count(*) from cabs_gid_cleaned;


-- counting any NULL values in the entire nymc_gid table:
select count(*) from nymc_gid
where gid is NULL or
	  borocode is NULL or
	  boroname is NULL or
	  municourt is NULL or
	  shape_leng is NULL or
	  shape_area is NULL or
	  geom is NULL; 

--checking for any discrepancy in nymc_gid dataset:
select count(*) from nymc_gid
where gid < 0 or
	  borocode < 0 or
	  shape_leng < 0 or
	  shape_area < 0;

--checking date range for records pertaining to zones I was given (1, 3, 9, 14):
select min(pickup_datetime), max(pickup_datetime) from cabs_gid_cleaned
	  
--------------------------------------------------------********************************************
----- ANALYSIS -----------------------------------------********************************************
--------------------------------------------------------********************************************

-- KPI 1: zone_id_pickup vs Total earning from the zone

select zone_id_pickup, sum(fare_amount) as "Total earnings in Zone"
from cabs_gid_cleaned
--where pickup_datetime >= '2015-10-01 00:00:00' AND  pickup_datetime <  '2015-12-31 23:59:59'
group by zone_id_pickup
order by "Total earnings in Zone" desc;


-- KPI 2: zone_id_pickup and  borocode vs. total passengers

select cabs_gid_cleaned.zone_id_pickup, nymc_gid.borocode, sum(cabs_gid_cleaned.passenger_count) as "Total passenger count per zone/borocode combination"
from cabs_gid_cleaned join nymc_gid
on cabs_gid_cleaned.zone_id_pickup = nymc_gid.gid
group by cabs_gid_cleaned.zone_id_pickup, nymc_gid.borocode
order by "Total passenger count per zone/borocode combination" desc;

--checking the distinct zone_id_pickup, gid and borocode combinations:
select cabs_gid_cleaned.zone_id_pickup, nymc_gid.gid, nymc_gid.borocode
from cabs_gid_cleaned join nymc_gid
on cabs_gid_cleaned.zone_id_pickup = nymc_gid.gid
group by cabs_gid_cleaned.zone_id_pickup, nymc_gid.gid, nymc_gid.borocode

-- all distinct gid and borocode:
select distinct gid from nymc_gid;
select distinct borocode from nymc_gid;

-- KPI 3: Tip amount vs. zone_id_dropoff/borrocde
select cabs_gid_cleaned.zone_id_dropoff, nymc_gid.borocode, sum(cabs_gid_cleaned.tip_amount) as "Total tip per zone/borocode combination"
from cabs_gid_cleaned join nymc_gid
on cabs_gid_cleaned.zone_id_dropoff = nymc_gid.gid
group by cabs_gid_cleaned.zone_id_dropoff, nymc_gid.borocode
order by "Total tip per zone/borocode combination" desc;

---------------------------------------------------------------------------------------------------
-- select pickup_datetime,
-- 	   dropoff_datetime,
-- 	   zone_id_pickup,
-- 	   zone_id_dropoff,
-- 	   --sum(fare_amount),
-- 	   fare_amount,
-- 		ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934) as distance_travelled,
-- 		trip_distance,
-- 		(ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934)) - trip_distance as difference_dist_readings
-- from cabs_gid_cleaned
-- where ((ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934)) - trip_distance) <= 1 
	
-- 	AND ((ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934)) - trip_distance) >= -1
-- order by difference_dist_readings asc
-- limit 10;

-- select * from cabs_gid_cleaned
-- limit 5

-- ---
-- create table cabs_gid_dist_cleaned as
-- select * from cabs_gid_cleaned
-- where ((ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934)) - trip_distance) <= 1 
	
-- 	AND ((ST_Distance (
-- 					pickup_pt, dropoff_pt
-- 	)/(1000 * 1.60934)) - trip_distance) >= -1;
	
-- select count(*) from cabs_gid_dist_cleaned

-- select * from cabs_gid_dist_cleaned
-- limit 5

--
-- select min(trip_distance), max(trip_distance) from cabs_gid_dist_cleaned

-- select * from cabs_gid_dist_cleaned
-- where (trip_distance) in
-- ( select max(trip_distance)
--  from cabs_gid_dist_cleaned)

--drop table cabs_gid_dist_cleaned

---------------------------------------------------------------------------------------------------

-- KPI 4: Most profitable  routes/zones based on total earnings and total number of trips available:

-- Creating a KPI4 table to deal with the issue:
create table KPI4 as
select zone_id_pickup, zone_id_dropoff, sum(fare_amount) as "Total_earnings", 
		sum(trip_distance) as "Total_distance_travelled", 
		count(*) as "total_number_trips_in_route"
from cabs_gid_cleaned
group by zone_id_pickup, zone_id_dropoff
order by "Total_earnings" desc

--drop table kpi4;
--select * from KPI4

-- Adding total_earnings_per_km column to kpi4:
ALTER TABLE KPI4 ADD COLUMN total_earnings_per_km numeric;
UPDATE kpi4 
SET "total_earnings_per_km" = "Total_earnings" / ("Total_distance_travelled" / 1000); 

-- Adding total_earnings_per_trip column to kpi4:
ALTER TABLE KPI4 ADD COLUMN total_earnings_per_trip numeric;
UPDATE kpi4 
SET "total_earnings_per_trip" = ("Total_earnings" / "total_number_trips_in_route"); 

--
select * from kpi4
order by "total_earnings_per_trip" desc; 

-- KPI 5: Most important time to drive based on total number of  trips and total earnings:
select date_part('hour', pickup_datetime) as trip_hour,
		count(*) as total_trips,
		sum (fare_amount) as total_earnings
from cabs_gid_cleaned
where (zone_id_pickup = 1 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 9 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 14 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
group by trip_hour
order by trip_hour;

-- Correlation between total_trips and fare_amount:

--first create a new table with total_trips and total_earnings columns: this could have been done in a simpler way, but I am almost out :/
create table kpi5_corr as
select date_part('hour', pickup_datetime) as "trip_hour",
		count(*) as "total_trips",
		sum (fare_amount) as "total_earnings"
from cabs_gid_cleaned
where (zone_id_pickup = 1 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 9 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
	 OR (zone_id_pickup = 14 AND (zone_id_dropoff = 1 OR zone_id_dropoff = 9 OR zone_id_dropoff = 14))
group by trip_hour
order by trip_hour;

--  apply the corr function:
select corr("total_trips", "total_earnings") 
	as total_trips_N_total_earnings_R
from kpi5_corr;
