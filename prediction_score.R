


y1df$rf1 <- predict(rf1,y1df)
y1df[(y1df$rf1 < 0) & (!is.na(y1df$rf1)),"rf1"] <- 0
y1df$score <- ( log(y1df$rf1+1) - log(y1df$days_in_hospital+1)  )^2
sqrt(  sum(y1df$score, na.rm = TRUE)  /    sum(!is.na(y1df$score)) )


y2df$rf1 <- predict(rf1,y2df)
y2df[(y2df$rf1 < 0) & (!is.na(y2df$rf1)),"rf1"] <- 0
y2df$score <- ( log(y2df$rf1+1) - log(y2df$days_in_hospital+1)  )^2
sqrt(  sum(y2df$score, na.rm = TRUE)  /    sum(!is.na(y2df$score)) )



y2df[(y2df$plm1 < 0) & (!is.na(y2df$plm1)),"plm1"] <- 0
y2df$score <- ( log(y2df$plm1+1) - log(y2df$days_in_hospital+1)  )^2
sqrt(  sum(y2df$score, na.rm = TRUE)  /    sum(!is.na(y2df$score)) )


# This next line is a problem
y1df[(y1df$plm1 < 0) & (!is.na(y1df$plm1)),"plm1"] <- 0
y1df$score <- ( log(y1df$plm1+1) - log(y1df$days_in_hospital+1)  )^2
sqrt(  sum(y1df$score, na.rm = TRUE)  /    sum(!is.na(y1df$score)) )