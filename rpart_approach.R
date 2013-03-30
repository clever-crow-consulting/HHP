library("tree")
library("rpart")
#library("randomForest")
target <- read.csv("../data/Target.csv",
                   header=TRUE) 

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

# Data in
y1df <- read.csv("../data/Y1_member_claim_count3.csv")
y1df <- y1df[,!(names(y1df) %in% c("Urgent.Care"))]
y2df <- read.csv("../data/Y2_member_claim_count3.csv")
y2df <- y2df[,!(names(y2df) %in% c("Urgent.Care"))]

# droplevels() fixes issue with randomForest according to 
# http://stackoverflow.com/questions/13495041/random-forests-in-r-empty-classes-in-y-and-argument-legth-0
suby1 <- droplevels(y1df[y1df$days_in_hospital != 0,])
suby2 <- droplevels(y2df[y2df$days_in_hospital != 0,])

#y3df <- read.csv("../data/Y3_member_claim_count3.csv")
#y3df <- y3df[,!(names(y3df) %in% c("Urgent.Care"))]

#
# RPart models
#
model <- "days_in_hospital ~ .-member_id"
print(c(model,"y1df/y2df"))
model1 <- rpart(model, data = y1df)
model2 <- rpart(model, data = y2df)
model_and_report(y1df,y2df,model1,model2)
print(c(model,"suby1/suby2"))
model1 <- rpart(model, data = suby1)
model2 <- rpart(model, data = suby2)
print("Non-zeros only")
model_and_report(y1df,y2df,model1,model2)
print("All data only")
model_and_report(suby1,suby2,model1,model2)


# Rpart w/ fewer terms
model <- "days_in_hospital~AgeAtFirstClaim+n_claims+Sex"
print(c(model,"y1df/y2df"))
model1 <- rpart(model, data = y1df)
model2 <- rpart(model, data = y2df)
model_and_report(y1df,y2df,model1,model2)

#
# Linear Models
#
model <- "days_in_hospital~n_claims+Sex+AgeAtFirstClaim"
print(c(model,"y1df/y2df"))
model1 <- lm(model, data = y1df)
model2 <- lm(model, data = y2df)
model_and_report(y1df,y2df,model1,model2)

model <- "days_in_hospital ~ .-member_id"
print(c(model,"y1df/y2df"))
model1 <- lm(model, data = y1df)
model2 <- lm(model, data = y2df)
model_and_report(y1df,y2df,model1,model2)

#
# Trees
#
model <- "days_in_hospital ~ .-member_id"
print(c(model,"y1df/y2df"))
model1 <- tree(model, data = y1df)
model2 <- tree(model, data = y2df)
model_and_report(y1df,y2df,model1,model2)


stop()
y3df$model1 <- predict(model1,y3df)
y3df$model2 <- predict(model2,y3df)

y3df$avgrp <- rowMeans(data.frame(y3df$model1,y3df$model2))
y3df$SupLOS <- 0

# only member_ids in the target file will be used
logical_list <- rep(FALSE,length(y3df$member_id))
for (i in 1:length(y3df$member_id)){
  logical_list[i] <- is.element(y3df$member_id[i], target$MemberID)
}

# Subset data frame to only Target members
#y3df <- y3df[logical_list,]

write.csv(y3df[logical_list,c("member_id","SupLOS","avgrp")], 
          file="../submissions/target_20130330.csv", row.names=FALSE)
