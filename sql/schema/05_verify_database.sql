-- ============================================
-- FILE: 05_verify_database.sql
-- PURPOSE: Verify Database Tables and Relationships
-- ============================================


-- --------------------------------------------
-- QUERY 01: List All Tables
-- PURPOSE: Display Tables in staging and analytics Schemas
-- --------------------------------------------

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema IN ('staging', 'analytics')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;


-- --------------------------------------------
-- QUERY 02: Check Source Documents
-- PURPOSE: Display Source Document Records
-- --------------------------------------------

SELECT *
FROM analytics.source_documents;


-- --------------------------------------------
-- QUERY 03: Check Foreign Keys
-- PURPOSE: Display Foreign Key Relationships
-- --------------------------------------------

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc

JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema

JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.constraint_schema = tc.constraint_schema

WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.constraint_schema = 'analytics';