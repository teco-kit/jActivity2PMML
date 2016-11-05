This package illustrates how to deploy our code to create PMML models for sensor data collected via jActivity.

You can run the function getPMML(json_file) by handing over a JSON file containing "sensor", "label" and "classifier" information.

Example:
{"sensor" : ["devicemotion","deviceorientation"], "label" : "('walking', 'standing')", "classifier" : "rpart"}

To install and run the package in OpenCPU, do the following:

# Install in R
{{
library(devtools)
install_github("teco-kit","jActivity2PMML")

opencpu::opencpu$start()
opencpu::opencpu$browse("/library/jActivity2PMML/www/example.html")
}}

# Calling from your own web page to increase fontsize when walking
{{
 	<script src="js/jactivity.js"></script>
	<script src="js/devicemotion.js"></script>

  <script>
	    
	    var activityCallback = function(activity) {
			switch(activity) {
				case "walking": document.body.style.fontSize = "1.2em";	break;
				default:       	document.body.style.fontSize = "1.0em"; break;
			}
		}    
	  
	  new jActivity("../",[devicemotion],activityCallback, ["walking","standing"], 1000);

	</script>
	
}}

you need to adapt the first Argument of jactivity to the root to whereever
{{
opencpu::opencpu$browse("/library/jActivity2PMML/www/")
}}
points to

# Server installation

Refer to https://www.opencpu.org/download.html for installation packages

To train new classifiers will also need the data collection component that is available on https://github.com/teco-kit/jActivity

You will also want to cache the request to the classifier via a reverse proxy for faster runtime