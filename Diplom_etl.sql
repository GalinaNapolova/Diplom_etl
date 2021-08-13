create schema diplom_etl

CREATE TABLE dim_calendar
AS
WITH dates AS (
    SELECT dd::timestamp AS dt
    FROM generate_series
            ('2013-01-01'::timestamp
            , '2025-01-01'::timestamp
            , '1 minute'::interval) dd
)
SELECT
    to_char(dt, 'YYYYMMDDHH24MISS')::bigint AS id,
    dt AS date,
    to_char(dt, 'YYYY-MM-DD') AS ansi_date,
    date_part('isodow', dt)::int AS day,
    date_part('week', dt)::int AS week_number,
    date_part('month', dt)::int AS month,
    date_part('isoyear', dt)::int AS year,
    (date_part('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
    (to_char(dt, 'YYYYMMDD')::int IN (
        20130101,
        20130102,
        20130103,
        20130104,
        20130105,
        20130106,
        20130107,
        20130108,
        20130223,
        20130308,
        20130310,
        20130501,
        20130502,
        20130503,
        20130509,
        20130510,
        20130612,
        20131104,
        20140101,
        20140102,
        20140103,
        20140104,
        20140105,
        20140106,
        20140107,
        20140108,
        20140223,
        20140308,
        20140310,
        20140501,
        20140502,
        20140509,
        20140612,
        20140613,
        20141103,
        20141104,
        20150101,
        20150102,
        20150103,
        20150104,
        20150105,
        20150106,
        20150107,
        20150108,
        20150109,
        20150223,
        20150308,
        20150309,
        20150501,
        20150504,
        20150509,
        20150511,
        20150612,
        20151104,
        20160101,
        20160102,
        20160103,
        20160104,
        20160105,
        20160106,
        20160107,
        20160108,
        20160222,
        20160223,
        20160307,
        20160308,
        20160501,
        20160502,
        20160503,
        20160509,
        20160612,
        20160613,
        20161104,
        20170101,
        20170102,
        20170103,
        20170104,
        20170105,
        20170106,
        20170107,
        20170108,
        20170223,
        20170224,
        20170308,
        20170501,
        20170508,
        20170509,
        20170612,
        20171104,
        20171106,
        20180101,
        20180102,
        20180103,
        20180104,
        20180105,
        20180106,
        20180107,
        20180108,
        20180223,
        20180308,
        20180309,
        20180430,
        20180501,
        20180502,
        20180509,
        20180611,
        20180612,
        20181104,
        20181105,
        20181231,
        20190101,
        20190102,
        20190103,
        20190104,
        20190105,
        20190106,
        20190107,
        20190108,
        20190223,
        20190308,
        20190501,
        20190502,
        20190503,
        20190509,
        20190510,
        20190612,
        20191104,
        20200101, 20200102, 20200103, 20200106, 20200107, 20200108,
       20200224, 20200309, 20200501, 20200504, 20200505, 20200511,
       20200612, 20201104))::int AS holiday
FROM dates
ORDER BY dt

ALTER TABLE dim_calendar ADD PRIMARY KEY (id);

ALTER TABLE dim_calendar add unique(date)


CREATE TABLE dim_passengers (
    id SERIAL PRIMARY KEY,
    passenger_id bigint not null,
    passenger_name varchar(200) not null,
    contacts jsonb,
unique (passenger_id)
)


CREATE TABLE dim_aircrafts (
    id SERIAL PRIMARY KEY,
    aircraft_code char(3) not null,
    modal varchar(100) not null,
    range int not null,
CHECK (range > 0),
unique (aircraft_code),
unique (modal)
)

CREATE TABLE rej_dim_aircrafts (
    aircraft_code char(3),
    modal varchar(100),
    range int
)


CREATE TABLE dim_airports (
    id SERIAL PRIMARY KEY,
    airport_code char(3) not null,
    airport_name varchar(100) not null,
    city varchar(100) not null,
    longitude float8 not null,
    latitude float8 not null,
    timezone varchar(200) not null,
CHECK (longitude > 0),
CHECK (latitude > 0),
unique (airport_code),
unique (airport_name)
)

CREATE TABLE rej_dim_airports (
    airport_code char(3),
    airport_name varchar(100),
    city varchar(100),
    longitude float8,
    latitude float8,
    timezone varchar(200)
)

CREATE TABLE dim_aiports (
    id SERIAL PRIMARY KEY,
    aiport_code char(3) not null,
    airport_name varchar(100) not null,
    city varchar(100) not null,
    longitude float8 not null,
    latitude float8 not null,
    timezone varchar(200) not null,
CHECK (longitude > 0),
CHECK (latitude > 0),
unique (aiport_code),
unique (airport_name)
)

CREATE TABLE dim_tariff (
    id SERIAL PRIMARY KEY,
    fare_conditions char(100) not null,
CHECK (
    fare_conditions IN ('Economy', 'Comfort', 'Business') 
    ),
unique (fare_conditions)
)

CREATE TABLE fact_flights (
    passenger_id int not null references dim_passengers(id),
    actual_departure timestamptz not null references dim_calendar (date),
    actual_arrival timestamptz not null references dim_calendar (date),
    delayed_departure timestamptz,
    delayed_arrival timestamptz,
    aircraft_code int not null references dim_aircrafts(id),
    departure_airport int references dim_airports(id),
    arrival_airport int references dim_airports(id),
    fare_conditions int not null references dim_tariff(id),
    amount float8,
CHECK (
    actual_arrival IS NULL OR
	(actual_departure IS NOT NULL AND
	actual_arrival IS NOT NULL AND
	actual_arrival > actual_departure)
	),
CHECK (
	actual_arrival IS NULL OR
	(actual_arrival <= current_date)
	), 
CHECK (
	actual_departure IS NULL OR
	(actual_departure <= current_date)
	),	
CHECK (amount > 0)
)

CREATE TABLE rej_fact_flights (
    passenger_id int,
    actual_departure timestamptz,
    actual_arrival timestamptz,
    delayed_departure timestamptz,
    delayed_arrival timestamptz,
    aircraft_code int,
    departure_airport int,
    arrival_airport int,
    fare_conditions int,
    amount float8
)

