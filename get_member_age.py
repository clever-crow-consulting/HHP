import csv
import numpy

AGE2AGE = { '': None,
            '80+':85.,
            numpy.nan: None,
            '50-59': (59.-50)/2+52,
            '20-29': (29.-20)/2+20,
            '60-69': (69-60.)/2+60,
            '10-19': (19-10.)/2+10,
            '0-9': 4.5,
            '30-39': (39-30.)/2+30,
            '40-49': (49-40.)/2+40,
            '70-79': (79-70.)/2+70
            }

members = csv.reader(open("../provided_data/Members.csv"))
of = open("../data/Members_wInt.csv","w")
writer = csv.writer(of, lineterminator='\n')

for aline in members:
    
    try:
        aline.append(AGE2AGE[aline[1]])
    except:
        print aline[1]
    
    writer.writerow(aline)
of.close()
    
