library(lme4)
library(lmerTest)
library(ggplot2)
library(plotrix)

# Load the data:
setwd('/Users/awarlau/IVOC-NN-Learning/DataTables/')
babblenndata = read.csv("Extd_params_200motor_2scaling_and_yokes_Moving_threshold_simdata.csv")
babblenndata = subset(babblenndata,sec<=7200)

# Analyze and plot salience as a function of time and yoked status:

babblennlm = lmer(scale(salience) ~ (1|simname) + yoke + scale(sec) + yoke*scale(sec),data=babblenndata)
summary(babblennlm)

qplot(sec,salience,data=babblenndata,geom=c("smooth"),method="gam",formula=y ~ s(x), color=yoke)+ylab("Salience") + xlab("Simulation Time (s)") + scale_color_discrete(name="",breaks=c("false", "true"),labels=c("Salience Reinforced", "Yoked Control")) + coord_cartesian(xlim=c(0,7200)) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
quartz.save("salience_vs_sec_gam.pdf",type="pdf")

# Analyze and plot salience as a function of mean and STD of a second's muscle activity:

activitylm = lm(scale(salience) ~ scale(meanActivity) + scale(STDofActivity),data=babblenndata)
summary(activitylm)

babblenndata_subsample = subset(babblenndata,yoked="false")
babblenndata_subsample = babblenndata_subsample[seq(1,nrow(babblenndata_subsample),by=5),]
salcol = color.scale(babblenndata_subsample$salience,c(0,1,1),c(1,1,0),c(1,0,1))
plot(babblenndata_subsample$meanActivity,babblenndata_subsample$STDofActivity,col=salcol,xlab="Mean Activity",ylab="STD of Activity")
legend("topleft",c(paste("Salience = ",sprintf("%.1f",min(babblenndata_subsample$salience)),sep=""),paste("Salience = ",sprintf("%.1f",max(babblenndata_subsample$salience)),sep="")),pch=c(1,1),col=salcol[c(which.min(babblenndata_subsample$salience),which.max(babblenndata_subsample$salience))])
quartz.save("salience_vs_meanandstd.pdf",type="pdf")

# Analyze and plot mean muscle activity as a function of time and yoked status:

meanActivitylm = lmer(scale(meanActivity) ~ (1|simname) + yoke + scale(sec) + yoke*scale(sec),data=babblenndata)
summary(meanActivitylm)

qplot(sec,meanActivity,data=babblenndata,geom=c("smooth"),method="gam",formula=y ~ s(x), color=yoke)+ylab("Mean Activity") + xlab("Simulation Time (s)") + scale_color_discrete(name="",breaks=c("false", "true"),labels=c("Salience Reinforced", "Yoked Control")) + coord_cartesian(xlim=c(0,7200)) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
quartz.save("meanActivity_vs_sec_gam.pdf",type="pdf")

# Analyze and plot STD of a second's muscle activity as a function of time and yoked status:

STDofActivitylm = lmer(scale(STDofActivity) ~ (1|simname) + yoke + scale(sec) + yoke*scale(sec),data=babblenndata)
summary(STDofActivitylm)

qplot(sec,STDofActivity,data=babblenndata,geom=c("smooth"),method="gam",formula=y ~ s(x), color=yoke) + ylab("STD of Activity") + xlab("Simulation Time (s)") + scale_color_discrete(name="",breaks=c("false", "true"),labels=c("Salience Reinforced", "Yoked Control")) + coord_cartesian(xlim=c(0,7200)) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(), axis.line = element_line(colour = "black"))
quartz.save("STDofActivity_vs_sec_gam.pdf",type="pdf")
