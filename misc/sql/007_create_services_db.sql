CREATE DATABASE IF NOT EXISTS "services";

CREATE USER IF NOT EXISTS service WITH PASSWORD '_';

GRANT ALL on DATABASE services to service;