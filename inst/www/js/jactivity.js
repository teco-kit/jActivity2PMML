class jActivity {
	constructor(base, sensorClasses, callback, label, interval) {
		this.callback = callback
		this.label = label
		this.interval = interval
		this.base = base

		var dataset = {}
		this.dataset = dataset; 

		var sensors = []
		this.sensors = sensors; 


		sensorClasses.forEach(function (sensorClass)
		{
			var sensor= new sensorClass(dataset);
			sensors.push(sensorClass.name)
		}
		)
		

		// get stylesheet for transformation 
		// TODO: could store this globally to not trigger recompilation 
		var pmml2js = new Promise((resolve, reject) => {
			var onSuccess = function(xsl_file) {
				resolve( function(model){	
					let generated_code = transform(model,xsl_file)
					return eval(generated_code.textContent);
				}
				)
			}
			$.ajax({
				type: "GET",
				url: (this.base + "www/js/pmml2js.xsl"),
				success: onSuccess
			})
		})

		// get PMML 
		var pmml = new Promise((resolve,reject) => {

			var onSuccess = function(data) {
				resolve($.parseXML(data.pop()))
			}

			$.ajax({
				type: "POST",
				url: (this.base + "R/getPMML/json"),
				data: 'json_data={"sensor": ' + JSON.stringify(this.sensors) + ',"label": ' + JSON.stringify(this.label) + ',"classifier": "rpart"}',
				success: onSuccess,
				dataType: "json"
			})
		}
		)

		// once we have both we generate the classifier and register the callback
		Promise.all([pmml2js,pmml]).then( p => 
			{ 
				this.classifier = p[0](p[1]) //generate and store classifiier 
				// then call by interval assuming someone fills the dataset
				window.setInterval(
					function(scope) {
						 // calculate features
						 // TODO: currently only average!!!
						 let averageData = {}

						 for (var feature in scope.dataset) {

							 averageData[feature] = scope.dataset[feature].reduce(function(a, b) { return a + b }, 0) / scope.dataset[feature].length
							 scope.dataset[feature] = [] //clear this
						 }

						 scope.callback(scope.classifier.evaluate(averageData))
					 }
					 , interval,this)
			}
		)
	}
}
