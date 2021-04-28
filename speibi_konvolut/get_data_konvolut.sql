/* get_date_konvolut.sql: Ausgabe Daten zur Massenmkorrektur fuer Konvolute in  der Speicherbibliothek Bueron */
/* 07.10.2016, Basil Marti */

MERGE
INTO barcodes_konvolut
USING z30
ON (
z30_barcode = barcodes_konvolut.barcode_alt 
AND barcodes_konvolut.barcode = '&1'
)
WHEN MATCHED THEN
UPDATE
SET barcodes_konvolut.note_opac = z30_call_no
;
EXIT;


