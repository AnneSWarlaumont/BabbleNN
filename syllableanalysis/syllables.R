setwd('/chroot/lab/BabbleNN/Neuron_and_MuscleScaling_Tests/SyllableData/')
sylldata = read.csv('NandScTesting_2_1_1_syllables.csv')
sylldata = rbind(sylldata,read.csv('NandScTesting_2_1_2_syllables.csv'))
sylldata = rbind(sylldata,read.csv('NandScTesting_2_1_3_syllables.csv'))
sylldata = rbind(sylldata,read.csv('NandScTesting_2_1_4_syllables.csv'))
sylldata = rbind(sylldata,read.csv('NandScTesting_2_1_5_syllables.csv'))

# Add a column that indicates whether the simulation is yoked
sylldata$yoked = NA
sylldata$simname = NA
for (rownum in 1:nrow(sylldata)) {
	if (length(grep("yoke",sylldata[rownum,]$soundname)) > 0) {
		sylldata[rownum,]$yoked = "True"
	} else {
		sylldata[rownum,]$yoked = "False"
	}
	sylldata[rownum,]$simname = gsub("_[0-9]*$","",sylldata[rownum,]$soundname)
}

# Add a column that indicates the second
sylldata$sec = NA
for (rownum in 1:nrow(sylldata)) {
	sylldata[rownum,]$sec = as.numeric(gsub(".*_","",sylldata[rownum,]$soundname))
}

write.csv(sylldata,file="sylldata.csv")

library(lmer)
library(lmerTest)
library(ggplot2)

sylllm = lmer(scale(nsyll) ~ (1|simnum) yoked + scale(sec) + yoked*scale(sec),data = sylldata)
summary(sylllm)

qplot(sec,nsyll,data=sylldata,geom=c("smooth"),method="lm",formula=y~x,color=yoked)+ylab("number of syllables") + xlab("seconds")
quartz.save("nsyll_vs_sec.pdf",type="pdf")
	