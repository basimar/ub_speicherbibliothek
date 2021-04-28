LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_indi'
BADFILE '$data_scratch/difflist_indi.bad'
APPEND
INTO TABLE spei_difflist 
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
