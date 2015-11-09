library(gplots)
library(ggplot2)

setwd('/Users/awarlau/IVOC-NN-Learning/DataTables/')
soutdata = read.csv('sout_ratios_sds.csv')

t.test(soutdata$real_sout_ratios, soutdata$yoke_sout_ratios, paired = TRUE)
t.test(soutdata$real_sout_sds, soutdata$yoke_sout_sds, paired = TRUE)

real_ratios_mean_ci = mean_se(soutdata$real_sout_ratios,mult=1.96)
yoke_ratios_mean_ci = mean_se(soutdata$yoke_sout_ratios,mult=1.96)
real_sds_mean_ci = mean_se(soutdata$real_sout_sds,mult=1.96)
yoke_sds_mean_ci = mean_se(soutdata$yoke_sout_sds,mult=1.96)

# Match the colors to those used in ggplot
gg_color_hue <- function(n) {
  hues = seq(15, 375, length=n+1)
  hcl(h=hues, l=65, c=100)[1:n]
}
cols = gg_color_hue(2)

barplot2(height = c(real_ratios_mean_ci$y,yoke_ratios_mean_ci$y), names.arg = c('Salience Reinforced', 'Yoked control'), col = cols, ylab = 'Presynaptic Agonist Connections / Presynaptic Antagonist Connections', beside = T, plot.ci = T, ci.l = c(real_ratios_mean_ci$ymin,yoke_ratios_mean_ci$ymin), ci.u = c(real_ratios_mean_ci$ymax,yoke_ratios_mean_ci$ymax), ylim = c(0, 1.5))
quartz.save("sout_ratio_barplot.pdf",type="pdf")

barplot2(height = c(real_sds_mean_ci$y,yoke_sds_mean_ci$y), names.arg = c('Salience Reinforced', 'Yoked control'), col = cols, ylab = 'Standard Deviation of Reservoir to Motor Synapse Strengths', beside = T, plot.ci = T, ci.l = c(real_sds_mean_ci$ymin,yoke_sds_mean_ci$ymin), ci.u = c(real_sds_mean_ci$ymax,yoke_sds_mean_ci$ymax), ylim = c(0, .8))
quartz.save("sout_sd_barplot.pdf",type="pdf")
