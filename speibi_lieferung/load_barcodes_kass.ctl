LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_kass'
BADFILE '$data_scratch/barcodes_kass.bad'
REPLACE
INTO TABLE barcodes_kass 
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
