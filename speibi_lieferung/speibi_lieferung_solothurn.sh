#!/bin/csh -f

# JOB-DAEMON-INIT 
source $aleph_proc/def_local_env
start_p0000 dsv51

# Script zum Import von SpeiBi-Mutationsdaten und Lieferung an LVS
# Dateien werden per Taskmanager-Upload auf dsv51/scratch hochgeladen
# Basiert auf vonroll_import.sh; Anpassungen ZB: Daniel Schmied;
# History: Anpassungen ZB Stand: 19.11.2015; Anpassungen IBB Stand: 22.06.2018/blu
# Variante zur manuellen Lieferung von Daten der ZB Solothurn: 28.02.2019/bmt

# Variablen:
# ------------------------
# set datum = '20161115'
set datum = `date +%Y%m%d`
set datum_timestamp = `date +"%Y%m%d%H%M000"`
set start_time = `date +%T`
set line = '----------------------------------------------------------------------------'

# Definition der Varianten: Kollektiv-, Kassations-, Individualbestand:
set listtype=(zbso)
set workdir = "$alephe_dev/dsv51/scripts/speibi_lieferung"
set logdir = "$alephe_dev/dsv51/scripts/speibi_lieferung/log"
set inputdir = "$alephe_dev/dsv51/scratch"
set log = $logdir/speibi_lieferung_$datum.log

# Definition Mail-Empfaenger (global fuer jeden Versand im Script):
set MAILEMPF=""

# SCHRITT 1: Schleife fuer Exemplarmutationen und formale Checks pro listtype:
# ----------------------------------------------------------------------------

