getPMML <- function(json_data){

  ########################
  # DEAL WITH JSON INPUT #
  ########################
  
  sensorNames = json_data$sensor
  
  predictionClass = json_data$label
  
  classifier = json_data$classifier
  
  
  ###################
  ### GET SENSORS ###
  ###################

  library(RMySQL)
    
  # establish a connection to the database
  mydb = dbConnect(MySQL(), user='admin', password='admin', dbname='jactivity2', host='mysql', port=3306)

  ifelse(length(predictionClass)>1,{
	  predictionClassDB = paste("(",'"',predictionClass[1],'"',sep="")
	  for(i in 2:length(predictionClass)) 
	  {
		  predictionClassDB = paste(predictionClassDB,", ",'"',predictionClass[i],'"',sep="")
	  }  
	  predictionClassDB = paste(predictionClassDB,")",sep="")
  },{
	  predictionClassDB = paste("(",'"',predictionClass,'"',")",sep="")
  })
  
  
  # if we want to get sensor data dynamically 
  library(foreach)
  ifelse(grepl("other",predictionClass),{ 
    # if "other" in predictionClass then get everything to define later on that other is the rest
    foreach(s=sensorNames)%do%
    {
      query = paste("select * from ",s," where label in ",predictionClassDB,sep="")
      print(query)
      assign(s, dbGetQuery(mydb, query))
    }
  },{
    # if only true labels are in predictionClass then only get the prediction class data
    foreach(s=sensorNames)%do%
    {
      query = paste("select * from ",s," where label in ",predictionClassDB,sep="")
      print(query)
      assign(s, dbGetQuery(mydb, query))
    }
  }
  )

  dbDisconnect(mydb) 
  
  # join/merge sensors into one dataframe
  library(plyr)
  sensorvalues=join(x=devicemotion, y=deviceorientation, by = c("timestamp","useragent","label"), type = "full", match = "first")
  ## TODO: make it dynamic
    
  ################################
  ### CLASSIFY and CREATE PMML ###
  ################################
  
  library(pmml)
  library(XML)
  # https://cran.r-project.org/web/packages/pmml/pmml.pdf
  # note: package pmml, version 1.5.0. License: GPL (>= 2.1)
  
  library(rpart) #rpart
  library(randomForest) # randomForest
  library(e1071) #naiveBayes,SVM

  
  ### data preprocessing to correct type (factor, numeric) ###
  
  sensorvalues <- subset(sensorvalues, select=-c(grep("timestamp", colnames(sensorvalues)),grep("id", colnames(sensorvalues))))
  sensorvalues$useragent <- as.factor(sensorvalues$useragent)
  sensorvalues$label <- as.factor(sensorvalues$label)
  sensorvalues[,-c(grep("useragent", colnames(sensorvalues)),grep("label", colnames(sensorvalues)))] <- sapply(sensorvalues[, -c(grep("useragent", colnames(sensorvalues)),grep("label", colnames(sensorvalues)))], as.numeric)
  
  switch(classifier,
         rpart = {
           print("rpart")
           fit <- rpart(label ~ ., data=sensorvalues,maxsurrogate=0) # no surrogates as it is easier to be handled, esp. if we want to reuse the code for randomForests
           return(saveXML(pmml(fit)))
         },
         randomForest = {
           print("randomForest")
           fit <- randomForest(label ~ ., data=sensorvalues)
           return(saveXML(pmml(fit)))
         },
         naiveBayes = {
           print("naiveBayes")
           fit <- naiveBayes(label ~ ., data=sensorvalues)
           return(saveXML(pmml(fit,dataset=sensorvalues,predictedField="Class")))
         }
  )
  
}