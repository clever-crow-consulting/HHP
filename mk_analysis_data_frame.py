 # Create analysis data frame
import sys
import pandas
import numpy
from multiprocessing import Pool
from collections import Counter

TARGET = pandas.read_csv("../data/Target.csv")

def EDA():
    print claims.groupby("PrimaryConditionGroup").count()
    print claims.groupby("ProcedureGroup").count()
    print claims["ProcedureGroup"].unique()

def read_files(year_i,years):
    # join the next year's DIH to this year's claims
    dih = pandas.read_csv("../data/DaysInHospital_{}.csv".format(years[year_i+1]))
    claims = pandas.read_csv("../data/{}_Claims_clean.csv".format(  years[year_i]))
    of = open("../data/{}_member_claim_count.csv".format(years[year_i]),"w")
    return claims, dih, of

def get_uniqs_wout_nan(claims,col):
    print col
    uniqs = claims[col].unique()
    uniqs.sort()  # makes NaN first element
    # remove NaN from list if needed
    if  numpy.isnan(uniqs[0]):
        uniqs = uniqs[1:] # removes NaN from list
    return uniqs


#def cnt_occurences(col,values):
def cnt_occurences(tuplein):
    col = tuplein[0]
    values = tuplein[1]
    cnt_list = []
    cnts = Counter(col)
    #print cnts
    #sys.exit()
    for value in values:
        #cnt_list.append(cnts[value])
        #cnt_list.append(list(member_claims[col].values).count(value))  # member_claims is in main
        #print value
        #print col
        #sys.exit()
        if cnts.has_key(value):
            cnt_list.append(cnts[value])  # member_claims is in main
        else:
            cnt_list.append(0)
        #cnt_list.append(list(col.values).count(value))  # member_claims is in main
        #cnt_list.append(col.count(value))  # member_claims is in main
    return cnt_list
    
    
def main():
    years = ["Y1","Y2","Y3","Y4"]
    for year_i in range(len(years)-1):
        pool = Pool(processes=5)  
        print "Working on {}".format(years[year_i])
        #claims, dih, of = read_files(year)
        claims, dih, of = read_files(year_i,years)

        # Create lists of unique values for each column
        procedure_group_list = get_uniqs_wout_nan(claims,"ProcedureGroup")
        spec_list = get_uniqs_wout_nan(claims,"Specialty")
        cond_list = get_uniqs_wout_nan(claims,"PrimaryConditionGroup")
        plsv_list = get_uniqs_wout_nan(claims,"PlaceSvc")
        char_list = list(set(claims.CharlsonIndex))  # No NaNs breaks get_uniq

        # Header for output
        cols = ["member_id",
                "days_in_hospital",
                "n_claims",
                "sum_pay_delay",
                ]
        cols.extend(procedure_group_list)
        cols.extend(spec_list)
        cols.extend(cond_list)
        cols.extend(plsv_list)
        cols.extend(char_list)
        
        lines = []
        #of.write(",".join(cols)+"\n")
        lines.append(",".join(cols)+"\n")

        co = cnt_occurences
        # For each Member in the Target file
        for i in range(len(TARGET)):
            member_id = TARGET["MemberID"][i]
            # subset claims data frame for this memeber
            member_claims = claims[ claims["MemberID"] == member_id]
            days_in_hospital = sum(list(dih[dih["MemberID"] == member_id]["DaysInHospital"]))
            n_claims = len(member_claims)
            sum_pay_delay = sum(list(member_claims["PayDelay"]))
            
            #p_cnts = co(member_claims,"ProcedureGroup",procedure_group_list)
            
            #print member_claims.ProcedureGroup.values
            #print procedure_group_list
            
            #print co((member_claims.ProcedureGroup.values,procedure_group_list))
            
            #sys.exit()
            
            cntme = (
                (member_claims.ProcedureGroup.values,procedure_group_list),
                (member_claims.Specialty,spec_list),
                (member_claims.PrimaryConditionGroup,cond_list),
                (member_claims.PlaceSvc,plsv_list),
                (member_claims.CharlsonIndex,char_list)
            )
            cnts = pool.map(co,cntme)
            p_cnts = cnts[0]
            s_cnts = cnts[1]
            c_cnts = cnts[2]
            plsv_cnts = cnts[3]
            ch_cnts = cnts[4]
            #p_cnts = co(member_claims.ProcedureGroup,procedure_group_list)
            #s_cnts = co(member_claims.Specialty,spec_list)
            #c_cnts = co(member_claims.PrimaryConditionGroup,cond_list)
            #plsv_cnts = co(member_claims.PlaceSvc,plsv_list)
            #ch_cnts = co(member_claims.CharlsonIndex,char_list)

            # write row
            #of.write(
            aline = "{},{},{},{}".format(
                member_id,
                days_in_hospital,
                n_claims,
                sum_pay_delay
                )
            #of.write(
            aline += ",".join([str(x) for x in p_cnts])
            aline +=(",".join([str(x) for x in s_cnts]))
            aline +=(",".join([str(x) for x in c_cnts]))
            aline +=(",".join([str(x) for x in plsv_cnts]))
            aline +=(",".join([str(x) for x in ch_cnts]))
            aline +=("\n")
            lines.append(aline)
            if i!=0 and i % 1000 == 0:
                #of.close()
                #sys.exit()
                print i
        of.write(lines)

if __name__ == "__main__":
    main()