echo "Verarbeitung SpeiBi-Mutationen vom $datum um $start_time gestartet:"
while ($#listtype)
    echo $line
    echo "While... speibi_$listtype[1]_$datum.csv"
       # Als Dateiname wird z.B. speibi_koll_20150310.csv oder speibi_indi_20151028.csv erwartet.
       # Das Datum muss dem Tagesdatum entsprechen, an dem das Script laeuft, sonst wird abgebrochen.
    set success = 'Erfolg'
    cd $inputdir
    # Pruefen, ob Dateien vorhanden sind:
    if ( -e speibi_$listtype[1]_$datum.1.csv ) then
       # Gibt es mehrere Uploads pro Tag, sind sie durch laufende Nummern nach dem Datum gekennzeichnet. Diese zunaechst zusammenkopieren:
       echo $line
       echo "Mehrere Uploaddateien fuer $listtype[1] fuer $datum gefunden, diese werden zusammenkopiert." >> $log
       cat speibi_$listtype[1]_$datum.?.csv | sort -u > speibi_$listtype[1]_$datum.csv
    endif
    if (! -e speibi_$listtype[1]_$datum.csv) then
       echo "     Keine Datei speibi_$listtype[1]_$datum.csv in diesem Lauf ..."
       set filehandle = "Kein Input Typ $listtype[1]"
       echo $line >> $log
       echo "     Keine Datei vom Lauf am $datum um $start_time vom Typ speibi_$listtype[1] gefunden" >> $log
       set success = 'Abbruch'
    else
       echo $line
       echo "Verarbeitung speibi_$listtype[1]_$datum.csv"
       set runtype = $listtype[1]
       set filehandle = `ls -1 speibi_$listtype[1]_$datum.csv`
       echo $line >> $log
       echo $line >> $log
       echo "SpeiBi Import Mutationsdaten fuer $filehandle gestartet: $start_time" >> $log
       echo $line >> $log
       chmod -x $filehandle
       set filecheck = `file $filehandle | awk '{print $2$3}'`
       set check_key_error = `grep -c 'E+' $filehandle`
       if ( $check_key_error > 0 || $filecheck != 'ASCIItext' ) then
       # Syntax oben kann pro Verbund abweichen: In Basel ging frueher: 'asciitext', in der ZB und Basel muss es aktuell gross geschrieben sein.)
       # Stoppt das Script, wenn Datei formal falsch. Auch wenn z.B. ein Umlaut in drin ist:
          set success = 'Abbruch'
          echo "ABBRUCH: $filehandle enthaelt Formeln statt Barcodes oder ist keine ASCII-Datei" >> $log
       # In diesem Fall gleich auch ein Mailversand ans Magazin.
       # Beachten: Keine umlaute in abbruchmeldung.txt. Via Taskmanager gibt es sonst ein bin-Attachment statt Text: 
          cat $log | mailx -r @unibas.ch -s "SpeiBi: Achtung Script-Abbruch fuer Datei $filehandle um $start_time" $MAILEMPF
          mv $filehandle $filehandle.error
          set filehandle = "Fehler in Input Typ $listtype[1]"
       else
          cp $filehandle $workdir/speibi_$listtype[1].dat
          echo "1.: $filehandle importieren" >> $log
          echo $line >> $log
          cd $workdir
          switch ($runtype)
            # Case-Reihenfolge: koll zuletzt, damit bei doppelten Barcodes zur Sicherheit auf Kollektiv mutiert wird:
            case zbso:
              mv speibi_$listtype[1].dat barcodes_indi.dat
              # Lade Barcodes in Temp-Table barcodes_indi|koll|kass mit REPLACE
              sqlldr dsv51/dsv51 control=load_barcodes_indi
              # Lade Barcodes auch in Temp-Table spei_difflist mit APPEND
              sqlldr dsv51/dsv51 control=load_difflist_indi
              set indi_import = `grep 'data errors' load_barcodes_indi.log | awk '{print $1}'`
              if ( $indi_import == '0' ) then
                 echo "2.: Mutationen $filehandle ausfuehren" >> $log
                 sqlplus dsv51/dsv51 @korr-item_indi_zbso.sql $datum_timestamp
                 mv $inputdir/$filehandle $inputdir/$filehandle.done
              else
                 echo "Import von $filehandle gescheitert, Fehlerliste:" >> $log
                 cat load_barcodes_indi.bad >> $log
                 mv $inputdir/$filehandle $inputdir/$filehandle.error
                 set filehandle = "Fehler in Input Typ $listtype[1]"
                 set success = 'Abbruch'
              endif
              breaksw
            default:
              echo "Error with Runtype: $runtype, Filehandle: $filehandle, Log: $log"
              set success = 'Fehler'
              breaksw
          endsw
       endif
    endif

    echo $line
    echo " "
    echo $line >> $log
    set end_time = `date +%T`
    if ( $success == 'Erfolg' ) then
       echo "3.: Mutationen SpeiBi fuer $filehandle um $end_time mit $success beendet." >> $log
    else
       echo "     Keine Mutationen Speibi fuer speibi_$listtype[1] am $datum um $start_time" >> $log
    endif
    shift listtype
end

cd $workdir

# SCHRITT 2: Lesefehler ausgeben und per Mail verschicken:
# --------------------------------------------------------

  # Die Mutationsscripts korr-item_indi|kass|koll.sql pruefen auch, ob die Barcodes im Aleph existieren. 
  # Falls nicht, werden diese in Textdateien lesefehler_indi|kass|koll.txt geschrieben und hier per Mail verschickt:
  if ( -e lesefehler_koll.txt ) then
     cat lesefehler_koll.txt > lesefehler_all.txt
     rm lesefehler_koll.txt
  endif
  if ( -e lesefehler_kass.txt ) then
     cat lesefehler_kass.txt >> lesefehler_all.txt
     rm lesefehler_kass.txt
  endif
  if ( -e lesefehler_indi.txt ) then
     cat lesefehler_indi.txt >> lesefehler_all.txt
     rm lesefehler_indi.txt 
  endif
  # nur ausgeben, wenn Dateien nicht leer sind:
  if ( -e lesefehler_all.txt ) then
    if ( ! -z lesefehler_all.txt ) then
       cat lesefehler_all.txt | mailx -r @unibas.ch -s "SpeiBi: Achtung: nicht existierende Barcodes um $datum_timestamp eingelesen. Bitte sofort bearbeiten." $MAILEMPF
       mv lesefehler_all.txt lesefehler_$datum_timestamp.txt
    endif
  endif

cd $workdir

# SCHRITT 3: Stammdaten erzeugen und liefern
# ------------------------------------------

  echo $line >> $log
 # nur erzeugen, wenn Dateien existieren:
 if ( -e $inputdir/speibi_zbso_$datum.csv.done ) then
  sqlplus dsv51/dsv51 @speibi_stamm_indi.sql
  echo $line >> $log
  echo "Stammdaten Individualbestand um $end_time erzeugt." >> $log
 else
  echo $line >> $log
  echo "     Keine Stammdaten Individualbestand um $end_time" >> $log
 endif
  echo $line >> $log

 cd output
 if ( -e stammdaten_indi.csv ) then
    cat stammdaten_indi.csv > stammdaten_all.csv
 endif
 if ( -e stammdaten_kass.csv ) then
    cat stammdaten_kass.csv >> stammdaten_all.csv
 endif
 if ( -e stammdaten_koll.csv ) then
    cat stammdaten_koll.csv >> stammdaten_all.csv
 endif
 # Counter nur erhoehen, wenn Dateien nicht leer sind:
 if ( ! -z stammdaten_all.csv ) then
  sort -u stammdaten_all.csv > stammdaten_all.csv.srt
  mv stammdaten_all.csv.srt stammdaten_all.csv
  set stammcounter = `cat ./stamm_counter.dat`
  expr $stammcounter + 1 > ./stamm_counter.dat
  set stammcounter = `cat ./stamm_counter.dat`
  set fullcounter = `printf "%06d" $stammcounter`
  mv stammdaten_all.csv id$fullcounter.csv
  # lokale ftp-Check-Datei entfernen. Wird danach frisch geholt:
  rm ftp_connect_ok
  # FTP-Transfer (siehe auch README):
  set ftplogin = $workdir/ftp.dat
  set ftpuser = `cat $ftplogin`
  ftp -n ftp.speicherbibliothek.ch <<END_FTP
  user $ftpuser
  put id$fullcounter.csv
  get ftp_connect_ok
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

# SCHRITT 4: Holdings ermitteln
# -----------------------------

echo "Holdings ermitteln fuer $inputdir/speibi_koll_$datum.csv.done" >> $log
 # nur tun, wenn Exemplare vorhanden sind:
 if ( -e $inputdir/speibi_koll_$datum.csv.done ) then
  cp $inputdir/speibi_koll_$datum.csv.done $data_scratch/speikoll4hol_$datum
  # Bib-Sysno aus Barcodes ermitteln. PS: Kein Ampersand hinten anfuegen, dann wartet das Script jeweils, bis die einzelnen Schritte fertig sind:
  csh -f $aleph_proc/p_manage_70 DSV51,speikoll4hol_$datum,spei-hol-koll_$datum,DSV01,15, > $alephe_scratch/dsv51_p_manage_70_koll_$datum.log
  # Ausgabe von Titel und 852 mit Spezial-Expand SPEI-HOL (852##,b,Z01,BARCODE=N), vgl tab_expand. Achtung: Indikatoren hier im Script quoten:
  csh -f $aleph_proc/p_print_03 DSV01,spei-hol-koll_$datum,245\#\#,999\#\#,852\#\#,,,,,,speibi_koll_holdings_$datum,A,,SPEI-HOL,,N, > $alephe_scratch/dsv01_p_print_03_koll_$datum.log
echo "Holdings ermittelt fuer $inputdir/speibi_koll_$datum.csv.done" >> $log
 endif
 if ( -e $inputdir/speibi_kass_$datum.csv.done ) then
  cp $inputdir/speibi_kass_$datum.csv.done $data_scratch/speikass4hol_$datum
  csh -f $aleph_proc/p_manage_70 DSV51,speikass4hol_$datum,spei-hol-kass_$datum,DSV01,15, > $alephe_scratch/dsv51_p_manage_70_kass_$datum.log
  csh -f $aleph_proc/p_print_03 DSV01,spei-hol-kass_$datum,245\#\#,999\#\#,852\#\#,,,,,,speibi_kass_holdings_$datum,A,,SPEI-HOL,,N, > $alephe_scratch/dsv01_p_print_03_kass_$datum.log
 endif
 if ( -e $inputdir/speibi_indi_$datum.csv.done ) then
  cp $inputdir/speibi_indi_$datum.csv.done $data_scratch/speiindi4hol_$datum
  csh -f $aleph_proc/p_manage_70 DSV51,speiindi4hol_$datum,spei-hol-indi_$datum,DSV01,15, > $alephe_scratch/dsv51_p_manage_70_indi_$datum.log
  csh -f $aleph_proc/p_print_03 DSV01,spei-hol-indi_$datum,245\#\#,999\#\#,852\#\#,,,,,,speibi_indi_holdings_$datum,A,,SPEI-HOL,,N, > $alephe_scratch/dsv01_p_print_03_indi_$datum.log
 endif

# Den Output mit sed-Scripts lesbarer machen:

cd /exlibris/aleph/u22_1/dsv01/scratch

# nur tun, wenn Holdings vorhanden sind:
if ( -e speibi_koll_holdings_$datum ) then
echo "Holdings aufbereiten fuer speibi_koll_holdings_$datum" >> $log
 source $workdir/sed_koll.sed
 mv speibi_koll_holdings_$datum $workdir/speibi_koll_holdings_$datum_timestamp
 mv speibi_koll_holdings_lesbarer $workdir/holdings/speibi_koll_holdings_$datum_timestamp
echo "Holdings aufbereitet fuer speibi_koll_holdings_$datum_timestamp" >> $log
endif

if ( -e speibi_indi_holdings_$datum ) then
echo "Holdings aufbereiten fuer speibi_indi_holdings_$datum" >> $log
 source $workdir/sed_indi.sed
 mv speibi_indi_holdings_$datum $workdir/speibi_indi_holdings_$datum_timestamp
 mv speibi_koll_holdings_lesbarer $workdir/holdings/speibi_indi_holdings_$datum_timestamp
echo "Holdings aufbereitet fuer speibi_indi_holdings_$datum_timestamp" >> $log
endif

if ( -e speibi_kass_holdings_$datum ) then
echo "Holdings aufbereiten fuer speibi_kass_holdings_$datum" >> $log
 source $workdir/sed_kass.sed
 mv speibi_kass_holdings_$datum $workdir/speibi_kass_holdings_$datum_timestamp
 mv speibi_koll_holdings_lesbarer $workdir/holdings/speibi_kass_holdings_$datum_timestamp
echo "Holdings aufbereitet fuer speibi_kass_holdings_$datum_timestamp" >> $log
endif

cd $inputdir

# SCHRITT 5: Abschluss
# --------------------

# Verschieben der Barcode-Dateien und mit $datum_timestamp versehen.
# Zweck: So laufen die Schritte Stammdaten und Holdings nicht mit alten Barcode-Dateien, wenn das Script mehrfach taeglich laeuft.
mv speibi_kass_$datum.csv.done speibi_kass_$datum_timestamp.csv.done
mv speibi_koll_$datum.csv.done speibi_koll_$datum_timestamp.csv.done
mv speibi_indi_$datum.csv.done speibi_indi_$datum_timestamp.csv.done

# Log-Datei nach jedem Lauf verschicken:
cat $log | mailx -r @unibas.ch -s "SpeiBi-Logfile Einlagerung von $datum_timestamp" $MAILEMPF

exit


