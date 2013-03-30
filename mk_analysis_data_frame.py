 # Create analysis data frame
import datetime
import sys
import pandas
import numpy
from multiprocessing import Pool
from collections import Counter
import pdb # pdb.set_trace()

MULTI = False
TARGET = pandas.read_csv("../data/Target.csv")
#MEMBERS = [int(x.rstrip("\n")) for x in open("../data/unique_members.csv").readlines()]
import csv
#If you combine the member ids from DIH tables (Y2,Y3,Y4), and drop duplicates, 
# you will have 113,000 unique members. They are the same members represented in the claims.
dr = csv.DictReader(open("../data/Members_wInt.csv"))
MEMBERS_DICT = {}
for d in dr:
    MEMBERS_DICT[int(d["MemberID"])] = d  # int removes left padding with zero

MEMBERS = MEMBERS_DICT.keys()



def EDA():
    print claims.groupby("PrimaryConditionGroup").count()
    print claims.groupby("ProcedureGroup").count()
    print claims["ProcedureGroup"].unique()

def read_files(year_i,years):
    # global claims
    # global dih
    # global of
    # join the next year's DIH to this year's claims
    dih = pandas.read_csv("../data/DaysInHospital_{}.csv".format(years[year_i+1]))
    claims = pandas.read_csv("../data/{}_Claims_clean2.csv".format(  years[year_i]))
    of = open("../data/{}_member_claim_count3.csv".format(years[year_i]),"w")
    return claims, dih, of

def get_uniqs_wout_nan(claims,col):
    print col
    uniqs = claims[col].unique()
    uniqs.sort()  # makes NaN first element
    # remove NaN from list if needed
    #if  numpy.isnan(uniqs[0]):
    #    uniqs = uniqs[1:] # removes NaN from list
    return uniqs


def cnt_occurences(col,allvalues):
    cnt_list = []
    for avalue in allvalues:
        if "NaN" in avalue: avalue = numpy.nan
        vcnt = list(col).count(avalue)
        cnt_list.append(vcnt)
    #pdb.set_trace()
    return cnt_list

def cnt_occurences_multi(tuplein):
    col = tuplein[0]
    values = tuplein[1]
    cnt_list = []
    cnts = Counter(col)
    for value in values:
        if cnts.has_key(value):
            cnt_list.append(cnts[value])  # member_claims is in main
        else:
            cnt_list.append(0) 
    return cnt_list


def process_member(tin):
    member_id, claims, dih = tin[0], tin[1], tin[2]
    #member_id = TARGET["MemberID"][i]
    # subset claims data frame for this member
    #pdb.set_trace()

    member_claims = claims[ claims["MemberID"] == member_id]

    # Continuous Variables
    days_in_hospital = sum(list(dih[dih["MemberID"] == member_id]["DaysInHospital"]))
    age_at_first_claim = numpy.mean([float(x) for x in list(member_claims["AgeAtFirstClaim"]) if not numpy.isnan(x)])
    #pdb.set_trace()
    n_claims = len(member_claims)
    sum_pay_delay = sum(list(member_claims["PayDelay"]))
    sum_charlson = sum(list(member_claims["CharlsonIndex"]))
    
    # Factors
    if MULTI:
        cntme = (
            (member_claims.ProcedureGroup.values,procedure_group_list),
            (member_claims.Specialty,spec_list),
            (member_claims.PrimaryConditionGroup,cond_list),
            (member_claims.PlaceSvc,plsv_list),
            (member_claims.CharlsonIndex,char_list)
        )
        cnts = pool.map(cnt_occurences_multi,cntme)
        p_cnts,s_cnts,c_cnts,plsv_cnts,h_cnts = cnts
    else:
        #pdb.set_trace()
        p_cnts = cnt_occurences(member_claims.ProcedureGroup.values,procedure_group_list)
        s_cnts = cnt_occurences(member_claims.Specialty,spec_list)
        c_cnts = cnt_occurences(member_claims.PrimaryConditionGroup,cond_list)
        plsv_cnts = cnt_occurences(member_claims.PlaceSvc,plsv_list)
        #ch_cnts = cnt_occurences(member_claims.CharlsonIndex,char_list) #this is continuous

    # write row
    #of.write(

    aline = "{},{},{},{},{},{},".format(
        member_id,
        str(MEMBERS_DICT[member_id]["Sex"]),
        #str(MEMBERS_DICT[member_id]["AgeAtFirstClaim"]),  # This doesn't have the string parsing (i.e. "55-60")
        #str(age_at_first_claim),
        str(MEMBERS_DICT[member_id]["AgeInt"]),
        str(days_in_hospital),
        str(n_claims),
        str(sum_pay_delay),
        str(sum_charlson),
        )
    #of.write(
    aline += ",".join([str(x) for x in p_cnts])+","
    aline +=(",".join([str(x) for x in s_cnts]))+","
    aline +=(",".join([str(x) for x in c_cnts]))+","
    aline +=(",".join([str(x) for x in plsv_cnts]))+"\n"
    #aline +=(",".join([str(x) for x in ch_cnts]))
    #pdb.set_trace()
    return aline


def main():
    years = ["Y1","Y2","Y3","Y4"]
    #years = ["Y2","Y3","Y4"]
    #years = ["Y1","Y2"]
    for year_i in xrange(len(years)-1):
        #pool = Pool(processes=5)
        print "Working on {}".format(years[year_i])
        #claims, dih, of = read_files(year)
        claims, dih, of = read_files(year_i,years   )
        #read_files(year_i,years)

        print "done readin" 
        
        # Create lists of unique values for each column
        global procedure_group_list
        procedure_group_list = get_uniqs_wout_nan(claims,"ProcedureGroup")
        procedure_group_list[0] = "ProcedureGroupNaN"
        global spec_list
        spec_list = get_uniqs_wout_nan(claims,"Specialty")
        spec_list[0] = "SpecialtyNaN"
        global cond_list
        cond_list = get_uniqs_wout_nan(claims,"PrimaryConditionGroup")
        cond_list[0] = "PrimaryConditionGroupNaN"
        global plsv_list
        plsv_list = get_uniqs_wout_nan(claims,"PlaceSvc")
        plsv_list[0] = "PlaceSvcNaN"
        global char_list
        char_list = list(set(claims.CharlsonIndex))  # No NaNs. breaks get_uniq
        char_list[0]  = "CharlsonIndexNaN"
        
        # Header for output
        cols = ["member_id",
                "Sex",
                "AgeAtFirstClaim",
                "days_in_hospital",
                "n_claims",
                "sum_pay_delay",
                "CharlsonSum",
                ]
        cols.extend(procedure_group_list)
        cols.extend(spec_list)
        cols.extend(cond_list)
        cols.extend(plsv_list)
        #cols.extend(char_list)
        #pdb.set_trace()
        lines = []
        #of.write(",".join(cols)+"\n")
        lines.append(",".join([str(x) for x in cols])+"\n")

        # For each Member in the Target file

        #for i in range(len(TARGET)):
        for i in xrange(len(MEMBERS)):
        #for i in range(10):  # for debugging
            
            #print "inside iteration over MEMBERS - " + str(i)
        
            aline = process_member((MEMBERS[i], claims, dih))
            #aline = process_member((TARGET["MemberID"][i], claims, dih))
            #aline = process_member(TARGET["MemberID"][i])
            lines.append(aline)
            if i!=0 and i % 1000 == 0:
                print i
                #break
                
        print "writing"
        of.writelines(lines)
        of.close()

if __name__ == "__main__":
    main()