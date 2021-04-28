/* get_bib_konvolut.sql: ermittelnung Bib-Nummer zur Massenkorrektur fuer Konvolute in  der Speicherbibliothek Bueron */
/* 21.10.2016, Basil Marti */

-- ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;
SET HEADING OFF;
SET PAUSE OFF;
SET NEWPAGE 0;
SET SPACE 1;
SET LINESIZE 5000;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET TRIMSPOOL ON;
SET VERIFY OFF;
SET TERMOUT OFF;
SET ECHO OFF;

SPOOL $alephe_scratch/bibkey_reind_konvolut.sys APPEND
-- SPOOL $alephe_scratch/bibkey_reind2_konvolut.sys
-- SPOOL bib_adm_key_konvolut

select distinct lpad(z103_lkr_doc_number,9,'0')||'DSV01' from z103, z30
  where z103_lkr_library='DSV01'
  and Z103_LKR_TYPE = 'ADM'
  and z103_rec_key_1 = 'DSV51'||substr(z30_rec_key,1,9)
  and z30_barcode = '&1'
order by lpad(z103_lkr_doc_number,9,'0')||'DSV01';

SPOOL OFF;
EXIT;



