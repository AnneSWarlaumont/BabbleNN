library(lme4)
library(lmerTest)
library(ggplot2)

# Load data
setwd('/Users/awarlau/IVOC-NN-Learning/SyllableData/')
sylldata = read.csv("sylldata_200_2.csv")
sylldata = subset(sylldata,sec<=7200)

# Analyze and plot number of syllables as a function of simulation time and yoked status

sylllm = lmer(scale(nsyll) ~ (1|simname) + yoked + scale(sec) + yoked*scale(sec),data = sylldata)
summary(sylllm)

qplot(sec,nsyll,data=sylldata,geom=c("smooth"),method="gam",formula=y ~ s(x), color=yoked)+ylab("Number of Syllables") + xlab("Simulation Time (s)") + scale_color_discrete(name="",breaks=c("false", "true"),labels=c("Salience Reinforced", "Yoked Control")) + coord_cartesian(xlim=c(0,7200)) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
quartz.save("nsyll_vs_sec_gam.pdf",type="pdf")

