/* speibi_stamm.sql: Ausgabe Stammdaten fuer LVS der Speicherbibliothek Bueron */
/* 25.11.2014, Bernd Luchner */

set linesize 900;
set pagesize 0;
set heading off;
set pause off;
set echo off;
set feedback off;
set termout off;

spool output/stammdaten_indi.csv

select /*+ ordered */ rtrim(z30_barcode)||CHR(9)||
z30_sub_library||CHR(9)||
substr(z30_call_no,1,40)||CHR(9)||
rtrim(z30_material)||CHR(9)||
substr(z13_author,1,40)||CHR(9)||
substr(z13_title,1,80)||CHR(9)||
substr(z30_description,1,40)||CHR(9)||
rtrim(z13_imprint)
from z30 inner join z13 on substr(z30_rec_key,1,9) = z13_rec_key
where exists (select barcode from barcodes_ind where barcode = z30_barcode);

spool off
exit;

