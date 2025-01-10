#COS_CNA_2014
#Costa Rica census
wd <- '/Users/larissa/Larissa/Earthstat/'
dwd <- 'Data/Costa Rica/0-Source/COS_CNA_2014/'

file.out <- 'CostaRica_CropsByFarmsize_2014.csv'
owd <- '/Users/larissa/LUGE/Projects/Vinny/2-Formatted'

library('gdata')
library('zoo')
library('plyr')
library('reshape2')

classes <- c("Menos de 1 hectárea","1 a menos de 2","2 a menos de 3","3 a menos de 4","4 a menos de 5",
             "5 a menos de 10","10 a menos de 20","20 a menos de 50","50 a menos de 100","100 y más")
class_min<-c(0,1,2,3,4,5,10,20,50,100)
class_max<-c(1,2,3,4,5,10,20,50,100,NA)

files <- list.files(paste0(wd,dwd), full.names = TRUE)
files <- files[grepl('xlsx',files)]

#only interested in t2
files <- files[grepl('t2',files)]

#read in all tables
all.tables <- do.call("rbind.fill", sapply(files, read.xls,sheet = 1,skip=0, header = FALSE,fileEncoding='latin1',stringsAsFactors=FALSE,simplify = FALSE))

#shift tables that are missing column 1
all.tables[is.na(all.tables$V1), -ncol(all.tables)] <- all.tables[is.na(all.tables$V1),-1]

#assign table name to each row to distinguish different tables
all.tables$file  <-  ifelse(grepl('CUADRO',all.tables$V1), all.tables$V1, NA)
all.tables$file  <-  na.locf(all.tables$file)

#Select for tables that report by farm size
df <- all.tables[all.tables$file %in% all.tables$file[grepl('tamanodelafinca', fixvector(all.tables$V1))], ] 

#Subset out rows that have crop names, remove all non-crop specific data
df$crop <- ''
df$crop[grep('CUADRO', df$V1)+1] <- df$V1[grep('CUADRO', df$V1)+1]
df$crop <- unlist(lapply(df$crop, function(x) strsplit(x, "de|por")[[1]][3]))
df$crop[-1]  <-  na.locf(df$crop[-1])

#only taking national level data (by finding all 'Costa Rica' occurences and taking the following 10 rows. In some instances this sibset out data we aren't interested in, so we remove it in the next step)
df.nat <- df[rep(which(df$V1 == 'Costa Rica'), each= 11) + c(0:10),]

df.nat <- df.nat[df.nat$V1 %in% c("Menos de 1 hectárea","1 a menos de 2","2 a menos de 3","3 a menos de 4","4 a menos de 5",
                        "5 a menos de 10","10 a menos de 20","20 a menos de 50","50 a menos de 100","100 y más"),]

#Deal with the weird nuber formatting in some tables
df.nat$V3 <- gsub("\\$1|\\$10|C|\\[|\\]|A", '', df.nat$V3)
df.nat$V3 <- gsub(' ','',df.nat$V3)

df.nat$V4 <- gsub("\\$1|\\$10|C|\\[|\\]|A", '', df.nat$V4)
df.nat$V4 <- gsub(' ','',df.nat$V4)

#V3 is planted area, V4 is harvested, only keeping harvested
x <- melt(df.nat[,c('V1','V4','crop')], id.vars = c('V1','crop'))

out<-data.frame(cbind(theme='Landuse',
                      NAME_0='Costa Rica',
                      NAME_1=1,
                      NAME_2=1,
                      NAME_3=1,
                      type='Cropland',
                      subtype='',
                      fs_class_min=class_min[match(x$V1, classes)],
                      fs_class_max=class_max[match(x$V1, classes)],
                      fs_class_unit='ha',
                      subject=ifelse(x$variable == 'V3', 'Planted area',
                                     ifelse(x$variable == 'V4', 'Harvested area',
                                            NA)),
                      reporting_unit='Per crop',
                      orig_crop=x$crop,
                      #Orig_crop=trimws(unlist(lapply(x[,1],function(x)indic_ef$V2[match((strsplit(x,',')[[1]][3]),indic_ef$V1)]))),
                      value=as.numeric(as.character(gsub(',','',x$value))),
                      data_unit='ha',
                      year=2014,
                      source='VI Censo Nacional Agropecuario',
                      Scode='COS_CNA_2014',
                      comments='',
                      person_entering='Larissa Jarvis',
                      data_entered=Sys.Date(),
                      orig_var='Total de fincas con cultivo de X por extensión sembrada y cosechada en hectáreas',
                      microdata='0',  #Is this microdata 0=no 1=yes
                      weight_corr='0', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='cen' #cen=census data, sur=survey data
), stringsAsFactors = FALSE) 

write.csv(out, paste(owd, file.out, sep='/'), row.names = FALSE)
