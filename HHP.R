

dih <- read.csv("../data/DaysInHospital_Y2.csv",header=TRUE)

claims.with.missing <- read.csv("../data/Claims_clean.csv",header=TRUE)

c <- claims.with.missing
stop()


claims <- claims.with.missing[which(complete.cases(claims.with.missing)),]



claims <- claims[claims["Year"]=="Y1",]

claims$ProviderID <- as.factor(claims$ProviderID)
claims$Vendor <- as.factor(claims$Vendor)
claims$PCP <- as.factor(claims$PCP)

target <- read.csv("../data/Target.csv",header=TRUE)


y2 <- merge(x = claims, y = dih, by = "MemberID", all.y = TRUE)
y2 <- y2[which(complete.cases(y2)),]

stop()

slm1 <- step(lm(log(DaysInHospital) ~ 
              PrimaryConditionGroup + 
              ProcedureGroup + 
              CharlsonIndex 
              , data=y2))

print(summary(slm1))
print(sapply(y2,class))
