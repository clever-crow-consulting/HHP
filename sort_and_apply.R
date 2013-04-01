
subsort <- submission[with(submission, order(avgrf)), ]
y3dih <- read.csv("../provided_data/DaysInHospital_Y3.csv",
                  header=TRUE,
                  na.strings = c("NA","nan", ""))


y2dih <- read.csv("../provided_data/DaysInHospital_Y2.csv",
                               header=TRUE,
                               na.strings = c("NA","nan", ""))

y2quantiles <- quantile(y2dih$DaysInHospital,seq(7094)/7094)

submission_file <- "../submissions/target_20130325.csv"

submission <- read.csv(submission_file,
                       header=TRUE,
                       na.strings = c("NA","nan", ""))


submission$y2dihq2 <- rep(0,length(submission$member_id))

nrows <- length(submission$member_id)-1
end_i = nrows/10
submission$y2dihq2[1:2] <- 0
for (i in 1:end_i){
  #ix_start <- (i-1)*1+1
  ix_end <- i*10+2
  ix_start <- ix_end-9
  #print(i)
  #print(ix_start)
  #print(ix_end)
  submission$y2dihq2[ix_start:ix_end] <- y2quantiles[i]
}

# Now "pull back" the middle values to get closer to the target mean

ix <- (submission$y2dihq2 > 2.75) & (submission$y2dihq2 < 15) 

#

submission$y2dihq2[ix] = log(submission$y2dihq2[ix])
print("after log")
stop()

#0.209179
#submission$regress2mean <- submission$y2dihq2*.4470

write.csv(submission[,c("member_id","SupLOS","y2dihq2")], 
          file="../submissions/target_20130325_sort_apply_log.csv", row.names=FALSE)
