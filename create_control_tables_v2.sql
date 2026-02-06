-- ====================================================================
-- Script: create_control_tables_v2.sql
-- Purpose: Create control tables to replace hardcoded customer/node values
--          Version 2: Refactored NODCUSTXRF with parent-child design
-- Author: Bob
-- Date: 2026-02-05
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
-- Table 2: NODCUSTXRF - Node/Customer Cross Reference Control (Parent)
-- Purpose: Replace hardcoded node/customer relationships in acs0098.rpgle
-- ====================================================================

CREATE TABLE NODCUSTXRF (
    CUSTOMER    DECIMAL(7, 0) NOT NULL,
    NODE        DECIMAL(5, 0) NOT NULL,
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
LABEL ON COLUMN NODCUSTXRF.ACTIVE_FLAG IS 'Active Flag (Y/N)';
LABEL ON COLUMN NODCUSTXRF.CREATE_DATE IS 'Create Date (YYYYMMDD)';
LABEL ON COLUMN NODCUSTXRF.CREATE_USER IS 'Create User';
LABEL ON COLUMN NODCUSTXRF.NOTES IS 'Description/Notes';

CREATE INDEX NODCUSTXRF_IX1 ON NODCUSTXRF (CUSTOMER, ACTIVE_FLAG);
CREATE INDEX NODCUSTXRF_IX2 ON NODCUSTXRF (NODE, ACTIVE_FLAG);

-- ====================================================================
-- Table 3: NODCUSTCMP - Node/Customer Company Assignment (Child)
-- Purpose: Store individual company assignments for each node/customer pair
-- ====================================================================

CREATE TABLE NODCUSTCMP (
    CUSTOMER    DECIMAL(7, 0) NOT NULL,
    NODE        DECIMAL(5, 0) NOT NULL,
    COMPANY     DECIMAL(2, 0) NOT NULL,
    ACTIVE_FLAG CHAR(1) NOT NULL DEFAULT 'Y',
    CREATE_DATE DECIMAL(8, 0) NOT NULL,
    CREATE_USER CHAR(10) NOT NULL,
    
    CONSTRAINT NODCUSTCMP_PK PRIMARY KEY (CUSTOMER, NODE, COMPANY),
    
    CONSTRAINT NODCUSTCMP_FK1 FOREIGN KEY (CUSTOMER, NODE) 
        REFERENCES NODCUSTXRF (CUSTOMER, NODE)
        ON DELETE CASCADE,
    
    CONSTRAINT NODCUSTCMP_CK1 CHECK (ACTIVE_FLAG IN ('Y', 'N')),
    CONSTRAINT NODCUSTCMP_CK2 CHECK (COMPANY BETWEEN 1 AND 18)
);

LABEL ON TABLE NODCUSTCMP IS 'Node/Customer Company Assignments';
LABEL ON COLUMN NODCUSTCMP.CUSTOMER IS 'Customer Number';
LABEL ON COLUMN NODCUSTCMP.NODE IS 'Node/Salesperson Number';
LABEL ON COLUMN NODCUSTCMP.COMPANY IS 'Company Number (1-18)';
LABEL ON COLUMN NODCUSTCMP.ACTIVE_FLAG IS 'Active Flag (Y/N)';
LABEL ON COLUMN NODCUSTCMP.CREATE_DATE IS 'Create Date (YYYYMMDD)';
LABEL ON COLUMN NODCUSTCMP.CREATE_USER IS 'Create User';

CREATE INDEX NODCUSTCMP_IX1 ON NODCUSTCMP (CUSTOMER, NODE, ACTIVE_FLAG);
CREATE INDEX NODCUSTCMP_IX2 ON NODCUSTCMP (NODE, COMPANY, ACTIVE_FLAG);

-- ====================================================================
-- Grants
-- ====================================================================

GRANT ALL ON POESLCUST TO PUBLIC;
GRANT ALL ON NODCUSTXRF TO PUBLIC;
GRANT ALL ON NODCUSTCMP TO PUBLIC;

-- ====================================================================
-- Comments and Usage Notes
-- ====================================================================

COMMENT ON TABLE NODCUSTXRF IS 
'Parent table for node/customer cross-reference. Each record represents a special 
business rule exception where a customer should be assigned to a specific node 
(salesperson). The actual company assignments are stored in the child table NODCUSTCMP.';

COMMENT ON TABLE NODCUSTCMP IS 
'Child table storing individual company assignments for each node/customer pair. 
Replaces the 18-character COMP_ARRAY with normalized records. Each record indicates 
that a specific company (1-18) should be flagged for the parent node/customer combination.';

-- ====================================================================
-- Example Usage:
-- ====================================================================
-- To assign customer 250720 to node 10119 with companies 1 and 18:
--
-- INSERT INTO NODCUSTXRF VALUES (250720, 10119, 'Y', 20260205, 'SYSTEM', 'Total Wine & More');
-- INSERT INTO NODCUSTCMP VALUES (250720, 10119, 1, 'Y', 20260205, 'SYSTEM');
-- INSERT INTO NODCUSTCMP VALUES (250720, 10119, 18, 'Y', 20260205, 'SYSTEM');
--
-- To query all companies for a customer/node pair:
--
-- SELECT c.COMPANY 
-- FROM NODCUSTXRF x
-- JOIN NODCUSTCMP c ON c.CUSTOMER = x.CUSTOMER AND c.NODE = x.NODE
-- WHERE x.CUSTOMER = 250720 
--   AND x.NODE = 10119
--   AND x.ACTIVE_FLAG = 'Y'
--   AND c.ACTIVE_FLAG = 'Y'
-- ORDER BY c.COMPANY;
-- ====================================================================