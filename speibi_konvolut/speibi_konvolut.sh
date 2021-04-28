#!/usr/bin/csh -f

# JOB-DAEMON-INIT 
source $aleph_proc/def_local_env
start_p0000 dsv51

# Script zum Import von SpeiBi-Mutationsdaten und Lieferung an LVS
# Dateien werden per Taskmanager-Upload auf dsv51/scratch hochgeladen
# Basiert auf vonroll_import.sh; Anpassungen ZB: Daniel Schmied 
# History: Anpassungen ZB Stand: 19.11.2015; Anpassungen IBB Stand: 30.06.2016/blu

# Variablen:
# ------------------------
set datum = `date +%Y%m%d`
set datum_timestamp = `date +"%Y%m%d%H%M000"`
set start_time = `date +%T`
set line = '----------------------------------------------------------------------------'
set workdir = "$alephe_dev/dsv51/scripts/speibi_konvolut"
set inputdir = "$alephe_dev/dsv51/scratch"
set log = $inputdir/speibi_konvolut$datum.log
# Definition Mail-Empfaenger (global fuer jeden Versand im Script):
set MAILEMPF=""

# SCHRITT 1: Schleife fuer Exemplarmutationen und formale Checks pro listtype:
# ----------------------------------------------------------------------------

echo "Verarbeitung SpeiBi-Konvolute vom $datum um $start_time gestartet:"
echo $line
echo "While... speibi_konvolut_$datum.csv"
       # Als Dateiname wird z.B. speibi_koll_20150310.csv oder speibi_indi_20151028.csv erwartet.
       # Das Datum muss dem Tagesdatum entsprechen, an dem das Script laeuft, sonst wird abgebrochen.
set success = 'Erfolg'
cd $inputdir
if (! -e speibi_konvolut_$datum.csv) then
    echo "     Keine Datei speibi_konvolut_$datum.csv in diesem Lauf ..."
    set filehandle = "Kein Input Typ Konvolut"
    echo $line >> $log
    echo "     Keine Datei vom Lauf am $datum um $start_time vom Typ speibi_konvolut gefunden" >> $log
    set success = 'Abbruch'
else
    echo $line
    echo "Verarbeitung speibi_konvolut_$datum.csv"
    set filehandle = `ls -1 speibi_konvolut_$datum.csv`
    echo $line >> $log
    echo $line >> $log
    echo "SpeiBi Verarbeitung Konvolute gestartet: $start_time" >> $log
    echo $line >> $log
    chmod -x $filehandle
    set filecheck = `file $filehandle | awk '{print $2$3}'`
    set check_key_error = `grep -c 'E+' $filehandle`
    if ( $check_key_error > 0 || $filecheck != 'ASCIItext' ) then
    # Syntax oben kann pro Verbund abweichen: In Basel geht: 'asciitext', in der ZB muss es gross geschrieben sein.)
    # Stoppt das Script, wenn Datei formal falsch. Auch wenn z.B. ein Umlaut in drin ist:
        set success = 'Abbruch'
        echo "ABBRUCH: $filehandle enthaelt Formeln statt Barcodes oder ist keine ASCII-Datei" >> $log
        # In diesem Fall gleich auch ein Mailversand ans Magazin.
        # Beachten: Keine umlaute in abbruchmeldung.txt. Via Taskmanager gibt es sonst ein bin-Attachment statt Text: 
        cat $log | mailx -r  -s "SpeiBi: Achtung Script-Abbruch fuer Datei Konvolut um $start_time" $MAILEMPF
        mv $filehandle $filehandle.error
        set filehandle = "Fehler in Input Typ Konvolut"
    else
        cp $filehandle $workdir/speibi_konvolut.dat
        echo "1.: $filehandle importieren" >> $log
        echo $line >> $log
        cd $workdir
        # Loeschen der Systemnummerdatei zum Neuindexieren und Publizieren 
        rm $alephe_scratch/bibkey_reind_konvolut.sys
        mv speibi_konvolut.dat barcodes_konvolut.dat
        sqlplus dsv51/dsv51 @create_barcodes_konvolut.sql
        sqlldr dsv51/dsv51 control=load_barcodes_konvolut
        set konvolut_import = `grep 'data errors' load_barcodes_konvolut.log | awk '{print $1}'`
        if ( $konvolut_import == '0' ) then
            echo "2.: Mutationen $filehandle ausfuehren" >> $log
            # sql zu erstellen fuer konvolut
            foreach barcode ( "`cat barcodes_konvolut.dat`" )
                set input_barcode = `echo $barcode | awk -F";" '{print $1}'`
                echo "Bearbeite $input_barcode" >> $log 
                echo "Bearbeite $input_barcode" 
                sqlplus dsv51/dsv51 @get_data_konvolut.sql $input_barcode
                sqlplus dsv51/dsv51 @edit_data_konvolut.sql $datum_timestamp $input_barcode
                sqlplus dsv51/dsv51 @get_bib_konvolut.sql $input_barcode
            end
            mv $inputdir/$filehandle ../scratch/$filehandle.done
         else
            echo "Import von Konvolut gescheitert, Fehlerliste:" >> $log
            cat load_barcodes_konvolut.bad >> $log
            # entsteht aus Hilfsfile oben
            mv $inputdir/$filehandle ../scratch/$filehandle.error
            set filehandle = "Fehler in Input Typ Konvolut"
            set success = 'Abbruch'
         endif
    endif
endif
echo $line
echo " "
echo $line >> $log
set end_time = `date +%T`
if ( $success == 'Erfolg' ) then
    echo "3.: Verarbeitung Konvolute SpeiBi um $end_time mit $success beendet." >> $log
else
    echo "     Keine Mutationen Speibi fuer speibi_konvolut am $datum um $start_time" >> $log
endif

cd $workdir

# SCHRITT 2: Publizieren
# --------------------
csh -f $aleph_proc/p_manage_40 DSV01,bibkey_reind_konvolut.sys,,,00000000, > $alephe_scratch/dsv01_p_manage_40_konvolut$datum.log &




# SCHRITT 3: Abschluss
# --------------------

# Verschieben der Barcode-Dateien und mit $datum_timestamp versehen.
# Zweck: So laufen die Schritte Stammdaten und Holdings nicht mit alten Barcode-Dateien, wenn das Script mehrfach taeglich laeuft.
#mv speibi_konvolut_$datum.csv.done speibi_konvolut$datum_timestamp.csv.done

cp $alephe_scratch/bibkey_reind_konvolut.sys $workdir/bibkey_reind_konvolut_$datum_timestamp.sys

# Log-Datei nach jedem Lauf verschicken:
cat $log | mailx -r  -s "SpeiBi-Logfile Einlagerung von $datum_timestamp" $MAILEMPF

exit


