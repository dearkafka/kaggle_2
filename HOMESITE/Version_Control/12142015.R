
require(data.table); require(lubridate); require(caret); require(sqldf); require(xgboost); require(xlsx); require(dplyr); require(readr); require(doParallel)

rm(list = ls())

train_raw <- fread(input = "D:\\kaggle\\HOMESITE\\Data\\train.csv", data.table = F)

response <- train_raw$QuoteConversion_Flag

train_raw$QuoteConversion_Flag <- NULL

train_raw$QuoteNumber <- NULL



test_raw <- fread(input = "D:\\kaggle\\HOMESITE\\Data\\test.csv", data.table = F)

id <- test_raw$QuoteNumber

test_raw$QuoteNumber <- NULL



tmp <- rbind(train_raw, test_raw)

"Original_Quote_Date", "date"

tmp$Original_Quote_Date <- as.Date(tmp$Original_Quote_Date)

tmp$month <- as.integer(format(tmp$Original_Quote_Date, "%m"))

tmp$year <- as.integer(format(tmp$Original_Quote_Date, "%y"))

tmp$day <- weekdays(as.Date(tmp$Original_Quote_Date))

tmp$week <- week((as.Date(tmp$Original_Quote_Date)))

tmp$date <- (((tmp$year * 52 ) + tmp$week) %% 4)

# check which columns has NA

NA_list <- sapply(names(tmp),  function(x) sum(is.na(tmp[, x])))

NA_list <- NA_list[NA_list != 0]

  
tmp$PersonalField84 <- NULL

tmp$PropertyField29 <- NULL


row_NA <- apply(tmp, 1, function(x) sum(x == -1))

# feat_filled = as.integer(rowSums(tmp[, 1:ncol(tmp)] != 0)) 

# seperate character columns

char <- rep(0, length(names(tmp)))

for(i in names(tmp))
  
{
  if(class(tmp[, i]) == "character"){
    
  char <- c(char, i)
  }
  
  char <- char[char != 0 ]
}

# convert char columns to factors to dummify them

tmp_char <- tmp[, char]


for(f in names(tmp_dummy)){
  
  levels <- unique(tmp_dummy[, f])
  
  tmp_dummy[,f] <- factor(tmp_dummy[,f], levels = levels)
  
}


dummies <- dummyVars( ~., data = tmp_char)

tmp_char <- predict(dummies, newdata = tmp_char)

tmp_char <- data.frame(tmp_char)


rm(dummies)

gc()

# create dummy cols in batches

nominal_remove <- c("Field8", "Field9", "Field11")

tmp_dummy <- tmp[ , !(names(tmp) %in% c(char, nominal_remove , "Original_Quote_Date", "date", "SalesField8", "PropertyField6",  "GeographicField10A"))]

for(f in names(tmp_dummy)){
  
  levels <- unique(tmp_dummy[, f])
  
  tmp_dummy[,f] <- factor(tmp_dummy[,f], levels = levels)
  
}

# levels of tmp_dummy

len <- sapply(names(tmp_dummy), function(x) length(unique(tmp_dummy[,x])))

len[len<2]

table(tmp_dummy$PropertyField6)

tmp_id_1 <- data.frame(id = 1:nrow(tmp))

for(i in names(tmp_dummy)[1:266] )
    {
    
    dummies <- dummyVars( ~., data = tmp_dummy[i])
    tmp_char <- predict(dummies, newdata = tmp_dummy[i])
    tmp_char <- data.frame(tmp_char)
    
    tmp_id_1 <- cbind(tmp_id_1, tmp_char)
    
    rm(dummies)
    }


    
for (f in names(tmp)) {
  
  if (class(tmp[[f]])=="character") {
    
    levels <- unique(tmp[[f]])
    
    tmp[[f]] <- as.integer(factor(tmp[[f]], levels=levels))
    
  }
  
}




tmp_id_1 <- cbind(tmp, tmp_id_1)

rm(test_raw); rm(train_raw); rm(tmp_char)

tmp_id_1$row_NA <- row_NA

# add interaction terms

imp <- read_csv("D:\\kaggle\\HOMESITE\\FEATURE_IMP\\12062015_2.csv")

top_50 <- imp$Feature[1:5]

tmp_int <- tmp[, top_50]

for (f in top_50) {
  
  if (class(tmp_int[[f]])=="character") {
    
    levels <- unique(tmp_int[[f]])
    
    tmp_int[[f]] <- as.integer(factor(tmp_int[[f]], levels=levels))
  }
  
}


gc()

rm(imp); 

for (i in 1:ncol(tmp_int)) {
  
  for (j in (i + 1) : (ncol(tmp_int) + 1)) {
    
    #    a = i; b= j
    
    var.x <- colnames(tmp_int)[i]
    
    var.y <- colnames(tmp_int)[j]
    
    var.new <- paste0(var.x, '_plus_', var.y)
    
    tmp_int[ , paste0(var.new)] <- tmp_int[, i] + tmp_int[, j]
    
  }
}


gc()

tmp_new <- cbind(tmp_new, tmp_int)
rm(tmp_int)
gc()

