# Read in and format crop by farmsize data for Ethiopia; assign our crop classification as well as FAO codes. 
# Data has been pre-processed by copying and pasting pdf table into a csv, one for each region
# Notes on data:
#  Note:-
#     1. If in some tables figures do not add up to total it is due to rounding
#     2. Those farm management practice designated by “*” in all tables could not be reported because of
#       high coefficient of variation (i.e. they are less reliable). However, they are consolidated in the
#       total estimates.
#     3. In all tables “-” indicates not reported

library(reshape)

#working directory
wd<-'/Users/larissa/Larissa/Earthstat/'
owd<-'/Users/larissa/Larissa/LUGE/Projects/Vinny/2-Formatted'
file.out<-'Ethiopia_crop_by_farmsize_2001.csv'

#Raw data
x <- read.csv(paste0(wd,'Data/Ethiopia/0-Source/ETH_ASR_2001/ETH_ASR_2001_T4_4_T4_22.csv'),fileEncoding='latin1',stringsAsFactors=FALSE)
x <- x[x$Type.of.Crop != '', ]
x.melt <- melt(x, id = c('Type.of.Crop',"NAME_1" ))

OUT<-data.frame(cbind(theme='Landuse',
                      NAME_0='Ethiopia',NAME_1=x.melt$NAME_1,NAME_2=1,NAME_3=1,
                      type='Cropland',
                      subtype="",
                      fs_class_min=ifelse(x.melt$variable == 'Under.0.10' , '<',
                                          ifelse(x.melt$variable == 'X0.1...0.50' , 0.1,
                                                 ifelse(x.melt$variable == 'X0.51...1.00' , 0.51,
                                                        ifelse(x.melt$variable == 'X1.01...2.00' , 1.01,
                                                               ifelse(x.melt$variable == 'X2.01...5.00' , 2.01,
                                                                      ifelse(x.melt$variable == 'X5.01...10' , 5.01,
                                                                             ifelse(x.melt$variable == 'Over.10' , 10,
                                                                                    ifelse(x.melt$variable == 'Number.of.holders.reporting' , NA,
                                                                                           ifelse(x.melt$variable == 'All.Area.in.Hectares' , '',
                                                                                                  'error in farm size classification'))))))))),
                      fs_class_max=ifelse(x.melt$variable == 'Under.0.10' , '0.1',
                                          ifelse(x.melt$variable == 'X0.1...0.50' , 0.5,
                                                 ifelse(x.melt$variable == 'X0.51...1.00' , 1,
                                                        ifelse(x.melt$variable == 'X1.01...2.00' , 2,
                                                               ifelse(x.melt$variable == 'X2.01...5.00' , 5,
                                                                      ifelse(x.melt$variable == 'X5.01...10' , 10,
                                                                             ifelse(x.melt$variable == 'Over.10' , '>',
                                                                                    ifelse(x.melt$variable == 'Number.of.holders.reporting' , NA,
                                                                                           ifelse(x.melt$variable == 'All.Area.in.Hectares' , '',
                                                                                                  'error in farm size classification'))))))))),
                      fs_class_unit='ha',
                      fs_proxy = 0,
                      fs_orig_var = 'Size Of Holdings',
                      subject='Crop area',
                      reporting_unit='Per crop',
                      orig_crop=x.melt$Type.of.Crop,
                      value=as.numeric(as.character(gsub(' ','',x.melt$value))),
                      data_unit='ha',
                      year=2001,
                      source='Annual Agricultural Sample Survey Reports, chapter IV (land utilisation); Table 4.',
                      scode='ETH_ASR_2001',
                      comments=ifelse(x.melt$value == '*',
                                      'Those farm management practice designated by “*” in all tables could not be reported because of
                                high coefficient of variation (i.e. they are less reliable). However, they are consolidated in the
                                      total estimates.',
                                      ifelse(x.melt$value=='-',
                                             'In all tables “-” indicates not reported',
                                             '')),
                      person_entering='Larissa Jarvis',
                      data_entered=as.character(Sys.Date()),
                      orig_var='NUMBER OF HOLDERS AND AREA OF HOLDING BY TYPE OF CROP AND SIZE OF HOLDING',
                      microdata='0',  #Is this microdata 0=no 1=yes
                      weight_corr='0', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='cen'
), stringsAsFactors = FALSE)

OUT$comments<-gsub("[“”]",'',OUT$comments)

#subset out anyting not reported by farm size class, and all groups of crops
OUT<-OUT[!is.na(OUT$fs_class_min) & 
           !OUT$orig_crop %in% c("Total Cropland","Temporary Crops","Grain Crops","Cereals",
                                 "Pulses","Oilseeds","Permanent Crops","Fruit crops","Stimulant crops","Other permanent","Other s"),]


write.csv(OUT,paste(owd,file.out,sep='/'),row.names=FALSE)
