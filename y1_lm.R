library("randomForest")

# Load Training

y1df <- read.csv("../data/y1_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
                 
y1df <- y1df[,1:75]



y1df <- y1df[complete.cases(y1df),]

y2df <- read.csv("../data/y2_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y2df <- y2df[,1:75]
y2df <- y2df[complete.cases(y2df),]

# Load Prediction
target <- read.csv("../data/Target.csv",
                  header=TRUE) 
y3df <- read.csv("../data/y3_member_claim_count.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y3df <- y3df[,1:75]
#y3df <- y3df[complete.cases(y3df),]


# only member_ids in the target file will be used
logical_list <- rep(FALSE,length(y3df$member_id))
for (i in 1:length(y3df$member_id)){
  logical_list[i] <- is.element(y3df$member_id[i], target$MemberID)
}


gc()

# Predict

rf1 <- randomForest(days_in_hospital ~ .-member_id, 
                    data=y1df,
                    ntree=30, # for debugging
                    sampsize=nrow(y1df)/8,
                    #xtest=subset(y2df, select = -c(member_id,days_in_hospital) ),
                    #ytest=y2df$days_in_hospital,
                    keep.forest=TRUE
                    )

rf2 <- randomForest(days_in_hospital ~ .-member_id, 
                    data=y2df,
                    ntree=30, # for debugging
                    sampsize=nrow(y1df)/8,
                    #xtest=subset(y3df, select = -c(member_id,days_in_hospital) ),
                    #ytest=y3df$days_in_hospital,
                    keep.forest=TRUE
                    )

# Predict

y3df$rf1 <- predict(rf1, y3df )
y3df$rf2 <- predict(rf2, y3df )

# Post-process predictions

y3df$constant <- rep(0.209179,length(y3df[,1]))

#y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$rf2)
#y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$constant))
y3df$avgrf <- rowMeans(data.frame(y3df$rf1,y3df$rf2,y3df$constant))



# Remove negative guesses
#y3df[y3df$avg_fitted_days_in_hospital < 0,]$avg_fitted_days_in_hospital <- 0

# Write result

y3df$SupLOS <- rep(0,length(y3df[,1]))

submission_file <- "../submissions/target_20130324.csv"

write.csv(y3df[logical_list,c("member_id","SupLOS","avgrf")], 
          file=submission_file, row.names=FALSE)

submission <- read.csv(submission_file,
                       header=TRUE,
                       na.strings = c("NA","nan", ""))



hist(submission$avgrf)
plot(density(submission$avgrf))
print(summary(submission$avgrf))




