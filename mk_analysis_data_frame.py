# Create analysis data frame
import sys
import pandas
import numpy

def EDA():
    print claims.groupby("PrimaryConditionGroup").count()
    print claims.groupby("ProcedureGroup").count()
    print claims["ProcedureGroup"].unique()
    
claims = pandas.read_csv("../data/y1_Claims_clean")
dih = pandas.read_csv("../data/DaysInHospital_Y2.csv")
target = pandas.read_csv("../data/Target.csv")

procedure_group_list = claims["ProcedureGroup"].unique()
procedure_group_list.sort()  # makes NaN first element
procedure_group_list = procedure_group_list[1:] # removes NaN from list

spec_list = claims["Specialty"].unique()
spec_list.sort()  # makes NaN first element
spec_list = spec_list[1:]

cond_list = claims["PrimaryConditionGroup"].unique()
cond_list.sort()
cond_list = cond_list[1:]

char_list = claims["CharlsonIndex"].unique()

# Header for output
of = open("../data/y1_member_claim_count.csv","w")
cols = ["member_id",
        "days_in_hospital",
        "n_claims",
        "sum_pay_delay",
        ]
cols.extend(procedure_group_list)
cols.extend(spec_list)
cols.extend(cond_list)
#cols.extend(char_list)
of.write(",".join(cols)+"\n")

# rows of output
for i in range(len(target)):
    member_id = target["MemberID"][i]
    
    members_claims_ix = claims["MemberID"] == member_id
    days_in_hospital = sum(list(dih[dih["MemberID"] == member_id]["DaysInHospital"]))
    n_claims = len(claims[ claims["MemberID"] == member_id])
    sum_pay_delay = sum(list(claims[claims["MemberID"] == member_id]["PayDelay"]))
    list(claims[claims["MemberID"] == member_id]["ProcedureGroup"].values)
    
    p_cnts = []
    for p in procedure_group_list:
        p_cnts.append(list(claims[members_claims_ix]["ProcedureGroup"].values).count(p))
    
    s_cnts = []
    for s in spec_list:
        s_cnts.append(list(claims[members_claims_ix]["Specialty"].values).count(s))
    
    c_cnts = []
    for c in cond_list:
        c_cnts.append(list(claims[members_claims_ix]["PrimaryConditionGroup"].values).count(c))

    ch_cnts = []
    for ch in char_list:
        ch_cnts.append(list(claims[members_claims_ix]["CharlsonIndex"].values).count(ch))
        
    
    # write row
    of.write("{},{},{},{}".format(
        member_id,
        days_in_hospital,
        n_claims,
        sum_pay_delay
        ))
    of.write(",".join([str(x) for x in p_cnts]))
    of.write(",".join([str(x) for x in s_cnts]))
    of.write(",".join([str(x) for x in c_cnts]))
    #of.write(",".join([str(x) for x in ch_cnts]))
    of.write("\n")
    if i!=0 and i % 1000 == 0:
        #of.close()
        #sys.exit()
        print i

