#library("party")
library("rpart")

#
# Functions
#
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

#
# Data in
#
target <- read.csv("../data/Target.csv",
                   header=TRUE) 

y1df <- read.csv("../data/Y1_member_claim_count3.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y1df <- y1df[,!(names(y1df) %in% c("Urgent.Care"))] #FixMe: look for bug in .py scripts
y1df$is.zero <- y1df$days_in_hospital == 0
y1df$is.max <- y1df$days_in_hospital == 15

# Y2
y2df <- read.csv("../data/Y2_member_claim_count3.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))

y2df <- y2df[,!(names(y2df) %in% c("Urgent.Care"))]
y2df$is.zero <- y2df$days_in_hospital == 0
y2df$is.max <- y2df$days_in_hospital == 15

y3df <- read.csv("../data/y3_member_claim_count3.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))


# only member_ids in the target file will be used
logical_list <- rep(FALSE,length(y3df$member_id))
for (i in 1:length(y3df$member_id)){
  logical_list[i] <- is.element(y3df$member_id[i], target$MemberID)
}

y3df <- y3df[,!(names(y3df) %in% c("Urgent.Care"))] #FixMe: look for bug in .py scripts

#
# Model
#
tree.y1.zero <- ctree(is.zero ~ n_claims+Sex+AgeAtFirstClaim+sum_pay_delay+CharlsonSum, data=y1df)
# Predict
y1df$tree.y1.zero <- Predict(tree.y1.zero, newdata=y1df)
y2df$tree.y1.zero <- Predict(tree.y1.zero, newdata=y2df)
y3df$tree.y1.zero <- Predict(tree.y1.zero, newdata=y3df)


tree.y1.max <- ctree(is.max ~ n_claims+Sex+AgeAtFirstClaim+sum_pay_delay+CharlsonSum, data=y1df)
y2df$tree.y1.max <- Predict(tree.y1.max, newdata=y2df)
y3df$tree.y1.max <- Predict(tree.y1.max, newdata=y3df)


train <- y1df[y1df$tree.y1.zero < .8,1:92]
ctree <- ctree(days_in_hospital ~ ., data=train)


# Predict year 3 using model from year 1
y3df$ctree <- predict(ctree, y3df )

#Predict zeros in year 3 using ctree from year 1
y3df$y1ctree.likelihood.zero <- predict(tree.y1.zero, y3df )
y3df[y3df$y1ctree.likelihood.zero > .8,"ctree"] <- 0


submission_file <- "../submissions/target_20130330.csv"
y3df$SupLOS <- 0
write.csv(y3df[logical_list,c("member_id","SupLOS","ctree")], 
          file=submission_file, row.names=FALSE)
