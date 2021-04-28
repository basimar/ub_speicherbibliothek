/* edit_data_konvolut.sql:  Massenkorrektur fuer Konvolute in  der Speicherbibliothek Bueron */
/* 07.10.2016, Basil Marti */

MERGE 
INTO dsv51.z30 
USING barcodes_konvolut 
ON (
z30_barcode = barcodes_konvolut.barcode and z30_barcode = '&2'
)
WHEN MATCHED THEN
UPDATE
SET z30_upd_time_stamp = '&1',
z30_item_status = '44',
z30_note_opac = SUBSTR('Bestellbar unter Sig.: ' || RTRIM(barcodes_konvolut.note_opac) || ' ' || RTRIM(z30_note_opac),1,200)
;
EXIT;

