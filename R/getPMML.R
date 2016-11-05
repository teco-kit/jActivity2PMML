getSensorsSQL <- function(sensors, classes, host='jactivity', port=3306, dbname='jactivity2')
{
  library(RMySQL)
  # establish a connection to the database
  mydb = dbConnect(MySQL(), user='admin', password='admin', dbname=dbname, host=host, port=port )
  #for bug fixing or testing issues use port 3307 and your own host

    
  predictionClassDB = paste("(", 
                            paste('"',classes,'"',collapse=',',sep=''),
                            ")",sep="")
  ids=c("id","timestamp","useragent","label")
  # join/merge sensors into one dataframe on ids
  joinhelper<-function(x,y) {plyr::join(x, y, by = ids, type = "full", match = "first")}
  
  
  library(foreach)
  res=foreach(s=sensors,.combine="joinhelper")%do%
  {
    query = paste("select * from ",s," where label in ",predictionClassDB,sep="")
    
    v<-dbGetQuery(mydb, query)
    
    # if we want to make them unique and expose the sensor names: names(v)[0:-4]<- gsub("^", paste(s,".",sep="") , names(v)[0:-4])
    
    v
    
  }
  
  # remove ids
  res <-subset(res,select=-c(timestamp,id,useragent))
  
  # label to factor  
  res$label <- as.factor(tolower(res$label))
  
  # the rest to numeric
  res[,-grep("label", colnames(res))] <- sapply(res[,-grep("label", colnames(res))], as.numeric)
 
  dbDisconnect(mydb) 
  return(res)
}

getModel <- function(classifier,sensorvalues)
{
  fit <- switch(classifier,
     rpart=rpart::rpart(label ~ ., data=sensorvalues,maxsurrogate=0) # no surrogates as it is easier to be handled, esp. if we want to reuse the code for randomForests
    ,randomForest=randomForest::randomForest(label ~ ., data=sensorvalues,na.action=randomForest::na.roughfix)
    ,naiveBayes=e1071::naiveBayes(label ~ ., data=sensorvalues)
    ,warning("classifier not supported yet")
    )
}

getPMML <- function(json_data=jsonlite::fromJSON('{"sensor": ["devicemotion","touchevents"],"label": ["walking", "standing"],"classifier": "rpart"}')){
  
  #get sensordata from server for labels
  sensorvalues <- getSensorsSQL(json_data$sensor, json_data$label)
  

  #learn model
  fit=getModel(json_data$classifier, sensorvalues)
 
  invisible(XML::saveXML(pmml::pmml(fit)))
}