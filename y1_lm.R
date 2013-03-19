#library("ipred")
#library("tree")
library("randomForest")

y1df <- read.csv("../data/y1_member_claim_count.csv",header=TRUE)
y1df <- y1df[,1:75]
y1df <- y1df[complete.cases(y1df),]

#y2df <- read.csv("../data/y2_member_claim_count.csv",header=TRUE)
ftdf <- read.csv("../data/y3_member_claim_count.csv",header=TRUE)
ftdf <- ftdf[,1:75]
ftdf <- ftdf[complete.cases(ftdf),]
#mem_list <- unique(ftdf$member_id)

#y1df <- y1df[mem_list,]
#y2df <- y2df[mem_list,]

gc()

#y1df[is.na(y1df)] <- 0  # Gotcha!  This was stupid!
#y2df[is.na(y2df)] <- 0  # Gotcha!  This was stupid!
#ftdf[is.na(ftdf)] <- 0  # Gotcha!  This was stupid!

# Predict

#y1lm <- lm(days_in_hospital ~ .-member_id, data=y1df)
#y2lm <- lm(days_in_hospital ~ .-member_id, data=y2df)
#y1tree <- tree(days_in_hospital ~ .-member_id, data=y1df)
#y2tree <- tree(days_in_hospital ~ .-member_id, data=y2df)
#y1_treebag <- bagging(days_in_hospital ~ .-member_id, data=y1df)
#y2_treebag <- bagging(days_in_hospital ~ .-member_id, data=y2df)
train_rows = sample(nrow(y1df)/2)
rf1 <- randomForest(days_in_hospital ~ .-member_id, data=y1df[train_rows,])

# Fit

#ftdf$y1lm_fitted_days_in_hospital <- predict(y1tree, ftdf)
#ftdf$y2lm_fitted_days_in_hospital <- predict(y2tree, ftdf)
#ftdf$y1_treebag <- predict(y1_treebag, ftdf)
#ftdf$y2_treebag <- predict(y2_treebag, ftdf)
#ftdf$avg_treebag <- rowMeans(data.frame(ftdf$y1_treebag,ftdf$y2_treebag))

ftdf$rf1 <- predict(rf1, ftdf)
 
#ftdf$avg_fitted_days_in_hospital <- rowMeans(data.frame(ftdf$y1lm_fitted_days_in_hospital,ftdf$y2lm_fitted_days_in_hospital))
# Remove negative guesses
#ftdf[ftdf$avg_fitted_days_in_hospital < 0,]$avg_fitted_days_in_hospital <- 0

ftdf$SupLOS <- rep(0,length(ftdf[,1]))


write.csv(ftdf[,c("member_id","SupLOS","rf1")], 
          file="../data/target_20130317_rf1.csv", row.names=FALSE)