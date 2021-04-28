LOAD DATA
INFILE 'alle_barcodes.csv'
BADFILE 'load_barcodes_into_table.bad'
REPLACE
INTO TABLE barcode_speibi_ssch
fields terminated by ';' optionally enclosed by '"'
(
BARCODE 
)
