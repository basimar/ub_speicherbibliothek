LOAD DATA
INFILE '$data_root/scripts/speibi_konvolut/barcodes_konvolut.dat'
BADFILE '$data_scratch/barcodes_konvolut.bad'
REPLACE
INTO TABLE barcodes_konvolut 
fields terminated by ';' optionally enclosed by '"'
(
barcode,
barcode_alt               
)
