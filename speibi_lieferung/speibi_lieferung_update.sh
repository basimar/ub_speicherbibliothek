#!/bin/csh -f

# JOB-DAEMON-INIT 
source $aleph_proc/def_local_env
start_p0000 dsv51

# Script zum Import von SpeiBi-Mutationsdaten und Lieferung an LVS
# Dateien werden per Taskmanager-Upload auf dsv51/scratch hochgeladen
# Basiert auf vonroll_import.sh; Anpassungen ZB: Daniel Schmied;
# History: Anpassungen ZB Stand: 19.11.2015; Anpassungen IBB Stand: 22.06.2018/blu

# Variablen:
# ------------------------
# set datum = '20161115'
set datum = `date +%Y%m%d`
set datum_timestamp = `date +"%Y%m%d%H%M000"`
set start_time = `date +%T`
set line = '----------------------------------------------------------------------------'

# Definition der Varianten: Kollektiv-, Kassations-, Individualbestand:
set listtype=(koll kass indi)
set workdir = "$alephe_dev/dsv51/scripts/speibi_lieferung"
set logdir = "$alephe_dev/dsv51/scripts/speibi_lieferung/log"
set inputdir = "$alephe_dev/dsv51/scratch"
set log = $logdir/speibi_lieferung_$datum.log

# Definition Mail-Empfaenger (global fuer jeden Versand im Script):
set MAILEMPF=""

cd $workdir

cd output
# lokale ftp-Check-Datei entfernen. Wird danach frisch geholt:
rm ftp_connect_ok
  # FTP-Transfer (siehe auch README):
  set ftplogin = $workdir/ftp.dat
  set ftpuser = `cat $ftplogin`
  ftp -n ftp.speicherbibliothek.ch <<END_FTP
  user $ftpuser
  get ftp_connect_ok
  put id000305.csv
  put id000306.csv
  quit
END_FTP
 endif
  


 cd $workdir
 rm output/stammdaten*.csv
 # Fehlermeldung ausgeben, falls FTP-Server nicht erreichbar war. Dann fehlt die Pruefdatei lokal:
 if ( -e output/ftp_connect_ok ) then
  echo "     Stammdatentransfer erfolgt (sofern vorhanden, vgl. oben)" >> $log
  echo $line >> $log
  echo $line >> $log
  echo $line >> $log
 else
  echo "KEINE FTP-VERBINDUNG ZUM LVS MOEGLICH! Stammdaten nicht lieferbar." >> $log
  echo $line >> $log
  echo $line >> $log
  echo $line >> $log
 endif
 # und mail an mich:
 if ( ! -e output/ftp_connect_ok ) then
  mailx -r @unibas.ch -s "KEINE FTP-VERBINDUNG ZUM LVS MOEGLICH um $datum_timestamp" $MAILEMPF
 endif

# SCHRITT 5: Abschluss
# --------------------

# Log-Datei nach jedem Lauf verschicken:
cat $log | mailx -r @unibas.ch -s "SpeiBi-Logfile Einlagerung von $datum_timestamp" $MAILEMPF

exit


