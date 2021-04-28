/******************************************************************************/
/* Script zum Veraendern von z30-Saetzen mit cursor ueber die temp. Tabelle   */
/* barcodes_kass                                                              */
/******************************************************************************/

update dsv51.z30
set z30_upd_time_stamp = '&1',
    z30_item_process_status = 'NV',
    z30_sub_library= 'BSSBI',
    z30_collection = 'MAG',
    z30_item_status = '20',
    z30_item_statistic = 'Kass.Ex.' 
where exists (select barcode from barcodes_kass where barcode = z30_barcode);

/* hier noch ein diff der Mutationen zu eingabe.dat machen und loggen */
/* oder aus log: logical record count 3, aber weiter unten: 2 rows updated */
set heading off;
set pause off;
set echo off;
set feedback off;
set termout off;
spool lesefehler_kass.txt
select barcode from barcodes_kass minus (select z30_barcode from z30 where z30_barcode in (select barcode from barcodes_kass));
spool off

EXIT;
