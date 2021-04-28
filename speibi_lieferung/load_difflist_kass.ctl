LOAD DATA
INFILE '$data_root/scripts/speibi_lieferung/barcodes_kass'
BADFILE '$data_scratch/difflist_kass.bad'
APPEND
INTO TABLE spei_difflist 
(
barcode                   POSITION(1:30)      CHAR,
verschickt                                    DATE)
