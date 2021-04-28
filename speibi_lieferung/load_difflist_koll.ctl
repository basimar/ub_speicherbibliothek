LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_koll'
BADFILE '$data_scratch/difflist_koll.bad'
APPEND
INTO TABLE spei_difflist 
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
