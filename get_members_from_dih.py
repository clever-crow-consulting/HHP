#get_members_from_dih.py
import csv

infilenames = [
    r"C:\Users\DanDye\Google Drive\Projects\HeritageHealthPrize\data\DaysInHospital_Y2.csv",
    r"C:\Users\DanDye\Google Drive\Projects\HeritageHealthPrize\data\DaysInHospital_Y2.csv"]

members = []

for infilename in infilenames:
    creader = csv.reader(infilename)
    lines = list(creader)
    for aline in lines:
        members.append(aline[0]])

members = list(set(members))