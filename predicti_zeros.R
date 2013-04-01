#predict zeros
library("party")

y1df <- read.csv("../data/Y1_member_claim_count3.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y1df <- y1df[,!(names(y1df) %in% c("Urgent.Care"))] #FixMe: look for bug in .py scripts
y1df$is.zero <- y1df$days_in_hospital == 0
y1df$is.max <- y1df$days_in_hospital == 15

y2df <- read.csv("../data/Y2_member_claim_count3.csv",
                 header=TRUE,
                 na.strings = c("NA","nan", ""))
y2df <- y2df[,!(names(y2df) %in% c("Urgent.Care"))] #FixMe: look for bug in .py scripts
y2df$is.zero <- y2df$days_in_hospital == 0
y2df$is.max <- y2df$days_in_hospital == 15



#zed <- ctree(is.zero ~ AgeAtFirstClaim + n_claims + Sex, data=y1df)

zed <- ctree(is.zero ~ n_claims+Sex+AgeAtFirstClaim+sum_pay_delay+CharlsonSum, data=y1df)

y2df$zero.pred <- Predict(zed,y2df)

err <- rep(0,1001)
x <- seq(0,1000)/1000
cnt = 1
for (i in x){
  err[cnt] <- (table((y2df$zero.pred > i) + y2df$is.zero)[1])
  cnt <- cnt+1
}
plot(x,err)


