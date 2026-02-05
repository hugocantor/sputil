-- ====================================================================
-- Script: create_control_tables.sql
-- Purpose: Create control tables to replace hardcoded customer/node values
-- Author: Bob
-- Date: 2026-01-29
-- ====================================================================

-- ====================================================================
-- Table 1: POESLCUST - PWH Customer/Salesperson Control
-- Purpose: Replace hardcoded customer/salesperson relationships in poe0035.sqlrpgle
-- ====================================================================

CREATE TABLE POESLCUST (
    SOURCE_CUST DECIMAL(7, 0) NOT NULL,
    SOURCE_DIV  DECIMAL(1, 0) NOT NULL,
    SOURCE_COMP DECIMAL(1, 0) NOT NULL,
    SOURCE_SLM  DECIMAL(2, 0) NOT NULL,
    TARGET_DIV  DECIMAL(1, 0) NOT NULL,
    TARGET_COMP DECIMAL(2, 0) NOT NULL,
    TARGET_SLM  DECIMAL(2, 0) NOT NULL,
    ACTIVE_FLAG CHAR(1) NOT NULL DEFAULT 'Y',
    CREATE_DATE DATE NOT NULL,
    CREATE_USER CHAR(10) NOT NULL,
    NOTES       CHAR(50) NOT NULL DEFAULT '',
    
    CONSTRAINT POESLCUST_PK PRIMARY KEY (
        SOURCE_CUST, SOURCE_DIV, SOURCE_COMP, SOURCE_SLM, TARGET_SLM
    ),
    
    CONSTRAINT POESLCUST_CK1 CHECK (ACTIVE_FLAG IN ('Y', 'N'))
);

LABEL ON TABLE POESLCUST IS 'PWH Customer/Salesperson Control';
LABEL ON COLUMN POESLCUST.SOURCE_CUST IS 'Source Customer Number';
LABEL ON COLUMN POESLCUST.SOURCE_DIV IS 'Source Division';
LABEL ON COLUMN POESLCUST.SOURCE_COMP IS 'Source Company';
LABEL ON COLUMN POESLCUST.SOURCE_SLM IS 'Source Salesperson';
LABEL ON COLUMN POESLCUST.TARGET_DIV IS 'Target Division';
LABEL ON COLUMN POESLCUST.TARGET_COMP IS 'Target Company';
LABEL ON COLUMN POESLCUST.TARGET_SLM IS 'Target Salesperson';
LABEL ON COLUMN POESLCUST.ACTIVE_FLAG IS 'Active Flag (Y/N)';
LABEL ON COLUMN POESLCUST.CREATE_DATE IS 'Create Date (YYYYMMDD)';
LABEL ON COLUMN POESLCUST.CREATE_USER IS 'Create User';
LABEL ON COLUMN POESLCUST.NOTES IS 'Description/Notes';

CREATE INDEX POESLCUST_IX1 ON POESLCUST (SOURCE_CUST, ACTIVE_FLAG);

-- ====================================================================
-- Table 2: NODCUSTXRF - Node/Customer Cross Reference Control
-- Purpose: Replace hardcoded node/customer relationships in acs0098.rpgle
-- ====================================================================

CREATE TABLE NODCUSTXRF (
    CUSTOMER    DECIMAL(7, 0) NOT NULL,
    NODE        DECIMAL(5, 0) NOT NULL,
    COMP_ARRAY  CHAR(18) NOT NULL DEFAULT '000000000000000000',
    ACTIVE_FLAG CHAR(1) NOT NULL DEFAULT 'Y',
    CREATE_DATE DECIMAL(8, 0) NOT NULL,
    CREATE_USER CHAR(10) NOT NULL,
    NOTES       CHAR(50) NOT NULL DEFAULT '',
    
    CONSTRAINT NODCUSTXRF_PK PRIMARY KEY (CUSTOMER, NODE),
    
    CONSTRAINT NODCUSTXRF_CK1 CHECK (ACTIVE_FLAG IN ('Y', 'N'))
);

LABEL ON TABLE NODCUSTXRF IS 'Node/Customer Cross Reference Control';
LABEL ON COLUMN NODCUSTXRF.CUSTOMER IS 'Customer Number';
LABEL ON COLUMN NODCUSTXRF.NODE IS 'Node/Salesperson Number';
LABEL ON COLUMN NODCUSTXRF.COMP_ARRAY IS '18-Char Company Flag Array';
LABEL ON COLUMN NODCUSTXRF.ACTIVE_FLAG IS 'Active Flag (Y/N)';
LABEL ON COLUMN NODCUSTXRF.CREATE_DATE IS 'Create Date (YYYYMMDD)';
LABEL ON COLUMN NODCUSTXRF.CREATE_USER IS 'Create User';
LABEL ON COLUMN NODCUSTXRF.NOTES IS 'Description/Notes';

CREATE INDEX NODCUSTXRF_IX1 ON NODCUSTXRF (CUSTOMER, ACTIVE_FLAG);
CREATE INDEX NODCUSTXRF_IX2 ON NODCUSTXRF (NODE, ACTIVE_FLAG);

GRANT ALL ON POESLCUST TO PUBLIC;
GRANT ALL ON NODCUSTXRF TO PUBLIC;