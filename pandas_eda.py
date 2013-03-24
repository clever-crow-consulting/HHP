# EDA
import sys
import pandas
import numpy

df = pandas.read_csv("../data/y1_Claims_clean")
dih = pandas.read_csv("../data/DaysInHospital_Y2.csv")
target = pandas.read_csv("../data/Target.csv")

# Header for output
of = open("../data/y1_member_claim_count.csv","w")
cols = ["member_id",
        "days_in_hospital",
        "n_claims",
        "sum_pay_delay"]
of.write(",".join(cols)+"\n")

# rows of output
for i in range(len(target)):
    member_id = target["MemberID"][i]
    days_in_hospital = dih[dih["MemberID"] == member_id]["DaysInHospital"]
    n_claims = len(df[ df["MemberID"] == member_id])
    sum_pay_delay = sum(list(df[df["MemberID"] == member_id]["PayDelay"]))
    
    # write row
    of.write("{},{},{},{}\n".format(
        member_id,
        days_in_hospital,
        n_claims,
        sum_pay_delay
        ))
    if i!=0 and i % 1000 == 0: 
        of.close()
        sys.exit()
#print len(sdf - sdih)