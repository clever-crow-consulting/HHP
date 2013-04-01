library("party")
library("rpart")
library("tree")

#
# Functions
#

eda_zero_predictions <- function(adf){  # ADF = "A Data Frame"
    err1 <- rep(0,101) # FALSE/FALSE 
    err2 <- rep(0,101) # FALSE/TRUE or TRUE/FALSE (error)
    err3 <- rep(0,101) # TRUE/TRUE
    perc <- rep(0,101) # TRUE/TRUE
    x <- seq(0,100)/100
    cnt = 1
    for (i in x){
      err1[cnt] <- table((adf$zero.ctree >= i) + adf$is.zero)[1]
      err2[cnt] <- table((adf$zero.ctree >= i) + adf$is.zero)[2]
      err3[cnt] <- table((adf$zero.ctree >= i) + adf$is.zero)[3]
      perc[cnt] <- sum(adf$zero.ctree >= i) / length(adf$zero.ctree)
      cnt <- cnt+1
    }
    par(mfrow=c(2,2))
    plot(x,err1/sum(adf$is.zero),main="% FALSE as FALSE")
    plot(x,err2/length(err2),main="% TRUE as FALSE or % FALSE as TRUE")
    plot(x,err3/sum(adf$is.zero),main="% TRUE as TRUE")
    plot(x,perc,main="% Zero")
}


model_perfect_zeros <- function(y1df,y2df,model1,model2){
  y1df.zeros <- y1df$days_in_hospital == 0
  y2df.zeros <- y2df$days_in_hospital == 0
  
  #print("Y1 Model's performance on its own training data:")
  y1df$model1 <- predict(model1,y1df) 
  y1df$model1[y1df.zeros] <- 0
  y1y1 <- get_score(y1df$model1,y1df$days_in_hospital)
  
  #print("Y1's performance on the following year:")
  y2df$model1 <- predict(model1,y2df)
  y2df$model1[y2df.zeros] <- 0
  y1y2 <- get_score(y2df$model1,y2df$days_in_hospital)
  
  #print("Y2 Model's performance on its own training data:")
  y2df$model2 <- predict(model2,y2df) 
  y2df$model2[y2df.zeros] <- 0
  y2y2 <- get_score(y2df$model2,y2df$days_in_hospital)
  
  #print("Y2's performance on the prior year:")
  y1df$model2 <- predict(model2,y1df)
  y1df$model2[y1df.zeros] <- 0
  y2y1 <- get_score(y1df$model2,y1df$days_in_hospital)
  
  print(cbind(c(y1y1,y1y2),c(y2y1,y2y2)))
  print(mean(y1y2,y2y1))
}

model_and_report <- function(y1df,y2df,model1,model2){
  
  #print("Y1 Model's performance on its own training data:")
  y1df$model1 <- predict(model1,y1df) 
  y1y1 <- get_score(y1df$model1,y1df$days_in_hospital)
  
  #print("Y1's performance on the following year:")
  y2df$model1 <- predict(model1,y2df)
  y1y2 <- get_score(y2df$model1,y2df$days_in_hospital)
  
  #print("Y2 Model's performance on its own training data:")
  y2df$model2 <- predict(model2,y2df) 
  y2y2 <- get_score(y2df$model2,y2df$days_in_hospital)
  
  #print("Y2's performance on the prior year:")
  y1df$model2 <- predict(model2,y1df)
  y2y1 <- get_score(y1df$model2,y1df$days_in_hospital)
  
  print(cbind(c(y1y1,y1y2),c(y2y1,y2y2)))
  print(mean(y1y2,y2y1))
}

get_score <- function( predictions, truth ){
  score <- (log(predictions+1) - log(truth+1))^2
  return(sqrt(sum(score, na.rm=TRUE) / sum(!is.na(score))))
}

read_frame <- function(filename){
  adf <- read.csv(filename,
                   header=TRUE,
                   na.strings = c("NA","nan", ""))
  # Remove a column:
  adf <- adf[,!(names(adf) %in% c("Urgent.Care"))] #FixMe: look for bug in .py scripts
  adf$is.zero <- adf$days_in_hospital == 0
  return(adf)
}

