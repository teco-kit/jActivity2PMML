This package illustrates how to deploy our code to create PMML models for sensor data collected via jActivity.
You can run the function getPMML(json_file) by handing over a JSON file containing "sensor", "label" and "classifier" information.

Example:
{"sensor" : ["devicemotion","deviceorientation"], "label" : "('walking', 'standing')", "classifier" : "rpart"}

To install and run the package in OpenCPU, do the following:

# Install in R
library(devtools)
install_github("jActivity2PMML")

#Load the app
library(opencpu)
opencpu$browse("/library/jActivity2PMML/www")