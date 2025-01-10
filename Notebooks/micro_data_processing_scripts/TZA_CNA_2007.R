#Colombia 2014 census. SPSS files
library('reshape2')
library('foreign')
library('dplyr')
library('plyr')

wd<-'/Volumes/LARA/Original'
wd<-'/Users/larissa/Larissa/Earthstat/Data/Tanzania/0-Source'

owd<-'/Users/larissa/LUGE/Projects/Vinny/2-Formatted'

Scode<-"TZA_CNA_2007"

file1a<-'ACQ1-Small Scale Farmers/R041.sav'
file1b<-'ACQ1-Small Scale Farmers/R051.sav'
file1c<-'ACQ1-Small Scale Farmers/R052.sav'
file1d<-'ACQ1-Small Scale Farmers/R053.sav' #permanent crops

file2a<-'ACQ2-Large Scale Farms/R031.sav'
file2b<-'ACQ2-Large Scale Farms/R041.sav'
file2c<-'ACQ2-Large Scale Farms/R422.sav'
file2d<-'ACQ2-Large Scale Farms/R043.sav' #permanent crops

file.out<-'Tanzania_cropsByFarmsize_2007.csv'

#Variables:

#Small farms

#In R041.sav
#/REGION
#/DISTRICT
#/WARD
#/VILLAGE
#/HHNUMBER
#/Q041_C2 'Area in Acres' (this refers to 'land access', which from the questionnaire indicates land owned. Next module is 'land use')

#In R051.sav
#/Q0511C2  "Crop Code"
#/Q0511C3  "Actual Planted Area (acres)"
#/Q0511C28 "Quantity Harvested (kgs)"

#In R052.sav
#/Q0521C2  "Crop Code"
#/Q0521C3  "Actual Planted Area (acres)"
#/Q0521C28 "Quantity Harvested (kgs)"

#In R053.sav
#/Q0531C2  "Crop Code"
#/Q0531C29  "Area harvested (acres)"
#/Q0531C31 "Quantity Harvested (kgs)"

#Large farms
#In R031.sav
#/ID_FMER Farm serial number
#/Q031_C2 'Area in Hectares'

#In R041.sav
#/ID_FMER Farm serial number
#/Q411_C1 "Crop code"
#/Q411_C4 "Area harvested"
#/Q411-C6 "Amount harvested" 

#In R043.sav
#/ID_FMER Farm serial number
#/Q431_C1 "Crop code"
#/Q431_C4 "Area (ha) of mature plants/trees/bushes in MONO CROP"
#/Q431_C7 "Amount harvested" 

#In R4221.sav
#/IF_FMER Farm serial number
#/Q422_C1 "Crop code"
#/Q422_C4 "Area harvested"
#/Q422-C6 "Amount harvested" 

#lookups
crop.id<-read.csv(paste(wd,Scode,'crop_ids.csv',sep='/'))
#These names/codes were extracted from echnical_And_Operation_Report.pdf using Tabula

admin.id<-read.csv(paste(wd,Scode,'tabula-admin.csv',sep='/'),stringsAsFactors = FALSE)

#wca farm size classes (for our own classification)
wca.classes <- c(0,1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, NA)
xi<-cbind.data.frame(fs_class_min=wca.classes[-12],
                     fs_class_max=wca.classes[-1],
                     class=letters[1:11],
                     stringsAsFactors=FALSE)

