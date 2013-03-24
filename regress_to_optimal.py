import sys

infile = open("../submissions/target_20130322.csv")
of = open("../submissions/target_20130323_0322regressedwithoptimized.csv","w")

of.write(infile.next())

cnt = 0
while infile:
    aline = infile.next()
    parts = aline.split(",")
    val = (float(parts[2])+0.209179) / 2
    cnt += 1
    of.write("{},{},{}\n".format(parts[0], parts[1], val))
    #if cnt > 10: sys.exit()

