#!/usr/local/bin/python
# ToDo:
# Set NA with pandas.read_csv
#na_values : list-like or dict, default None
#Additional strings to recognize as NA/NaN. If dict passed, specific per-column NA values


import os,sys
import csv
import re
import pandas
import numpy

INFILENAME = "../data/Claims.csv"

DSFS2DSFS = {
             '' : None,
             numpy.nan: None,
             '8- 9 months' : 5.5*30.,
             '6- 7 months' : 6.5*30,
             '3- 4 months' : 3.5*30,
             '1- 2 months' : 1.5*30,
             '11-12 months' : 11.5*30,
             '5- 6 months' : 5.5*30,
             '10-11 months' : 1.5*30,
             '9-10 months' : 9.5*30,
             '0- 1 month' : .5*30,
             '7- 8 months' : 7.5*30,
             '4- 5 months' : 4.5*30,
             '2- 3 months' : 2.5*30
             }

LOS2DIH = { "": 0.,
            "1 day":1.,
            "2- 4 weeks":2.*7.,
            "2 days":2.,
            "3 days":3.,
            "4 days":4.,
            "1- 2 weeks":7.,
            "4- 8 weeks":4.*7.,
            "6 days":6.,
            "5 days":5.,
            "26+ weeks":26.*7.
            }

SEX2SEX = {'M':'M',
           'F':'F',
           numpy.nan:None
           }

AGE2AGE = {'80+':85.,
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

class switch(object):
    def __init__(self, value):
        self.value = value
        self.fall = False

    def __iter__(self):
        """Return the match method once, then stop"""
        yield self.match
        raise StopIteration
    
    def match(self, *args):
        """Indicate whether or not to enter a case suite"""
        if self.fall or not args:
            return True
        elif self.value in args: # changed for v1.5, see below
            self.fall = True
            return True
        else:
            return False
            
def clean_charlson(instr):
    if instr == "0": return 0
    parts = instr.split("-")
    if len(parts) > 1:
        return int(parts[1])-int(parts[0]) / 2.

def clean_line(line, members):
    #if line["Year"] != year:
    #    return None
    if line["MemberID"] == "\r":
        return None
    #if line["LengthOfStay"] == "" : return None
    line["LengthOfStay"] = LOS2DIH[line["LengthOfStay"]]
    #if line["SupLOS"] == : return None
    line["PayDelay"] = line["PayDelay"].replace("+","").strip()
    line["MemberID"] = int(line["MemberID"])
    line["Sex"] = SEX2SEX[members.ix[members.MemberID == line["MemberID"],2].values[0]]
    #try:
    line["AgeAtFirstClaim"] = AGE2AGE[members.ix[members.MemberID == line["MemberID"],1].values[0]]
    line["CharlsonIndex"] = clean_charlson(line["CharlsonIndex"])
    line["DSFS"] = DSFS2DSFS[line["DSFS"]]
    #except:#
    #    line["AgeAtFirstClaim"] = None
    #    print members.ix[members.MemberID == line["MemberID"],1].values[0]
    return line

def main(infilename=INFILENAME):

    members = pandas.read_csv("../data/Members.csv")
    cl = clean_line # defining in fx speeds things up
    #for year in ["Y1","Y2","Y3"]:

    infile = open(INFILENAME)
    y1outfile = open("../data/Y1_Claims_clean2.csv","w")
    y2outfile = open("../data/Y2_Claims_clean2.csv","w")
    y3outfile = open("../data/Y3_Claims_clean2.csv","w")
    reader = csv.DictReader(infile)
    outfields = reader.fieldnames
    outfields.extend(("Sex","AgeAtFirstClaim"))
    y1writer = csv.DictWriter(y1outfile, outfields, lineterminator='\n')
    y2writer = csv.DictWriter(y2outfile, outfields, lineterminator='\n')
    y3writer = csv.DictWriter(y3outfile, outfields, lineterminator='\n')
    y1writer.writeheader()
    y2writer.writeheader()
    y3writer.writeheader()

    lines = list(reader) # Gotcha: Memory hog
    for i,aline in enumerate(lines):
        if i % 100000 == 0:
            print i
        aline = cl(aline, members)
        for case in switch(aline["Year"]):
            if case("Y1"):
                y1writer.writerow(aline)
                break
            elif case("Y2"):
                y2writer.writerow(aline)
                break
            elif case("Y3"):
                y3writer.writerow(aline)
                break
            else:
                print "Unkown year detected"
                sys.exit()

        #if i > 100:  # debugging
            #outfile.close()            
            #sys.exit()
    y1outfile.close()
    y2outfile.close()
    y3outfile.close()

if __name__ == "__main__":
    main()