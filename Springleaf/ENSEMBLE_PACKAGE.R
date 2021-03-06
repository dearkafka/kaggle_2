library('caret')

library('mlbench')

library('pROC')

data(Sonar)

set.seed(107)

inTrain <- createDataPartition(y = Sonar$Class, p = .75, list = FALSE)

training <- Sonar[ inTrain,]

testing <- Sonar[-inTrain,]

my_control <- trainControl(

    method='boot',
  
    number=25,
  
    savePredictions=TRUE,
  
    classProbs=TRUE,
  
    index=createResample(training$Class, 25),
  
    summaryFunction=twoClassSummary
)


library('rpart')

library('caretEnsemble')

model_list <- caretList(

    Class~., data=training,
  
    trControl=my_control,
  
    methodList=c('gbm', "xgbTree")
)

p <- as.data.frame(predict(model_list, newdata=head(testing)))

print(p)

library('mlbench')

library('randomForest')

library('nnet')

model_list_big <- caretList(

    Class~., data=training,
  
    trControl=my_control,
  
    metric='ROC',
  
    methodList=c('glm', 'xgbTree'),
  
    tuneList=list(
    
      rf1=caretModelSpec(method='gbm'),
    
      rf2=caretModelSpec(method='gbm', preProcess='pca'),
    
      nn=caretModelSpec(method='nnet', tuneLength=2, trace=FALSE)
  )
)

greedy_ensemble <- caretEnsemble(model_list)
summary(greedy_ensemble)


library('caTools')

model_preds <- lapply(model_list, predict, newdata=testing, type='prob')

model_preds <- lapply(model_preds, function(x) x[,'M'])

model_preds <- data.frame(model_preds)

ens_preds <- predict(greedy_ensemble, newdata=testing)

model_preds$ensemble <- ens_preds

colAUC(model_preds, testing$Class)


glm_ensemble <- caretStack(
  
  model_list, 
  
  method='xgbTree',
  
  metric='ROC',
  
  trControl=trainControl(
    method='boot',
    number=10,
    savePredictions=TRUE,
    classProbs=TRUE,
    summaryFunction=twoClassSummary
  )
)
model_preds2 <- model_preds

model_preds2$ensemble <- predict(glm_ensemble, newdata=testing, type='prob')$M

CF <- coef(glm_ensemble$ens_model$finalModel)[-1]

colAUC(model_preds2, testing$Class)


library('xgboost')

xgb_ensemble <- caretStack(
  
  model_list, 
  
  method='xgbTree',
  
  verbose=FALSE,
  
  tuneLength=10,
  
  metric='ROC',
  
  trControl=trainControl(
  
      method='boot',
    
      number=10,
    
      savePredictions=TRUE,
    
      classProbs=TRUE,
    
      summaryFunction=twoClassSummary
  )
)

model_preds3 <- model_preds

model_preds3$ensemble <- predict(xgb_ensemble, newdata=testing, type='prob')$M

colAUC(model_preds3, testing$Class)
