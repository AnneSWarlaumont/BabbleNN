# setwd('/Users/awarlau/IVOC-NN-Learning/DataTables/')
setwd('/chroot/lab/BabbleNN/DataTables/')
variationkey = read.csv('parameterVariationsCSVFiles.csv')

for (variation in 1:nrow(variationkey)){
	
	# Load the data from the 5 simulations of this type
	babblenndata = read.csv(as.character(variationkey$csvfile[variation]))
	
	# Get the first and last 60 seconds average salience for the 5 simulations of this type 50 motor neuron, muscle scaling = 4 simulations
	babblennmin1 = subset(babblenndata,sec<=60&yoke=='false')
	babblennmin120 = subset(babblenndata,sec>(119*60)&sec<=(120*60)&yoke=='false')
	
	print('~~~~~')
	print(paste('Number of motor neurons: ',variationkey$nmot[variation]))
	print(paste('Muscle scaling factor: ',variationkey$muscscale[variation]))
	print(paste('Minute 1 salience: ',mean(babblennmin1$salience)))
	print(paste('Minute 120 salience: ',mean(babblennmin120$salience)))
	print(paste('Minute 120 salience minus Minute 1 salience: ',mean(babblennmin120$salience)-mean(babblennmin1$salience)))
	print(paste('Minute 1 standard deviation across simulations: ',sd(aggregate(babblennmin1$salience, by=list(babblennmin1$simname),FUN=mean)$x)))
	print(paste('Minute 120 standard deviation across simulations: ',sd(aggregate(babblennmin120$salience, by=list(babblennmin120$simname),FUN=mean)$x)))
	print(paste('Minute 1 standard error across simulations: ',sd(aggregate(babblennmin1$salience, by=list(babblennmin1$simname),FUN=mean)$x)/sqrt(5)))
	print(paste('Minute 120 standard error across simulations: ',sd(aggregate(babblennmin120$salience, by=list(babblennmin120$simname),FUN=mean)$x)/sqrt(5)))
	print(paste('T-test for difference in average salience between Minute 1 and Minute 120: '))
	print(t.test(aggregate(babblennmin1$salience, by=list(babblennmin1$simname),FUN=mean)$x,aggregate(babblennmin120$salience, by=list(babblennmin120$simname),FUN=mean)$x,paired=TRUE))
}