subset_to_target_members <- function(adf,tdf){
  # only member_ids in the target file will be used
  logical_list <- rep(FALSE,length(adf$member_id))
  for (i in 1:length(adf$member_id)){
    logical_list[i] <- is.element(adf$member_id[i], tdf$MemberID)
  }
  return(adf[logical_list,])
}


#
# Data in
#
target <- read.csv("../data/Target.csv",
                   header=TRUE) 
y1df <- read_frame("../data/Y1_member_claim_count3.csv")
y2df <- read_frame("../data/Y2_member_claim_count3.csv")
y3df <- read_frame("../data/Y3_member_claim_count3.csv")

# Optional: model only target members
if (TRUE){
  y1df <- subset_to_target_members(y1df,target)
  y2df <- subset_to_target_members(y2df,target)
  y3df <- subset_to_target_members(y3df,target)
}

gc()
#
# Model Zeros
#
zero.y1.ctree <- ctree(is.zero ~ n_claims+Sex+AgeAtFirstClaim+sum_pay_delay+CharlsonSum, data=y1df)
zero.y2.ctree <- ctree(is.zero ~ n_claims+Sex+AgeAtFirstClaim+sum_pay_delay+CharlsonSum, data=y2df)


# Assess predictions and set threshold
y2df$zero.ctree <- Predict(zero.y1.ctree, newdata=y2df)
y1df$zero.ctree <- Predict(zero.y2.ctree, newdata=y1df)
eda_zero_predictions(y1df)
eda_zero_predictions(y2df)

# Predict Zeros in Y3 with zero models trained on Y1 and Y2

y3df$zero.y1.ctree <- Predict(zero.y1.ctree, newdata=y3df)
y3df$zero.y2.ctree <- Predict(zero.y2.ctree, newdata=y3df)

#
# Determine the zero threshold with EDA
#
# Range appears to be .65 - 1.0
zero.prediction.threshold <- .752

#
# Create Training Data.Frames
#
# Because of the zero inflated nature of the data and the evaluation
#  metric's bias for short stays, the training data uses only
#  members with short, non-zero days_in_hospital.
#
stay_length_threshold <- 5.0 # will model stays of c(1,2,3,4)
y1train <- y1df[y1df$is.zero == FALSE & y1df$days_in_hospital < stay_length_threshold,1:92]
y2train <- y1df[y1df$is.zero == FALSE & y2df$days_in_hospital < stay_length_threshold,1:92]

# Build Model
dih.y1.ctree <- ctree(days_in_hospital ~ ., data=y1train)
dih.y2.ctree <- ctree(days_in_hospital ~ ., data=y2train)
# ToDo: plot models to file

# Predict year 3 using models from both years into its own column
y3df$dih.y1.ctree.w.zero <- predict(dih.y1.ctree, y3df )
y3df$dih.y2.ctree.w.zero <- predict(dih.y2.ctree, y3df )

# Apply zeros to prediction in new column (for later comparison)
y3df$dih.y1.ctree <- y3df$dih.y1.ctree.w.zero
y3df$dih.y2.ctree <- y3df$dih.y2.ctree.w.zero
y3df$dih.y1.ctree[y3df$zero.y1.ctree > zero.prediction.threshold] <- 0
y3df$dih.y2.ctree[y3df$zero.y2.ctree > zero.prediction.threshold] <- 0

submission_file <- "../submissions/target_20130401_y1.csv"
y3df$SupLOS <- 0
write.csv(y3df[,c("member_id","SupLOS","dih.y1.ctree")], 
          file=submission_file, row.names=FALSE)

submission_file <- "../submissions/target_20130401_y2.csv"
y3df$SupLOS <- 0
write.csv(y3df[,c("member_id","SupLOS","dih.y2.ctree")], 
          file=submission_file, row.names=FALSE)

