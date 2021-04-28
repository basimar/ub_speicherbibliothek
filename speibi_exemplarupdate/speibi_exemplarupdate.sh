#!/bin/csh -f

# JOB-DAEMON-INIT 
source $aleph_proc/def_local_env
start_p0000 dsv51

set workdir = "$alephe_dev/dsv51/scripts/speibi_exemplarupdate"
set logdir = $workdir/logs

set ftplogin = $workdir/ftp.dat
set ftpuser = `cat $ftplogin`
set now = `date "+%Y%m%d%H%M%S%N" | cut -c1-15`
set today = `echo $now | cut -c3-8`
set LOG = $logdir/run_$today.log

set mail_receivers = ""

cd $workdir

echo "Hole Barcodes vom FTP-Host" | tee -a $LOG
ftp -in ftp.speicherbibliothek.ch <<EOF
user $ftpuser
mget ee*
mdelete ee*
quit
EOF

if ($status > 0) then
    echo "$now -- FTP-Transaktion war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif

ls ee* >& /dev/null
if ($status > 0) then
    echo "$now -- Keine Dateien heruntergeladen. Breche ab." >>$LOG
    exit(0)
endif  

cat ee* | sort | uniq > $workdir/alle_barcodes.csv
if ($status > 0) then
    echo "$now -- Konkatenierung war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif


echo "Erstelle neue Hilfstabelle" | tee -a $LOG
sqlplus -S dsv51/dsv51 <<EOF 
DROP TABLE barcode_speibi_ssch; 
CREATE TABLE barcode_speibi_ssch 
   (BARCODE CHAR (30)) 
    STORAGE (INITIAL 20M NEXT 5M MAXEXTENTS 200) 
    TABLESPACE ts0; 
EXIT;
EOF
if ($status > 0) then
    echo "$now -- Erstellen der Hilfstabelle war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif


echo "Lade Barcodes in Hilfstabelle" | tee -a $LOG
sqlldr dsv51/dsv51 control=$workdir/load_barcodes_into_table.ctl
if ($status > 0) then
    echo "$now -- Laden der Barcodes in Hilfstabelle war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif


echo "Loesche Wert 'NV' in Feld Z30_ITEM_PROCESS_STATUS der betroffenen Datensaetze" | tee -a $LOG
sqlplus -S dsv51/dsv51 <<EOF
MERGE INTO z30 USING barcode_speibi_ssch ON
(z30_barcode = barcode) WHEN MATCHED THEN UPDATE SET
z30_item_process_status = '',
z30_upd_time_stamp = '$now';

set heading off
set feed off
set pause off
set pagesize 0
set echo off
set trimspool on
set termout off
 
SPOOL edited_rec_keys.sys
 
SELECT trim(z30_rec_key) from z30 where z30_upd_time_stamp = '$now';
 
SPOOL off
EXIT;
EOF
if ($status > 0) then
    echo "$now -- Merging der Barcodes in Tabelle Z30 war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif

echo "`wc -l edited_rec_keys.sys` Datensaetze aktualisiert (Z30_UPD_TIME_STAMP = $now)" | tee -a $LOG

echo "Indexiere..." | tee -a $LOG
/exlibris/aleph/u22_1/dsv51/scripts/reind_bmt.sh $workdir/edited_rec_keys.sys

echo "Raeume auf" | tee -a $LOG
echo $now > $logdir/upd_time_stamp_$today.txt 
mkdir $logdir/barcodes_$today
mv $workdir/ee* $logdir/barcodes_$today
mv $workdir/alle_barcodes.csv $logdir/barcodes_$today/alle_barcodes.csv
mv $workdir/edited_rec_keys.sys $logdir/edited_rec_keys_$today.sys
mv $workdir/load_barcodes_into_table.log $logdir/load_barcodes_$today.log
if ($status > 0) then
    echo "$now -- Aufraeumen war nicht erfolgreich. Fehlercode: $status" >>$LOG
    cat $LOG | mailx -r @unibas.ch -s "SpeiBi: Fehler bei Exemplarupdate um $today" $mail_receivers
    exit($status)
endif
echo "Job beendet" | tee -a $LOG

exit
