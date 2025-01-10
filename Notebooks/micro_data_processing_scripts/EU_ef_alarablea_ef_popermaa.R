#### Read in and format Eurostat data on crops by farm size ####
library(reshape2)
library(plyr)
library(memisc)


eustat<-'Data/EuroStat/Rawdata/'

#http://ec.europa.eu/eurostat/web/agriculture/agricultural-production
#Notes:
#This is area of crops by size of 'Utilized Agricultural Area' of farms (closest we get to farm size for Europe)
#UAA= total area taken up by arable land, permanent pasture and meadow, land used for permanent crops and kitchen gardens.

#raw data
xa<-read.table(paste(wd,eustat,'ef_alarableaa.tsv',sep=''),header=TRUE,stringsAsFactors=FALSE)
xp<-read.table(paste(wd,eustat,'ef_popermaa.tsv',sep=''),sep='\t',header=TRUE,stringsAsFactors=FALSE)
#dictionaries
agrarea<-read.table(paste(wd,eustat,'agrarea.dic',sep=''),sep='\t',stringsAsFactors=FALSE)
arable<-read.table(paste(wd,eustat,'arable.dic',sep=''),sep='\t',stringsAsFactors=FALSE)
indic_ef<-read.table(paste(wd,eustat,'indic_ef.dic',sep=''),sep='\t',stringsAsFactors=FALSE)
croparea<-read.table(paste(wd,eustat,'croparea.dic',sep=''),sep='\t',stringsAsFactors=FALSE)

euSubj<-c('hold','ha')
subject<-c('Number of farms','Area')

#Lookups to convert Eurostat units to Earthstat
euRange<-c("HA0",     "HA10-19", "HA2-4",   "HA20-29", "HA30-49", "HA5-9",   "HA50-99", "HA_GE100","HA_LT2",  "TOTAL")
Range_min<-c(0,10,2,20,30,5,50,100,'0','')
Range_max<-c(0,19,4,29,49,9,99,'',2,'')

xa<-melt(xa,id=c(names(xa)[1]),stringsAsFactors=FALSE)
xp<-melt(xp,id=c(names(xp)[1]),stringsAsFactors=FALSE)

xa$variable<-gsub('X','',xa$variable)
xp$variable<-gsub('X','',xp$variable)

xa<-data.frame(rename(xa,c(variable = 'Year')))
xp<-data.frame(rename(xp,c(variable = 'Year')))

xa$NAME_0<-unlist(lapply(xa[,1],function(x)(strsplit(x,',')[[1]][4])))
xp$NAME_0<-unlist(lapply(xp[,1],function(x)(strsplit(x,',')[[1]][4])))

#removing data reported by arable area (only interested in total agricultural area) for now
xa<-xa[lapply(xa[,1],function(x)arable$V2[match((strsplit(x,',')[[1]][2]),arable$V1)])=='Total',]
#removing data reported by crop area (only interested in total agricultural area)
xp<-xp[lapply(xp[,1],function(x)croparea$V2[match((strsplit(x,',')[[1]][3]),croparea$V1)])=='Total',]

#exclude the following from xa:
exA<-c("AGRAREA_HA","B_1_12_HA","B_1_12_HOLD" ,"B_1_HA","B_1_HOLD","HOLD_HOLD")
#which represent
#c("ha: Utilised agricultural area","ha: Fallow land - total (with and w/o subsidies)",
#"hold: Fallow land - total (with and w/o subsidies)","ha: Arable land","hold: Arable land","hold: Total number of holdings")
xa<-xa[!unlist(lapply(xa[,1],function(x)(strsplit(x,',')[[1]][3]))) %in% exA,]

#exclude the following from xp:
exP<-c("AGRAREA_HA","B_4_HA","B_4_HOLD","HOLD_HOLD")
#which represent
#c( "ha: Utilised agricultural area","ha: Permanent crops","hold: Permanent crops","hold: Total number of holdings")
xp<-xp[!unlist(lapply(xp[,1],function(x)(strsplit(x,',')[[1]][1]))) %in% exA,]

