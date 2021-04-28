/* speibi_stamm_update.sql: Ausgabe s√mtlicher Stammdaten fuer LVS der Speicherbibliothek Bueron */
/* 07.02.2019, Basil Marti */

set linesize 900;
set pagesize 0;
set heading off;
set pause off;
set echo off;
set feedback off;
set termout off;

spool output/stammdaten_update.csv
select /*+ ordered */ rtrim(z30_barcode)||CHR(9)||
z30_sub_library||CHR(9)||
substr(z30_call_no,1,40)||CHR(9)||
rtrim(z30_material)||CHR(9)||
substr(z13_author,1,40)||CHR(9)||
substr(z13_title,1,80)||CHR(9)||
substr(z30_description,1,40)||CHR(9)||
rtrim(z13_imprint)
from z30 inner join z13 on substr(z30_rec_key,1,9) = z13_rec_key
where z30_sub_library in ('BSSBK','BSSBI','SOSBK','SOSBI');

spool off
exit;

