
#! bin/sed -f

sed -e 's/245   L $$a/TITEL: /g' speibi_indi_holdings_$datum > tempindi1
sed -e 's/999   L $$a/DUMMY-TITEL: /g' tempindi1 > tempindi2
sed -e 's/.*$$j/            Signatur: /g' tempindi2 > tempindi3
sed -e 's/$$5/\n            Standort: /g' tempindi3 > tempindi4
sed -e 's/.*8524  L.*//g' tempindi4 > tempindi5
sed -e 's/$$a/\n            Holding: /g' tempindi5 > tempindi6
sed -e 's/$$.*//g' tempindi6 > tempindi7
sed '/^$/d' tempindi7 > tempindi8
sed '/^00.*/{x;p;x;}' tempindi8 > speibi_indi_holdings_lesbarer
# keine date-variable hier mehr, sondern im shell

rm tempindi*

# exit fuer taksmanager entfernt