smFS<-read.spss(paste(wd,Scode,file1a,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
smCR1<-read.spss(paste(wd,Scode,file1b,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
smCR2<-read.spss(paste(wd,Scode,file1c,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
smCR3<-read.spss(paste(wd,Scode,file1d,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
lrFS<-read.spss(paste(wd,Scode,file2a,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
lrCR1<-read.spss(paste(wd,Scode,file2b,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
lrCR2<-read.spss(paste(wd,Scode,file2c,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)
lrCR3<-read.spss(paste(wd,Scode,file2d,sep='/'),to.data.frame=TRUE,use.value.labels = FALSE)

#Aggregate smFS by all types of land in access (owned, borrowred, rented, shared)
smFS.agg<-aggregate(Q041C2~REC.TYPE+REGION+DISTRICT+WARD+VILLAGE+HHNUMBER+VillageID+Dist_ID+Wt_adjust,sum,data=smFS)
#convert land in access (land owned) from acres to ha
smFS.agg$Q041C2 <- smFS.agg$Q041C2*0.404686

#Merge farm area data to crop data
sm1<-merge(smFS.agg,smCR1,by=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER"))
sm2<-merge(smFS.agg,smCR2,by=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER"))
sm3<-merge(smFS.agg,smCR3,by=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER"))

#Correct for weights
sm1$Q0511C3_corr<-sm1$Q0511C3*sm1$Wt_adjust.x
sm1$Q0511C28_corr<-sm1$Q0511C28*sm1$Wt_adjust.x

sm2$Q0521C3_corr<-sm2$Q0521C3*sm2$Wt_adjust.x
sm2$Q0521C28_corr<-sm2$Q0521C28*sm2$Wt_adjust.x

sm3$Q0531C29_corr<-sm3$Q0531C29*sm3$Wt_adjust.x
sm3$Q0531C31_corr<-sm3$Q0531C31*sm3$Wt_adjust.x


#Transform variables of interest to long form
sm.melt1<-melt(sm1[,c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2",'Q0511C2','Q0511C3_corr','Q0511C28_corr')], id=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2","Q0511C2"))
sm.melt2<-melt(sm2[,c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2",'Q0521C2','Q0521C3_corr','Q0521C28_corr')], id=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2","Q0521C2"))
sm.melt3<-melt(sm3[,c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2",'Q0531C2','Q0531C29_corr','Q0531C31_corr')], id=c("REGION","DISTRICT","WARD","VILLAGE","HHNUMBER","Q041C2","Q0531C2"))

#Asssign crop name from crop.id lookup
sm.melt1$Orig_crop<-crop.id$Q0511C2_name[match(sm.melt1$Q0511C2,crop.id$Q0511C2_id)]
sm.melt2$Orig_crop<-crop.id$Q0521C2_name[match(sm.melt2$Q0521C2,crop.id$Q0521C2_id)]
sm.melt3$Orig_crop<-crop.id$Q0531C2_name[match(sm.melt3$Q0531C2,crop.id$Q0531C2_id)]

#Combine data from both tables
names(sm.melt1)[names(sm.melt1)=='Q0511C2']<-"Q0521C2"
names(sm.melt3)[names(sm.melt3)=='Q0531C2']<-"Q0521C2"
sm.melt<-rbind.fill(sm.melt1,sm.melt2, sm.melt3)

#Large farms
#Aggregate lrFS by all types of land in access (owned, borrowed, rented, shared)
lrFS.agg<-aggregate(Q031_C2~ID_FMER+REGION+Q021,sum,data=lrFS)
#Merge farm area data to crop data
lr1<-merge(lrCR1,lrFS.agg,by=c('ID_FMER','REGION'))
lr2<-merge(lrCR2,lrFS.agg,by=c('ID_FMER','REGION'))
lrFS.agg$ID_FMER<-as.numeric(as.character(lrFS.agg$ID_FMER))

lr3<-merge(lrCR3,lrFS.agg,by=c('ID_FMER','REGION'))

#Transform variables of interest to long form
lr.melt1<-melt(lr1[,c("ID_FMER","REGION","Q031_C2","Q411_C1","Q411_C4","Q411_C6")], id=c("ID_FMER","REGION","Q031_C2","Q411_C1"),variable.factor=FALSE)
lr.melt2<-melt(lr2[,c("ID_FMER","REGION","Q031_C2","Q422_C1","Q422_C4","Q422_C6")], id=c("ID_FMER","REGION","Q031_C2","Q422_C1"))
lr.melt3<-melt(lr3[,c("ID_FMER","REGION","Q031_C2","Q431_C1","Q431_C4","Q431_C7")], id=c("ID_FMER","REGION","Q031_C2","Q431_C1"))

#Asssign crop name from crop.id lookup
lr.melt1$Orig_crop<-crop.id$Q411_C1_name[match(lr.melt1$Q411_C1,crop.id$Q411_C1_id)]
lr.melt2$Orig_crop<-crop.id$Q422_C1_name[match(lr.melt2$Q422_C1,crop.id$Q422_C1_id)]
lr.melt3$Orig_crop<-crop.id$Q431_C1_name[match(lr.melt3$Q431_C1,crop.id$Q431_C1_id)]

#Combine data from both tables
lr.melt<-rbind.fill(lr.melt1,lr.melt2,lr.melt3)

#add farm size classes
#add farm size class to each farm
sm.melt$wca <- ifelse(sm.melt$Q041C2 > 0 & sm.melt$Q041C2 < 1, 'a',
                       ifelse(sm.melt$Q041C2 >= 1  & sm.melt$Q041C2 < 2, 'b',
                              ifelse(sm.melt$Q041C2 >= 2 & sm.melt$Q041C2 < 5, 'b',
                                     ifelse(sm.melt$Q041C2 >=  5 & sm.melt$Q041C2 < 10, 'd',
                                            ifelse(sm.melt$Q041C2 >=  10 & sm.melt$Q041C2 < 20, 'e',
                                                   ifelse(sm.melt$Q041C2 >=  20 & sm.melt$Q041C2 < 50, 'f',
                                                          ifelse(sm.melt$Q041C2 >=  50 & sm.melt$Q041C2 < 100, 'g',
                                                                 ifelse(sm.melt$Q041C2 >=  100 & sm.melt$Q041C2 < 200, 'h',
                                                                        ifelse(sm.melt$Q041C2 >=  200 & sm.melt$Q041C2 < 500, 'i',
                                                                               ifelse(sm.melt$Q041C2 >=  500 & sm.melt$Q041C2 < 1000, 'j',
                                                                                      ifelse(sm.melt$Q041C2 >=  1000,'k',
                                                                                             NA)))))))))))


lr.melt$wca <- ifelse(lr.melt$Q031_C2 > 0 & lr.melt$Q031_C2 < 1, 'a',
                       ifelse(lr.melt$Q031_C2 >= 1  & lr.melt$Q031_C2 < 2, 'b',
                              ifelse(lr.melt$Q031_C2 >= 2 & lr.melt$Q031_C2 < 5, 'b',
                                     ifelse(lr.melt$Q031_C2 >=  5 & lr.melt$Q031_C2 < 10, 'd',
                                            ifelse(lr.melt$Q031_C2 >=  10 & lr.melt$Q031_C2 < 20, 'e',
                                                   ifelse(lr.melt$Q031_C2 >=  20 & lr.melt$Q031_C2 < 50, 'f',
                                                          ifelse(lr.melt$Q031_C2 >=  50 & lr.melt$Q031_C2 < 100, 'g',
                                                                 ifelse(lr.melt$Q031_C2 >=  100 & lr.melt$Q031_C2 < 200, 'h',
                                                                        ifelse(lr.melt$Q031_C2 >=  200 & lr.melt$Q031_C2 < 500, 'i',
                                                                               ifelse(lr.melt$Q031_C2 >=  500 & lr.melt$Q031_C2 < 1000, 'j',
                                                                                      ifelse(lr.melt$Q031_C2 >=  1000,'k',
                                                                                             NA)))))))))))



#aggregate everything to region level (large farms are only reported by region)
x<-aggregate(value~REGION+wca+Orig_crop+variable+value,sum,data=sm.melt[,!names(sm.melt)%in% c("Q0521C2","Q0511C2","Q0531C2")])
out.sm<-data.frame(cbind.data.frame(Theme='Landuse',
                      NAME_0='Tanzania',
                      NAME_1=admin.id$Region.Name[match(as.numeric(as.character(x$REGION)),admin.id$Region.Code)],
                      NAME_2=1,
                      NAME_3=1,
                      type='Cropland',
                      subtype="",
                      fs_class_min=xi$fs_class_min[match(x$wca,xi$class)], #converting to HA for assigning farm size classes
                      fs_class_max=xi$fs_class_max[match(x$wca,xi$class)],
                      fs_class_unit='ha',
                      fs_proxy='0', #Is it a proxy for farm size (ie: summed crop area, summed harvested area... 0=no,1=yes
                      fs_orig_var='land access (land owned)',
                      subject=ifelse(x$variable == "Q0521C3_corr" | x$variable == "Q0511C3_corr","Planted area",
                                     ifelse(x$variable == "Q0521C28_corr" | x$variable == "Q0511C28_corr" | x$variable == "Q0531C31_corr","Production",
                                            ifelse(x$variable == "Q0531C29_corr", 'Harvested area',NA))),
                      reporting_unit='Per crop',
                      orig_crop=x$Orig_crop, 
                      orig_group='',
                      value=as.numeric(x$value),
                      data_unit=ifelse(x$variable=="Q0521C3_corr" | x$variable=="Q0511C3_corr","acres",
                                       ifelse(x$variable=="Q0521C28_corr" | x$variable=="Q0511C28_corr" | x$variable == "Q0531C31_corr" ,"kgs",
                                              ifelse(x$variable == "Q0531C29_corr", 'acres',NA))),
                      year=2007,
                      source='Agriculture Sample Census Survey 2007/08',
                      scode='TZA_CNA_2007',
                      comments='',
                      person_entering='Larissa Jarvis',
                      data_entered='2017-05-16',
                      orig_var=ifelse(x$variable=="Q0521C3_corr" | x$variable=="Q0511C3_corr","Actual Planted Area (acres)",
                                      ifelse(x$variable=="Q0521C28_corr" | x$variable=="Q0511C28_corr" | x$variable == "Q0531C31_corr","Quantity Harvested (kgs)",
                                             ifelse(x$variable == "Q0531C29_corr", "Area harvested (acres)",NA))),
                      microdata='1',  #Is this microdata 0=no 1=yes
                      weight_corr='1', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='sur' 
), stringsAsFactors = FALSE) 


x<-aggregate(value~REGION+wca+Orig_crop+variable,sum,data=lr.melt[,!names(lr.melt)%in%c("Q411_C1","Q422_C1","Q431_C1")])
out.lr<-data.frame(cbind.data.frame(Theme='Landuse',
                      NAME_0='Tanzania',
                      NAME_1=admin.id$Region.Name[match(as.numeric(as.character(x$REGION)),admin.id$Region.Code)],
                      NAME_2=1,
                      NAME_3=1,
                      type='Cropland',
                      subtype="",
                      fs_class_min=xi$fs_class_min[match(x$wca,xi$class)], #converting to HA for assigning farm size classes
                      fs_class_max=xi$fs_class_max[match(x$wca,xi$class)],
                      fs_class_unit='ha',
                      fs_proxy='0', #Is it a proxy for farm size (ie: summed crop area, summed harvested area... 0=no,1=yes
                      fs_orig_var='Area in Hectares',
                      subject=ifelse(x$variable=="Q411_C4" | x$variable=="Q422_C4","Harvested area",
                                     ifelse(x$variable=="Q411_C6" | x$variable=="Q422_C6" | x$variable=="Q431_C7","Production",
                                            ifelse(x$variable=="Q431_C4","Crop area",NA))),
                      reporting_unit='Per crop',
                      orig_crop=x$Orig_crop, 
                      orig_group='',
                      value=as.numeric(x$value),
                      data_unit=ifelse(x$variable=="Q411_C4" | x$variable=="Q422_C4","ha",
                                       ifelse(x$variable=="Q411_C6" | x$variable=="Q422_C6" | x$variable=="Q431_C7","t",
                                              ifelse(x$variable=="Q431_C4","ha",NA))),
                      year=2007,
                      source='Agriculture Sample Census Survey 2007/08',
                      scode='TZA_CNA_2007',
                      comments='',
                      person_entering='Larissa Jarvis',
                      data_entered='2017-05-16',
                      orig_var=ifelse(x$variable=="Q411_C4" | x$variable=="Q422_C4","Area harvested",
                                      ifelse(x$variable=="Q411_C6" | x$variable=="Q422_C6" | x$variable=="Q431_C7","Amount harvested",
                                             ifelse(x$variable=="Q431_C4","Area (ha) of mature plants/trees/bushes in MONO CROP",NA))),
                      microdata='1',  #Is this microdata 0=no 1=yes
                      weight_corr='1', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='sur' 
), stringsAsFactors = FALSE) 

#Check values:
#Final reports crops report  (small holder): (for Maize) 4086555 planted ha and 5,444,178 tonnes). Microdata units are acre and kg 
aggregate(value~subject+data_unit,sum,data=out.sm[out.sm$orig_crop=='Maize',])
#Large scale report gives (for Maize): 22043 harvested ha and 344,134 t
aggregate(value~subject+data_unit,sum,data=out.lr[out.lr$orig_crop=='Maize',])

#FAO reports total maize harvested area for 2007 as 2600341 ha and production as 3659000 t

sum(out.sm$value)

out<-rbind.data.frame(out.sm,out.lr)

# #Exclude crops that don't contribute to the top 90% of planted area:
# out.agg<-aggregate(Value~NAME_0+Orig_crop,sum,data=out[out$Subject %in% c('Planted area','Harvested area','Crop area'),])
# 
# #calculate percent of total area
# out.agg$per<-out.agg$Value/sum(out.agg$Value,na.rm=TRUE)
# #calculate cummulative percent
# out.agg$cumper[rev(order(rank(out.agg$Value)))]<-cumsum(out.agg$per[rev(order(rank(out.agg$Value)))])
# 
# #These crops make up the top 90% of area
# out.90<-out[out$Orig_crop %in% out.agg$Orig_crop[out.agg$cumper>=.1],]
# exc.crop<-out.agg$Orig_crop[out.agg$cumper<.1]

write.csv(out,paste(owd,file.out,sep='/'),row.names=FALSE)
