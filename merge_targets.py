import sys
import numpy



data_path = "C:/Users/DanDye/Google Drive/Projects/HeritageHealthPrize/submissions/"

targets = [
    "target_20130330_y1.csv",
    "target_20130330_y2.csv"
    ]
of = open(data_path+"target_20130330.csv","w")
of.write("MemberID,SupLOS,DIH\n")
    
lines0 = open(data_path+targets[0]).readlines()
lines1 = open(data_path+targets[1]).readlines()

for i in range(1,len(lines0)):
    member_id = lines0[i].split(",")[0]
    
    avg = numpy.mean(
            float(lines0[i].split(",")[-1].strip()), 
            float(lines1[i].split(",")[-1].strip())
            )
    of.write("{},0,{}\n".format(
                        member_id,
                        avg
                        )
            )
of.close()
print "Done!"
