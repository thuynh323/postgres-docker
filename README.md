# Setup Instructions
1. Install Docker Desktop and Docker Compose. More instruction [here](https://docs.docker.com/compose/install/).</br>
2. Create project structure as follows:
```
myproject
 ┣ conf_file
 ┃ ┗ pg_hba.conf
 ┣ data
 ┃ ┣ clicks.csv
 ┃ ┣ leads.csv
 ┃ ┗ rate_tables.csv
 ┣ docker-compose.yml
 ┣ prod-init.sql
 ┗ test-init.sql
 ```
 Use pandas.read_parquet to read parquet files, then convert these files to csv.
 ```python
 # Install pyparrow if you don't have it (pip install pyparrow)

import pandas as pd
clicks = pd.read_parquet('clicks.parquet.gzip')
leads = pd.read_parquet('leads.parquet.gzip')
rate_tables = pd.read_parquet('rate_tables.parquet.gzip')

clicks.to_csv('clicks.csv')
leads.to_csv('clicks.csv')
rate_tables.to_csv('clicks.csv')
```
 3. Open Docker Desktop.
 4. In your terminal, start Postgres in Detached mode. Docker compose will create two containers (prod- and test-). You can also uncomment the third service setup in docker-compose.yml to create a Jupyter Notebook that can be linked to the databases. Please note it might take some time to set up.
```bash
$ docker-compose up -d
Creating network "myproject_default" with the default driver
Creating prod-container ... done
Creating test-container ... done
```
5. prod-container includes prod-db which is the "live production transaction database"; test-container include test-db (analytics database) with empty tables that can be used to replicate data from prod-db. Now connect to test-db.
```bash
$ docker exec -it test-container psql dbuser -d test-db
psql (14.2 (Debian 14.2-1.pgdg110+1))
Type "help" for help.

test-db=# 
```
6. Replicate tables from prod-db.
```bash
test-db=# CREATE SUBSCRIPTION tsub CONNECTION 'host=prod-container dbname=prod-db user=replicator password=123456' PUBLICATION ppub;
NOTICE:  created replication slot "tsub" on publisher
CREATE SUBSCRIPTION
test-db=# 
```
7. Check if tables are filled.
```
test-db=# \d+
                                     List of relations
 Schema |    Name     | Type  | Owner  | Persistence | Access method |  Size  | Description
--------+-------------+-------+--------+-------------+---------------+--------+-------------
 public | clicks      | table | dbuser | permanent   | heap          | 592 kB |
 public | leads       | table | dbuser | permanent   | heap          | 12 MB  |
 public | rate_tables | table | dbuser | permanent   | heap          | 55 MB  |
(3 rows)

test-db=#
```
8. Create a new schema.
```
test-db=# CREATE SCHEMA myschema;
CREATE SCHEMA
test-db=# ALTER TABLE clicks SET SCHEMA myschema; ALTER TABLE leads SET SCHEMA myschema; ALTER TABLE rate_tables SET SCHEMA myschema;
ALTER TABLE
ALTER TABLE
ALTER TABLE
test-db=#
```
9. Change search path to access new schema.
```
test-db=# SET search_path=myschema;
SET
test-db=# \d+
                                      List of relations
  Schema  |    Name     | Type  | Owner  | Persistence | Access method |  Size  | Description
----------+-------------+-------+--------+-------------+---------------+--------+-------------
 myschema | clicks      | table | dbuser | permanent   | heap          | 592 kB |
 myschema | leads       | table | dbuser | permanent   | heap          | 12 MB  |
 myschema | rate_tables | table | dbuser | permanent   | heap          | 55 MB  |
(3 rows)

test-db=#
```
10. Create foreign keys to link data tables.
```
test-db=# ALTER TABLE clicks ADD CONSTRAINT clicks_fk FOREIGN KEY (rate_table_offer_id) REFERENCES rate_tables (rate_table_offer_id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE
test-db=# ALTER TABLE rate_tables ADD CONSTRAINT rate_tables_fk FOREIGN KEY (lead_uuid) REFERENCES leads (lead_uuid);
ALTER TABLE
test-db=#
```
11. Check clicks table. This table has rate_table_offer_id as its primary key (PK) and also its foreign key (FK) to link with rate_tables table (one-one relationship).
```
test-db=# \d clicks
                              Table "myschema.clicks"
       Column        |            Type             | Collation | Nullable | Default
---------------------+-----------------------------+-----------+----------+---------
 rate_table_offer_id | character varying           |           | not null |
 num_clicks          | integer                     |           |          |
 last_click          | timestamp without time zone |           |          |
 first_click         | timestamp without time zone |           |          |
Indexes:
    "clicks_pkey" PRIMARY KEY, btree (rate_table_offer_id)
Foreign-key constraints:
    "clicks_fk" FOREIGN KEY (rate_table_offer_id) REFERENCES rate_tables(rate_table_offer_id) DEFERRABLE INITIALLY DEFERRED

test-db=#
```
12. Check leads table. This table has lead_uuid as its primary key (PK) to link with rate_tables table (one-many relationship).
```
test-db=# \d leads
                                Table "myschema.leads"
        Column         |            Type             | Collation | Nullable | Default
-----------------------+-----------------------------+-----------+----------+---------
 lead_uuid             | uuid                        |           | not null |
 requested             | double precision            |           |          |
 state                 | character varying           |           |          |
 loan_purpose          | character varying           |           |          |
 credit                | character varying           |           |          |
 annual_income         | double precision            |           |          |
 is_employed           | character varying           |           |          |
 monthly_net_income    | double precision            |           |          |
 morgate_property_type | character varying           |           |          |
 has_morgate           | character varying           |           |          |
 zipcode               | character varying           |           |          |
 lead_created_at       | timestamp without time zone |           |          |
Indexes:
    "leads_pkey" PRIMARY KEY, btree (lead_uuid)
Referenced by:
    TABLE "rate_tables" CONSTRAINT "rate_tables_fk" FOREIGN KEY (lead_uuid) REFERENCES leads(lead_uuid)

test-db=#
```
13. Check rate_tables. This table has rate_table_offer_id as its primary key (PK) and also its foreign key (FK) to link with clicks table (one-one relationship).
```
test-db=# \d rate_tables
                                Table "myschema.rate_tables"
           Column            |            Type             | Collation | Nullable | Default
-----------------------------+-----------------------------+-----------+----------+---------
 lead_uuid                   | uuid                        |           | not null |
 rate_table_id               | character varying           |           | not null |
 rate_table_offer_id         | character varying           |           | not null |
 rate_table_offer_created_at | timestamp without time zone |           |          |
 offer_apr                   | double precision            |           |          |
 offer_fee_fixed             | double precision            |           |          |
 offer_fee_rate              | double precision            |           |          |
 offer_monthly_payment       | double precision            |           |          |
 offer_rec_score             | double precision            |           |          |
 offer_rank_table            | integer                     |           |          |
 demand_sub_account_id       | character varying           |           | not null |
Indexes:
    "rate_tables_pkey" PRIMARY KEY, btree (rate_table_offer_id)
Foreign-key constraints:
    "rate_tables_fk" FOREIGN KEY (lead_uuid) REFERENCES leads(lead_uuid)
Referenced by:
    TABLE "clicks" CONSTRAINT "clicks_fk" FOREIGN KEY (rate_table_offer_id) REFERENCES rate_tables(rate_table_offer_id) DEFERRABLE INITIALLY DEFERRED

test-db=#
```
14. If you choose to create a Jupyter Notebook, you can find a URL in Docker jupyter-container. Open this URL in your browser to access your notebook.
15. To stop Docker, use docker-compose stop.
