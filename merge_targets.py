import sys
import numpy
import pdb


data_path = "C:/Users/DanDye/Google Drive/Projects/HeritageHealthPrize/submissions/"

targets = [
    "target_20130401_y1.csv",
    "target_20130401_y2.csv"
    ]
of = open(data_path+"target_20130401.csv","w")
of.write("MemberID,SupLOS,DIH\n")
    
lines0 = open(data_path+targets[0]).readlines()
lines1 = open(data_path+targets[1]).readlines()

for i in range(1,len(lines0)):
    #print i
    if i % 1000 == 0: print i,
    member_id = lines0[i].split(",")[0]
    navg = numpy.mean([float(lines0[i].split(",")[-1].strip()),
                       float(lines1[i].split(",")[-1].strip())])
    if navg > 0.209179: 
        navg = numpy.mean([navg,navg,0.209179]) 
    of.write("{},0,{}\n".format(
                        member_id,
                        navg
                        )
            )
of.close()
print "Done!"
