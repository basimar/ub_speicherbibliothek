/******************************************************************************/
/* Script zum Veraendern von z30-Saetzen mit cursor ueber die temp. Tabelle   */
/* barcodes_indi                                                              */
/******************************************************************************/

update dsv51.z30
set z30_upd_time_stamp = '&1',
    z30_item_process_status = 'NV',
    z30_sub_library= 'SOSBI',
    z30_item_status= '32',
    z30_collection = 'MAG',
    z30_item_statistic = NULL
where z30_item_status = '01' and exists (select barcode from barcodes_ind where barcode = z30_barcode);

/* hier noch ein diff der mutatinen zu eingabe.dat machen und loggen */
/* oder aus log: logical record count 3, aber weiter unten: 2 rows updated */
set heading off;
set pause off;
set echo off;
set feedback off;
set termout off;
spool lesefehler_indi.txt
select barcode from barcodes_ind minus (select z30_barcode from z30 where z30_barcode in (select barcode from barcodes_ind));
spool off

EXIT;
