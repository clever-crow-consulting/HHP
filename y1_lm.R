library("randomForest")

# Load Training
# ToDo: do all members in target have age at first claim set?
# ToDo: do all members in target have Sex set?

# 20% of Target Members have NA for either Sex or AgeAtFirstClaim.  Set these to 'U'

# Load Prediction
target <- read.csv("../data/Target.csv",
                   header=TRUE) 
y3df <- read.csv("../data/y3_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y3df <- y3df[,1:75]
#y3df <- y3df[complete.cases(y3df),] # Deprecated. Now replace with factor 'U'
# Fix missing factor in Sex and AgeAtFirstClaim by creating a U factor
y3df$Sex <- factor(y3df$Sex, levels=c(levels(y3df$Sex), 'U')) 
y3df[!complete.cases(y3df$Sex),"Sex"] <- "U"

y3df$AgeAtFirstClaim <- factor(y3df$AgeAtFirstClaim, levels=c(levels(y3df$AgeAtFirstClaim), 'U')) 
y3df[!complete.cases(y3df$AgeAtFirstClaim),"AgeAtFirstClaim"] <- "U"


# only member_ids in the target file will be used
logical_list <- rep(FALSE,length(y3df$member_id))
for (i in 1:length(y3df$member_id)){
  logical_list[i] <- is.element(y3df$member_id[i], target$MemberID)
}

# Subset data frame, Only train with members in Target.csv 
y3df <- y3df[logical_list,]


# Year 1 Model

y1df <- read.csv("../data/y1_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
                 
y1df <- y1df[,1:75]

#y1df <- y1df[complete.cases(y1df),] # Deprecated like Y3
# Fix missing factor in Sex and AgeAtFirstClaim by creating a U factor
y1df$Sex <- factor(y1df$Sex, levels=c(levels(y1df$Sex), 'U')) 
y1df[!complete.cases(y1df$Sex),"Sex"] <- "U"

y1df$AgeAtFirstClaim <- factor(y1df$AgeAtFirstClaim, levels=c(levels(y1df$AgeAtFirstClaim), 'U')) 
y1df[!complete.cases(y1df$AgeAtFirstClaim),"AgeAtFirstClaim"] <- "U"

y1.members.in.target <- rep(FALSE,length(y1df$member_id))
for (i in 1:length(y1df$member_id)){
  y1.members.in.target[i] <- is.element(y1df$member_id[i], target$MemberID)
}

y1df <- y1df[y1.members.in.target,]
gc() # Garbage collect after removing lots of rows.

# Model
rf1 <- randomForest(days_in_hospital ~ .-member_id, 
                    data=y1df,
                    ntree=30, # for debugging
                    sampsize=nrow(y1df)/8,
                    #xtest=subset(y2df, select = -c(member_id,days_in_hospital) ),
                    #ytest=y2df$days_in_hospital,
                    keep.forest=TRUE
                    )

# Predict year 3 using model from year 1
y3df$rf1 <- predict(rf1, y3df )
# stop()
rm(y1df)
gc()

print("Y1 done.")

y2df <- read.csv("../data/y2_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y2df <- y2df[,1:75]
#y2df <- y2df[complete.cases(y2df),]

y2df$Sex <- factor(y2df$Sex, levels=c(levels(y2df$Sex), 'U')) 
y2df[!complete.cases(y2df$Sex),"Sex"] <- "U"

y2df$AgeAtFirstClaim <- factor(y2df$AgeAtFirstClaim, levels=c(levels(y2df$AgeAtFirstClaim), 'U')) 
y2df[!complete.cases(y2df$AgeAtFirstClaim),"AgeAtFirstClaim"] <- "U"



rf2 <- randomForest(days_in_hospital ~ .-member_id, 
                    data=y2df,
                    ntree=30, # for debugging
                    sampsize=nrow(y2df)/8,
                    #xtest=subset(y3df, select = -c(member_id,days_in_hospital) ),
                    #ytest=y3df$days_in_hospital,
                    keep.forest=TRUE
                    )

y3df$rf2 <- predict(rf2, y3df )

# Post-process predictions

y3df$constant <- rep(0.209179,length(y3df[,1]))

#y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$rf2)
#y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$constant))

#ToDo: only change non zero 
keepzero <- ((y3df$rf1 == 0) | (y3df$rf2 == 0))  #These will be set back to 0

keepzero.and.logical_list <- (keepzero & logical_list)

y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$rf2,y3df$constant))


y3df[keepzero,"avgrf"] <- 0

#sum(y3df[y3df$rf1 > 0,]$rf1)

# Remove negative guesses
#y3df[y3df$avg_fitted_days_in_hospital < 0,]$avg_fitted_days_in_hospital <- 0

# Write result

y3df$SupLOS <- rep(0,length(y3df[,1]))

#y3df[sapply(y3df[logical_list,]$avgrf,is.na),]$avgrf

#y3df[is.na(y3df$avgrf),"avgrf"] <- 0.209179  # Deprecated

submission_file <- "../submissions/target_20130328.csv"

write.csv(y3df[logical_list,c("member_id","SupLOS","avgrf")], 
          file=submission_file, row.names=FALSE)

submission <- read.csv(submission_file,
                       header=TRUE,
                       na.strings = c("NA","nan", ""))

hist(submission$avgrf)
plot(density(submission$avgrf))
print(summary(submission$avgrf))
print(length(submission$avgrf))