-- ============================================
-- FILE: 01_create_schemas.sql
-- PURPOSE: Create PostgreSQL Schemas
-- ============================================

-- Create staging schema for imported source data
CREATE SCHEMA IF NOT EXISTS staging;

-- Create analytics schema for structured analytical tables
CREATE SCHEMA IF NOT EXISTS analytics;