Aout<-data.frame(cbind(Theme='Landuse',
                       NAME_0=unlist((lapply(xa[,1],function(x)unlist(strsplit(x,',')[[1]][4])))),
                       NAME_1=1,NAME_2=1,NAME_3=1,
                       Type='Cropland',
                       Subtype="Arable land",
                       FS_class_min=unlist(lapply(xa[,1],function(x)Range_min[match((strsplit(x,',')[[1]][1]),euRange)])),
                       FS_class_max=unlist(lapply(xa[,1],function(x)Range_max[match((strsplit(x,',')[[1]][1]),euRange)])),
                       FS_class_unit='ha',
                       Subject=subject[match(unlist(lapply(xa[,1],function(x)strsplit(indic_ef$V2[match((strsplit(x,',')[[1]][3]),indic_ef$V1)],':')[[1]][1])),euSubj)],
                       Reporting_unit='',
                       Orig_crop=trimws(unlist(lapply(xa[,1],function(x)paste(unlist(strsplit(indic_ef$V2[match((strsplit(x,',')[[1]][3]),indic_ef$V1)],':')[[1]][-1]),collapse='')))),
                       #Orig_crop=trimws(unlist(lapply(xa[,1],function(x)indic_ef$V2[match((strsplit(x,',')[[1]][3]),indic_ef$V1)]))),
                       Value=as.numeric(as.character(xa$value)),
                       Data_unit='ha',
                       Year=xa$Year,
                       Source='Eurostat',
                       Comments='',
                       Person_entering='Larissa Jarvis',
                       Data_entered='2015-11-10',
                       Orig_var='ef_alarableaa: Arable crops: number of farms and areas of different arable crops by agricultural size of farm (UAA) and size of arable area'
), stringsAsFactors = FALSE) 

Pout<-data.frame(cbind(Theme='Landuse',
                       NAME_0=unlist(lapply(xp[,1],function(x)unlist(strsplit(x,',')[[1]][4]))),
                       NAME_1=1,NAME_2=1,NAME_3=1,
                       Type='Cropland',
                       Subtype="",
                       FS_class_min=unlist(lapply(xp[,1],function(x)Range_min[match((strsplit(x,',')[[1]][2]),euRange)])),
                       FS_class_max=unlist(lapply(xp[,1],function(x)Range_max[match((strsplit(x,',')[[1]][2]),euRange)])),
                       FS_class_unit='ha',
                       Subject=subject[match(unlist(lapply(xp[,1],function(x)strsplit(indic_ef$V2[match((strsplit(x,',')[[1]][1]),indic_ef$V1)],':')[[1]][1])),euSubj)],
                       Reporting_unit='',
                       Orig_crop=trimws(unlist(lapply(xp[,1],function(x)paste(unlist(strsplit(indic_ef$V2[match((strsplit(x,',')[[1]][1]),indic_ef$V1)],':')[[1]][-1]),collapse='')))),
                       #Orig_crop=(unlist(lapply(xp[,1],function(x)indic_ef$V2[match((strsplit(x,',')[[1]][1]),indic_ef$V1)]))),
                       Value=as.numeric(as.character(xp$value)),
                       Data_unit='ha',
                       Year=xp$Year,
                       Source='Eurostat',
                       Comments='',
                       Person_entering='Larissa Jarvis',
                       Data_entered='2015-11-10',
                       Orig_var='ef_popermaa: Permanent crops: number of farms and areas by agricultural size of farm (UAA) and size of permanent crop area'
), stringsAsFactors = FALSE) 

EU<-data.frame(rbind(Pout,Aout),stringsAsFactors = FALSE)
write.csv(EU,paste(dwd,'/Data/Europe/2-Formatted/Europe_crop_by_farmsize_2005-2013.csv',sep=''),row.names=FALSE)