# create - interaction features

# add interaction terms


imp <- read_csv("D:\\kaggle\\HOMESITE\\FEATURE_IMP\\12062015_2.csv")

top_50 <- imp$Feature[1:5]

tmp_int <- tmp[, top_50]

for (f in top_50) {
  
  if (class(tmp_int[[f]])=="character") {
    
    levels <- unique(tmp_int[[f]])
    
    tmp_int[[f]] <- as.integer(factor(tmp_int[[f]], levels=levels))
  }
  
}


gc()

rm(imp); 



for (i in 1:ncol(tmp_int)) {
  
  for (j in (i + 1) : (ncol(tmp_int) + 1)) {
    
    var.x <- colnames(tmp_int)[i]
    
    var.y <- colnames(tmp_int)[j]
    
    var.new <- paste0(var.x, '_minus_', var.y)
    
    tmp_int[ , paste0(var.new)] <- tmp_int[, i] - tmp_int[, j]
    
  }
}


gc()

tmp_new <- cbind(tmp_new, tmp_int)
rm(tmp_int)
gc()




# create * interaction features


# add interaction terms


imp <- read_csv("D:\\kaggle\\HOMESITE\\FEATURE_IMP\\12062015_2.csv")

top_50 <- imp$Feature[1:5]

tmp_int <- tmp[, top_50]

for (f in top_50) {
  
  if (class(tmp_int[[f]])=="character") {
    
    levels <- unique(tmp_int[[f]])
    
    tmp_int[[f]] <- as.integer(factor(tmp_int[[f]], levels=levels))
  }
  
}


gc()

rm(imp); 


for (i in 1:ncol(tmp_int)) {
  
  for (j in (i + 1) : (ncol(tmp_int) + 1)) {
    
    var.x <- colnames(tmp_int)[i]
    
    var.y <- colnames(tmp_int)[j]
    
    var.new <- paste0(var.x, '_mult_', var.y)
    
    tmp_int[ , paste0(var.new)] <- tmp_int[, i] * tmp_int[, j]
    
  }
}




tmp_new <- cbind(tmp_new, tmp_int)
rm(tmp_int)
gc()






##################################################################################

rm(tmp); rm(test_raw); rm(train_raw); rm(tmp_char); rm(tmp_int); rm(imp)

tmp_new$row_NA <- row_NA

#tmp_new$feat <- feat_filled

# converting to sparse matrix

rownames(tmp_id_1) <- tmp_id_1$id

tmp_id_1$id <- NULL

library(Matrix)

tmp_id_sparse <- Matrix(as.matrix(tmp_id_1), sparse = TRUE)



train <- tmp_new[c(1:260753), ]

test <- tmp_new[c(260754:434589), ]

rm(tmp_new)

gc()

#train[is.na(train)] <- -1

#test[is.na(test)] <- -1

gc()


###################################################################################################


feature.names <- names(train)

h<-sample(nrow(train),10000)

dval<-xgb.DMatrix(data=data.matrix(train[h,]),label=response[h])

dtrain<-xgb.DMatrix(data=data.matrix(train[-h,]),label=response[-h])

#dtrain<-xgb.DMatrix(data=data.matrix(train),label=response)

watchlist<-list(val=dval,train=dtrain)

param <- list(  objective           = "binary:logistic", 
                
                booster = "gbtree",
                
                eval_metric = "auc",
                
                eta                 = 0.01, # 0.06, #0.01,
                
                max_depth           = 6, #changed from default of 8
                
                subsample           = 0.83, # 0.7
                
                colsample_bytree    = 0.77, # 0.7
                
                num_parallel_tree = 2
                
)

start <- Sys.time()

require(doParallel)

cl <- makeCluster(2); registerDoParallel(cl)

set.seed(12*16*15)

cv <- xgb.cv(params = param, data = dtrain, 

            nrounds = 3000, 

           nfold = 3, 

          showsd = T, 

         maximize = F)


time_taken <- Sys.time() - start

write_csv(submission, "D:\\kaggle\\HOMESITE\\submission\\12092015\\12092015_cv.csv")



clf <- xgb.train(   params              = param,
                    
                    data                = dtrain,
                    
                    nrounds             = 3000,
                    
                    verbose             = 1,  #1
                    
                    #early.stop.round    = 400,
                    
                    watchlist           = watchlist,
                    
                    maximize            = FALSE,
                    
                    nthread = 2)


time_taken <- Sys.time() - start


pred <- predict(clf, data.matrix(test[,feature.names]))

submission <- data.frame(QuoteNumber = id, QuoteConversion_Flag = pred)

write_csv(submission, "D:\\kaggle\\HOMESITE\\submission\\12092015\\12092015_16.csv")

time_taken <- Sys.time() - start



pred <- predict(clf, data.matrix(test[,feature.names]), ntreelimit = 1000)

submission <- data.frame(QuoteNumber = id, QuoteConversion_Flag = pred)

write_csv(submission, "D:\\kaggle\\HOMESITE\\submission\\12092015\\12092015_3.csv")
