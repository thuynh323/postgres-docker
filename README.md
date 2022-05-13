


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
 3. Open Docker Desktop.
 4. In your terminal, start Postgres in Detached mode. Docker compose will create two containers with two databases: production and analytics.
```bash
$ docker-compose up -d
Creating network "myproject_default" with the default driver
Creating prod-container ... done
Creating test-container ... done
```
5. Connect to analytics database.
```bash
$ docker exec -it test-container psql dbuser -d test-db
psql (14.2 (Debian 14.2-1.pgdg110+1))
Type "help" for help.

test-db=# 
```
6. Replicate tables from production database.
```bash
test-db=# CREATE SUBSCRIPTION tsub CONNECTION 'host=prod-container dbname=prod-db user=replicator password=123456' PUBLICATION ppub;
NOTICE:  created replication slot "tsub" on publisher
CREATE SUBSCRIPTION
test-db=# 
```
7.
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
8.
```
test-db=# CREATE SCHEMA myschema;
CREATE SCHEMA
test-db=# ALTER TABLE clicks SET SCHEMA myschema; ALTER TABLE leads SET SCHEMA myschema; ALTER TABLE rate_tables SET SCHEMA myschema;
ALTER TABLE
ALTER TABLE
ALTER TABLE
test-db=#
```
9.
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
10.
```
test-db=# ALTER TABLE clicks ADD CONSTRAINT clicks_fk FOREIGN KEY (rate_table_offer_id) REFERENCES rate_tables (rate_table_offer_id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE
test-db=# ALTER TABLE rate_tables ADD CONSTRAINT rate_tables_fk FOREIGN KEY (lead_uuid) REFERENCES leads (lead_uuid);
ALTER TABLE
test-db=#
```
11.
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
12.
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
13.
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
