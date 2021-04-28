
#! bin/sed -f

sed -e 's/245   L $$a/TITEL: /g' speibi_kass_holdings_$datum > tempkass1
sed -e 's/999   L $$a/DUMMY-TITEL: /g' tempkass1 > tempkass2
sed -e 's/.*$$j/            Signatur: /g' tempkass2 > tempkass3
sed -e 's/$$5/\n            Standort: /g' tempkass3 > tempkass4
sed -e 's/.*8524  L.*//g' tempkass4 > tempkass5
sed -e 's/$$a/\n            Holding: /g' tempkass5 > tempkass6
sed -e 's/$$.*//g' tempkass6 > tempkass7
sed '/^$/d' tempkass7 > tempkass8
sed '/^00.*/{x;p;x;}' tempkass8 > speibi_kass_holdings_lesbarer
# keine date-variable hier mehr, sondern im shell

rm tempkass*

# exit fuer taksmanager entfernt

