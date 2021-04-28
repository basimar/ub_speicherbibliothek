
#! bin/sed -f

sed -e 's/245   L $$a/TITEL: /g' speibi_koll_holdings_$datum > tempkoll1
sed -e 's/999   L $$a/DUMMY-TITEL: /g' tempkoll1 > tempkoll2
sed -e 's/.*$$h/            Signatur: /g' tempkoll2 > tempkoll3
sed -e 's/$$5/\n            Standort: /g' tempkoll3 > tempkoll4
sed -e 's/.*8524  L.*//g' tempkoll4 > tempkoll5
sed -e 's/$$a/\n            Holding: /g' tempkoll5 > tempkoll6
sed -e 's/$$.*//g' tempkoll6 > tempkoll7
sed '/^$/d' tempkoll7 > tempkoll8
sed '/^00.*/{x;p;x;}' tempkoll8 > speibi_koll_holdings_lesbarer
# keine date-variable hier mehr, sondern im shell

rm tempkoll*

# exit fuer taksmanager entfernt


