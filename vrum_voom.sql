CREATE SCHEMA IF NOT EXISTS raw_data;

CREATE TABLE IF NOT EXISTS raw_data.sales (
    id SERIAL PRIMARY KEY,
    auto VARCHAR,
    gasoline_consumption NUMERIC(3, 1),
    price NUMERIC(19, 12),
    date DATE,
    person VARCHAR,
    phone VARCHAR,
    discount FLOAT,
    brand_origin VARCHAR
)

CREATE SCHEMA IF NOT EXISTS car_shop;

CREATE TABLE IF NOT EXISTS car_shop.colors (
    id SERIAL PRIMARY KEY,
    color_name VARCHAR(30) UNIQUE NOT NULL -- Chosen, because biggest color length is 30 (via yandex its 'University of Pennsylvania red')
);

CREATE TABLE IF NOT EXISTS car_shop.countries (
    id SERIAL PRIMARY KEY,
    country_name VARCHAR(65) UNIQUE -- Chosen, because biggest country name is 56 symbols (via yandex its 'The United Kingdom of Great Britain and Northern Ireland')
);

CREATE TABLE IF NOT EXISTS car_shop.auto_brands (
    id SERIAL PRIMARY KEY,
    auto_brand VARCHAR(50) UNIQUE NOT NULL, --Chosen, beacuse i can't think of someone typing more than 50 symbols as a brand name
    country_id INTEGER REFERENCES car_shop.countries(id)
);

CREATE TABLE IF NOT EXISTS car_shop.auto_models (
    id SERIAL PRIMARY KEY,
    auto_model VARCHAR(50) NOT NULL, -- Chosen, as auto_brand in car_shop.auto_brands
    auto_brand_id INTEGER NOT NULL REFERENCES car_shop.auto_brands(id) ON DELETE CASCADE,
    gasoline_consumption NUMERIC(3, 1), -- Numeric, from -99.9 to 99.9
    UNIQUE(auto_model, auto_brand_id)
);

CREATE TABLE IF NOT EXISTS car_shop.persons (
    id SERIAL PRIMARY KEY,
    person_name VARCHAR NOT NULL, -- person name can be a lot of characters
    phone VARCHAR(25) NOT NULL, -- phone number is in common 13 characters chose 25 with addinional space for random
    UNIQUE(person_name, phone)
);

CREATE TABLE IF NOT EXISTS car_shop.sales (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL, -- date datatype built-in
    discount NUMERIC(5, 2) NOT NULL CHECK (discount BETWEEN 0 AND 100), -- constraint for numeric type 0.00 - 100.00
    price NUMERIC(11, 4) NOT NULL CHECK (price > 0), -- numeric got 11 characters 4 after dot
    color_id INTEGER NOT NULL REFERENCES car_shop.colors(id), -- FOREIGN key int constraint
    auto_model_id INTEGER NOT NULL REFERENCES car_shop.auto_models(id), -- FOREIGN key int constraint
    person_id INTEGER NOT NULL REFERENCES car_shop.persons(id) -- FOREIGN key int constraint
)

INSERT INTO car_shop.colors (color_name)
SELECT DISTINCT TRIM(SPLIT_PART(auto, ', ', 2)) 
FROM raw_data.sales;

INSERT INTO car_shop.countries (country_name)
SELECT DISTINCT brand_origin 
FROM raw_data.sales;

INSERT INTO car_shop.auto_brands (auto_brand, country_id)
SELECT DISTINCT 
    SPLIT_PART(auto, ' ', 1) as brand,
    c.id
FROM raw_data.sales rs
LEFT JOIN car_shop.countries c ON rs.brand_origin = c.country_name;


INSERT INTO car_shop.auto_models (auto_model, auto_brand_id, gasoline_consumption)
SELECT DISTINCT 
    TRIM(SPLIT_PART(SPLIT_PART(auto, ',', 1), ' ', 2)),
    ab.id,
    rs.gasoline_consumption
FROM raw_data.sales rs
JOIN car_shop.auto_brands ab ON SPLIT_PART(rs.auto, ' ', 1) = ab.auto_brand;


INSERT INTO car_shop.persons (person_name, phone)
SELECT DISTINCT person, phone 
FROM raw_data.sales;


INSERT INTO car_shop.sales (date, discount, price, color_id, auto_model_id, person_id)
SELECT 
    rs.date,
    COALESCE(rs.discount, 0) as discount,
    rs.price,
    c.id as color_id,
    am.id as auto_model_id,
    p.id as person_id
FROM raw_data.sales rs
LEFT JOIN car_shop.colors c ON TRIM(SPLIT_PART(rs.auto, ', ', 2)) = c.color_name
LEFT JOIN car_shop.auto_brands ab ON SPLIT_PART(rs.auto, ' ', 1) = ab.auto_brand
LEFT JOIN car_shop.auto_models am ON am.auto_brand_id = ab.id AND SPLIT_PART(SPLIT_PART(rs.auto, ',', 1), ' ', 2) = am.auto_model
LEFT JOIN car_shop.persons p ON rs.person = p.person_name AND rs.phone = p.phone;

