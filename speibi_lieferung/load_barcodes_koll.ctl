LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_koll'
BADFILE '$data_scratch/barcodes_koll.bad'
REPLACE
INTO TABLE barcodes_koll 
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
