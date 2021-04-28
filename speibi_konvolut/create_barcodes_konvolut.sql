 drop table barcodes_konvolut;
 create table barcodes_konvolut
    (BARCODE CHAR (30),
     BARCODE_ALT CHAR (30),
     REC_KEY CHAR(9), 
     NOTE_OPAC CHAR (200))
    storage (initial 20M next 5M maxextents 200)
     tablespace ts1;
exit;
