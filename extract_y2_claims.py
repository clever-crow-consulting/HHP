#!/usr/local/bin/python
import os,sys
import csv
import re
import pandas

INFILENAME = "../data/Claims.csv"
#OUTFILENAME = "../data/y1_Claims_clean.csv"
#OUTFILENAME = "../data/y2_Claims_clean.csv"
OUTFILENAME = "../data/y3_Claims_clean.csv"

los2dih = { "": 0., 
            "1 day":1., 
            "2- 4 weeks":21., 
            "2 days":2., 
            "3 days":3., 
            "4 days":4., 
            "1- 2 weeks":11.,
            "4- 8 weeks":42., 
            "6 days":6., 
            "5 days":5.,
            "26+ weeks":182.
            }
            

def clean_line(line):
    #if line["Year"] != "Y1": 
    #if line["Year"] != "Y2": 
    if line["Year"] != "Y3": 
        return None
    if line["MemberID"] == "\r": 
        return None
    #if line["LengthOfStay"] == "" : return None
    line["LengthOfStay"] = los2dih[line["LengthOfStay"]]
    #if line["SupLOS"] == : return None
    line["PayDelay"] = line["PayDelay"].replace("+","").strip()
    line["MemberID"] = int(line["MemberID"])
    return line
            
def main(infilename=INFILENAME, outfilename=OUTFILENAME):
    infile = open(infilename)
    outfile = open(outfilename, "w")
    
    reader = csv.DictReader(infile)
    writer = csv.DictWriter(outfile, reader.fieldnames, lineterminator='\n')
    writer.writeheader()
    
    i = 0
    for aline in reader:
        if i % 100000 == 0: 
            print i
        aline = clean_line(aline)
        if aline: writer.writerow(aline)
        i += 1
        #if i > 200: sys.exit()

if __name__ == "__main__":
    main()