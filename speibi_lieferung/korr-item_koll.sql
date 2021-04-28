/******************************************************************************/
/* Script zum Veraendern von z30-Saetzen mit cursor ueber die temp. Tabelle   */
/* barcodes_koll                                                              */
/******************************************************************************/

update dsv51.z30
set z30_upd_time_stamp = '&1',
    z30_item_process_status = 'NV',
    z30_sub_library= 'BSSBK',
    z30_collection = 'MAG',
    z30_item_status = '31',
    z30_item_statistic = NULL 
where exists (select barcode from barcodes_koll where barcode = z30_barcode);
-- where z30_barcode in (select barcode from barcodes_koll);

/* hier noch ein diff der Mutationen zu eingabe.dat machen und loggen */
/* oder aus log: logical record count 3, aber weiter unten: 2 rows updated */
set heading off;
set pause off;
set echo off;
set feedback off;
set termout off;
spool lesefehler_koll.txt
select barcode from barcodes_koll minus (select z30_barcode from z30 where z30_barcode in (select barcode from barcodes_koll));
spool off


EXIT;
