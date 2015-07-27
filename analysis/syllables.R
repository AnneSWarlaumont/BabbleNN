# Load the data from each of the 5 simulations and paste them together
datadir = '/chroot/lab/BabbleNN/Extended_Neuron_and_Scaling_Tests/SyllableData/'
sylldata = read.csv(paste(datadir,'NandScExtended_2_1_1_syllables.csv',sep=""))
sylldata = rbind(sylldata,read.csv(paste(datadir,'NandScExtended_2_1_2_syllables.csv',sep="")))
sylldata = rbind(sylldata,read.csv(paste(datadir,'NandScExtended_2_1_3_syllables.csv',sep="")))
sylldata = rbind(sylldata,read.csv(paste(datadir,'NandScExtended_2_1_4_syllables.csv',sep="")))
sylldata = rbind(sylldata,read.csv(paste(datadir,'NandScExtended_2_1_5_syllables.csv',sep="")))

# Add a column that indicates whether the simulation is yoked
sylldata$yoked = NA
sylldata$simname = NA
for (rownum in 1:nrow(sylldata)) {
	if (length(grep("yoke",sylldata[rownum,]$soundname)) > 0) {
		sylldata[rownum,]$yoked = "true"
	} else {
		sylldata[rownum,]$yoked = "false"
	}
	sylldata[rownum,]$simname = gsub("_[0-9]*$","",sylldata[rownum,]$soundname)
}

# Add a column that indicates the second
sylldata$sec = NA
for (rownum in 1:nrow(sylldata)) {
	sylldata[rownum,]$sec = as.numeric(gsub(".*_","",sylldata[rownum,]$soundname))
}

# Write the combined data to file
write.csv(sylldata,file="sylldata_200_2.csv")
