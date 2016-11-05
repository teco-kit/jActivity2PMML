class jActivity {
	constructor(base, sensors, callback, label, interval) {
		this.sensors = sensors
		this.callback = callback
		this.label = label
		this.interval = interval
		this.base = base

		this.dataset = {}

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
				window.setInterval((...args) => 
					 function() {
						 // calculate features
						 // TODO: currently only average!!!
						 let averageData = {}

						 for (var feature in this.dataset) {

							 averageData[feature] = this.dataset[feature].reduce(function(a, b) { return a + b }, 0) / this.dataset[feature].length
							 this.dataset[feature] = [] //clear this
						 }

						 this.callback(this.classifier.evaluate(averageData))
					 }
					 , interval)
			}
		)
	}
}
