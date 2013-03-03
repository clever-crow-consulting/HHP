#!/usr/local/bin/python
import os,sys
import csv
import re
import pandas

INFILENAME = "../data/Claims.csv"
OUTFILENAME = "../data/Claims_clean.csv"

los2dih = { "":0., 
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
    try:
        line["LengthOfStay"] = los2dih[line["LengthOfStay"]]
    except:
        print line["LengthOfStay"]
        sys.exit()
    return line
            
def main(infilename=INFILENAME, outfilename=OUTFILENAME):
    infile = open(infilename)
    outfile = open(outfilename, "w")
    reader = csv.DictReader(infile)
    writer = csv.DictWriter(outfile, reader.fieldnames)
    
    i = 0
    for aline in reader:
        if i % 100000 == 0: 
            print i
        aline = clean_line(aline)
        writer.writerow(aline)
        i += 1

if __name__ == "__main__":
    main()