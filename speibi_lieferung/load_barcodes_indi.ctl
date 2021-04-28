LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_indi'
BADFILE '$data_scratch/barcodes_indi.bad'
REPLACE
INTO TABLE barcodes_ind
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
