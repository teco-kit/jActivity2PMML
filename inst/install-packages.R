 ## Create the personal library if it doesn't exist. Ignore a warning if the directory already exists.
dir.create(Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)
install.packages("RMySQL") # to establish a connection and query sensor data from the database
install.packages("foreach") # to apply for each
install.packages("plyr") # to join data from different sensors
install.packages("pmml") # to create PMML from model
install.packages("XML") #to store PMML in XML structure
install.packages("rpart") # classifier: rpart
install.packages("randomForest") # classifier: randomforest
install.packages("e1071") # classifier: naiveBayes, SVM etc.
