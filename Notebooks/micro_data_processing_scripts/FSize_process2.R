library('gdata')
library(plyr)
require(dplyr)
require(data.table)
library(reshape)

load(paste("/Users/larissa/LUGE/Programming/R/Functions and scripts/LUGE_ES.RData", sep = '/'))

ewd<-'/Users/larissa/Larissa/Earthstat' #earthstat data location
lwd<-'/Users/larissa/LUGE' #where my functions etc are
owd<-'/Users/larissa/LUGE/Projects/Vinny' #output location
dwd<-'/Volumes/farmsize/Desktop/Formatted_data' #input data location

# ewd<-'/Users/larissa/Lexar/Earthstat' #earthstat data location
# lwd<-'/Users/larissa/Lexar/LUGE' #where my functions etc are
# owd<-'/Users/larissa/Lexar/LUGE/Projects/Vinny' #output location
# dwd<-'/Users/larissa/Lexar/Formatted_data' #input data location

file.out<-'CropByFarmsize'
list.files('/Volumes')

#crop lookup
crops <- read.csv(paste(owd,'Lookup_crops.csv - Lookup_crops.csv', sep = '/'),stringsAsFactors = FALSE)
crops <- crops[crops$Item.Code != '-', ]
crops$Crop_alt <- iconv(crops$Crop_alt, 'UTF-8', 'UTF-8')
#shapefile lookups
esmer1 <- read.csv(paste(ewd, 'Shapefile/Lookups/esmer1.csv', sep='/'),stringsAsFactors = FALSE)
esmer2 <- read.csv(paste(ewd, 'Shapefile/Lookups/esmer2.csv', sep='/'),stringsAsFactors = FALSE)
esmer3 <- read.csv(paste(ewd, 'Shapefile/Lookups/esmer3.csv', sep='/'),stringsAsFactors = FALSE)

#These are the values to fix farm size distributions that don't match WCA. For each class that doesn't match, it either needs to be groupes
# or split. The values to split are assigned based on the distribution of the matching classes in the WCA data. This
#spreadsheet contains the relationship between input and output classes, as well as the % of each input class contributes to it's associated output class(es)
fs.fix <- read.csv(paste(lwd,'Projects/Vinny/fs_class_fixes.csv', sep = '/'), stringsAsFactors = FALSE)

#target classes; maximun is set to the maximum reoprted by any country
classes_out<-c(0,1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 10000)

xi<-cbind.data.frame(fs_class_min=classes_out[-12],
                     fs_class_max=classes_out[-1],
                     class=letters[1:11],
                     stringsAsFactors=FALSE)

names_sort <- c("theme","es1", "NAME_0","NAME_1","NAME_2","NAME_3","type","subject","orig_var","reporting_unit" ,
"orig_crop","value",  "data_unit", "fs_class_min", "fs_class_max", "fs_class_unit","fs_proxy",  "fs_orig_var", 
"year","source", "scode", "comments",  "person_entering", "date_entered", "cen_sur", 
"microdata", "weight_corr","shpID","id_1","id_2","id_3","Crop","Item.Code", "orig_unit", "orig_fs_unit","fact") 
  
#1) Read in and clean (fix units if necessary, assign es1 code)
files.in <- c(list.files(dwd,full.names = TRUE),list.files(paste(lwd, 'Projects/Vinny/2-Formatted',sep='/'),full.names = TRUE))
files.in <- c(list.files(dwd,full.names = TRUE))
sources<-NA
#df<-do.call(`rbind.fill`,lapply(files.in, fread,stringsAsFactors=TRUE))

#summarizes processing
missed_units <- data.frame(es1 = '', NAME_1 = '', NAME_2 = '', NAME_3 = '')
missed_crops <- data.frame(es1 = '', orig_crop = '')

summary_units <- data.frame(es1 = '1', num_units = as.integer(1), num_unmatched = as.integer(1))
summary_crops <- data.frame(es1 = '1', subject = '1', sum = as.double(1), sum_unmatched = as.double(1))


for(i in files.in){
  print(i)
  
  df <- fread(i,encoding = if(grepl('Peru',i)){'Latin-1'}else{'UTF-8'},stringsAsFactors = FALSE)
  
  #remove any landless or total farm size classes that might have been input
  df <- df[!(is.na(df$fs_class_min) & is.na(df$fs_class_max)) & !(df$fs_class_min == '' & df$fs_class_max == ''), ]
  #x <- nameES(x)
  df<-nameES(df)
  #df<-subset(df,select=-orig_var)
  
  if("orig_group" %in% names(df)){df<-subset(df,select=-orig_group)}
  if(!"orig_var" %in% names(df)){df$fs_orig_var <- ''}
  if(!"fs_orig_var" %in% names(df)){df$fs_orig_var <- ''}
  if(!"fs_proxy" %in% names(df)){df$fs_proxy <- 0}
  if(!"scode" %in% names(df)){df$scode <- ''}
  if(!"weight_corr" %in% names(df)){df$weight_corr <- ''}
  
  # if(!'data_unit' %in% names(df)) df$data_unit<-ifelse(df$subject == 'Production',
  #                                                      't',
  #                                                      ifelse(df$subject == 'Yield',
  #                                                             't/ha',
  #                                                             ifelse(df$subject == 'Harvested area',
  #                                                                    'ha',
  #                                                                    NA))) #this is assuming any unreported data units are entered as ha, t and t/ha 
  df$fs_class_min<-as.numeric(df$fs_class_min)
  df$fs_class_max<-as.numeric(df$fs_class_max)
  df$value<-as.numeric(df$value)
  
  df <- unitsES(df)
  df <- es1Match(df, faomer, 'NAME_0')
  
  #keep track of sources to compile a table at the end
  sources<-c(sources,unique(df$scode))
  
  if(i == "/Volumes/farmsize/Desktop/Formatted_data/Europe_crop_by_farmsize_2005-2013.csv"   ){
    df <- df[df$year == 2013,]
  }
  #save as intermediary file
  #write.csv(df, paste(owd,'Intermediary/CropsByFarmsize_1.csv',sep='/'))
  #df<-read.csv(paste(owd,'Intermediary/CropsByFarmsize_1.csv',sep='/'), stringsAsFactors = FALSE)
  #df<-fread(paste(owd,'Intermediary/CropsByFarmsize_1.csv',sep='/'),encoding='UTF-8',stringsAsFactors = FALSE)
  
  #2) Harmonize farm size classes. This only has to be done for non-microdata
  
  if(unique(df$microdata) != 1 | 'South Africa' %in% df$NAME_0){
    xx <- data.frame(df)
    
    xx.fixes <- merge(xx, fs.fix, by.x=c('es1','fs_class_min','fs_class_max'), by.y = c('es1','fs_class_min_in','fs_class_max_in'))
    xx.fixes$value_corr <- xx.fixes$value * (xx.fixes$per/100)
    
    xx.fixes <- data.table(xx.fixes)
    xx.fixes[, newValue := sum(value_corr,na.rm=TRUE), by = list(class, es1, NAME_1,NAME_2, NAME_3, subject,orig_crop, orig_var,year, data_unit, orig_unit)]
  
    # keep unique observations
    uniqdat <- subset(xx.fixes, select = -c(fs_class_min,fs_class_max,per,NAME,value,value_corr,
                                  Year,Type,Subject,class,percent_total))
  
    names(uniqdat) <- ifelse(names(uniqdat) == "fs_class_min_out", "fs_class_min",
                           ifelse(names(uniqdat) == "fs_class_max_out", "fs_class_max",
                                  ifelse(names(uniqdat) == "newValue", "value",
                                         names(uniqdat))))

    uniqdat<-(uniqdat[, lapply(.SD, 
                     function(x)if(class(x) == "numeric"){mean(x,na.rm=TRUE)}else{paste(unique(x),collapse=';')}), 
            by=list(theme, type, subject, reporting_unit, orig_crop, fs_class_min,
                    fs_class_max, fs_class_unit, year, es1, NAME_0, NAME_1, NAME_2, NAME_3, orig_unit, data_unit, orig_var, value)])
    
    #new <- aggregate(value~fs_class_min+fs_class_max, test, sum, rm.na = FALSE)
    #orig <- aggregate(value~fs_class_min+fs_class_max, xx, sum, rm.na = TRUE)
    orig <- data.table(xx)
    orig[, tots := sum(value,na.rm=TRUE), by = list(fs_class_min,fs_class_max)]
    orig[, tots_1 := sum(value,na.rm=TRUE), by = list(NAME_1)]
    orig <- unique(data.frame(orig)[,c('fs_class_min','fs_class_max','tots')])
    orig <- orig[order(orig$fs_class_min),]
    
    #orig_1 <- unique(data.frame(orig)[,c('NAME_1','tots_1')])
    new <- data.table(uniqdat)
    new[, tots := sum(value,na.rm=TRUE), by = list(fs_class_min,fs_class_max)]
    new[, tots_1 := sum(value,na.rm=TRUE), by = list(NAME_1)]
    new <- unique(data.frame(new)[,c('fs_class_min','fs_class_max','tots')])
    new <- new[order(new$fs_class_min),]
    #new_1 <- unique(data.frame(new)[,c('NAME_1','tots_1')])
    
    if(sum(xx$value, na.rm=TRUE) != sum(uniqdat$value, na.rm=TRUE)){print(i);print('fs_adjust input and output differ');break}
    
    write.fwf(orig, paste(owd, paste0(strsplit(rev(strsplit(i, '/')[[1]])[1], '\\.')[[1]][1],'_orig_class.txt'),sep='/'))
    write.fwf(new, paste(owd, paste0(strsplit(rev(strsplit(i, '/')[[1]])[1], '\\.')[[1]][1],'_new_class.txt'),sep='/'))
    
    df <- data.frame(uniqdat)
    }
 
  #3) Match to FAO crop ID
  reported_crops<-data.table(unique(df[,c('NAME_0','orig_crop')]))
  reported_crops[,orig_crop_fix := fixvector(orig_crop)]
  setkey(reported_crops,orig_crop_fix)
  
  crops <- data.table(crops)
  crops[,Crop_alt := fixvector(Crop_alt)]
  setkey(crops,Crop_alt)
  
  reported_crops[crops, Crop := Crop]
  reported_crops[crops, Item.Code := Item.Code]
  
  df <- data.table(df)
  setkey(df, orig_crop)
  setkey(reported_crops, orig_crop)
  df[reported_crops, Crop := Crop]
  df[reported_crops, Item.Code := Item.Code]
  
  summary_crops<-rbind(summary_crops,
                       as.data.frame(df %>% 
                                       group_by_(.dots=c("es1","subject")) %>%
                                       summarise(sum = sum(as.numeric(value),na.rm=TRUE), sum_unmatched = sum(as.numeric(value[is.na(Item.Code)]), na.rm=TRUE)))
  )
  
  
  as.data.frame(df %>% 
                  group_by('es1') %>%
                  summarise(sum = sum(as.numeric(value))))
  
  missed_crops<-rbind(missed_crops,unique(df[is.na(df$Item.Code) , c('es1','orig_crop')]))
  
  #4) Match to shapefile IDs
  
  #Here are my kindda clunky functions to find the best possible match of admin units to names
  ones<-function(x){
    id_1<-ifelse(x[one] == '1' | is.na(x[one]), '',
                 ifelse(x[one] %in% esmer1$r1[esmer1$es1 == x[es1]], esmer1$id1[esmer1$es1 == x[es1] & esmer1$r1 == x[one]][1],
                        NA)
    )
  }
  twos <- function(x){
    #when matching at level 2, we also fill in level 1 where necessary. We try to match using id1 if avialable, 
    #if not we only match at name_2. This is the same for all levels
    rbind(id_1 = ifelse(x[two] == '1' | is.na(x[two]), 
                        x[id_one],
                        ifelse(!x[two] %in%  esmer2$r2[esmer2$es1 == x[es1]],
                               x[id_one],
                               ifelse(length(esmer2$id2[esmer2$es1 == x[es1] & 
                                                          esmer2$r2 == x[two] & 
                                                          esmer2$id1 == as.numeric(x[id_one])]) != 0,
                                      x[id_one],
                                      ifelse(length(esmer2$id2[esmer2$es1 == x[es1] & 
                                                                 esmer2$r2 == x[two]]) != 0,
                                             esmer2$id2[esmer2$es1 == x[es1] & 
                                                          esmer2$r2 == x[two]][1],
                                             NA)))),
          id_2 = ifelse(x[two] == '1' | is.na(x[two]), 
                        '',
                        ifelse(!x[two] %in%  esmer2$r2[esmer2$es1 == x[es1]],
                               '',
                               ifelse(length(esmer2$id2[esmer2$es1 == x[es1] & 
                                                          esmer2$r2 == x[two] & 
                                                          esmer2$id1 == as.numeric(x[id_one])]) != 0 & 
                                        !is.na(esmer2$id2[esmer2$es1 == x[es1] & 
                                                            esmer2$r2 == x[two] & 
                                                            esmer2$id1 == as.numeric(x[id_one])]),
                                      esmer2$id2[esmer2$es1 == x[es1] & 
                                                   esmer2$r2 == x[two] & 
                                                   esmer2$id1 == as.numeric(x[id_one])][1],
                                      ifelse(length(esmer2$id2[esmer2$es1 == x[es1] & 
                                                                 esmer2$r2 == x[two]]) != 0,
                                             esmer2$id2[esmer2$es1 == x[es1] & 
                                                          esmer2$r2 == x[two]][1],
                                             NA))))
    )
  }
  threes <- function(x){
    rbind(id_1 = ifelse(x[three] == '1' | is.na(x[three]), 
                        x[id_one],
                        ifelse(!x[three] %in%  esmer3$r3[esmer3$es1 == x[es1]],
                               x[id_one],
                               ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                          esmer3$r3 == x[three] &
                                                          esmer3$id1 == as.numeric(x[id_one]) &
                                                          esmer3$id2 == as.numeric(x[id_two])]) != 0,
                                      x[id_one],
                                      ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three] &
                                                                 esmer3$id1 == as.numeric(x[id_one])]) != 0,
                                             x[id_one],
                                             ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                        esmer3$r3 == x[three]]) != 0,
                                                    esmer3$id3[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three]][1],
                                                    x[id_one]))))),
          
          id_2 = ifelse(x[three] == '1' | is.na(x[three]), 
                        x[id_two],
                        ifelse(!x[three] %in%  esmer3$r3[esmer3$es1 == x[es1]],
                               x[id_two],
                               ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                          esmer3$r3 == x[three] &
                                                          esmer3$id1 == as.numeric(x[id_one]) &
                                                          esmer3$id2 == as.numeric(x[id_two])]) != 0,
                                      x[id_two],
                                      ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three] &
                                                                 esmer3$id1 == as.numeric(x[id_one])]) != 0,
                                             esmer3$id2[esmer3$es1 == x[es1] & 
                                                          esmer3$r3 == x[three] &
                                                          esmer3$id1 == as.numeric(x[id_one])][1],
                                             ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                        esmer3$r3 == x[three]]) != 0,
                                                    esmer3$id2[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three]][1],
                                                    x[id_two]))))),
          
          id_3 = ifelse(x[three] == '1' | is.na(x[three]), 
                        '',
                        ifelse(!x[three] %in%  esmer3$r3[esmer3$es1 == x[es1]],
                               '',
                               ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                          esmer3$r3 == x[three] &
                                                          esmer3$id1 == as.numeric(x[id_one]) &
                                                          esmer3$id2 == as.numeric(x[id_two])]) != 0,
                                      esmer3$id3[esmer3$es1 == x[es1] & 
                                                   esmer3$r3 == x[three] &
                                                   esmer3$id1 == as.numeric(x[id_one]) &
                                                   esmer3$id2 == as.numeric(x[id_two])][1],
                                      ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three] &
                                                                 esmer3$id1 == as.numeric(x[id_one])]) != 0,
                                             esmer3$id3[esmer3$es1 == x[es1] & 
                                                          esmer3$r3 == x[three] &
                                                          esmer3$id1 == as.numeric(x[id_one])][1],
                                             ifelse(length(esmer3$id3[esmer3$es1 == x[es1] & 
                                                                        esmer3$r3 == x[three]]) != 0,
                                                    esmer3$id3[esmer3$es1 == x[es1] & 
                                                                 esmer3$r3 == x[three]][1],
                                                    NA)))))
    )
  }
  
  admin <- data.table(unique(data.frame(df)[ ,names(df)[names(df) %in% c('NAME_0','NAME_1','NAME_2','NAME_3','NAME_4')]]))
  admin <- data.table(es1Match(admin,faomer, 'NAME_0'))
  admin[ ,name_1_fix := fixvector(NAME_1)]
  admin[ ,name_2_fix := fixvector(NAME_2)]
  admin[ ,name_3_fix := fixvector(NAME_3)]
  admin[ ,c('id_1', 'id_2', 'id_3', 'id_4') := '' ]
  
  #special fixes: Countries that need to be shifted to match gadm levels:
  #Malawi needs to be shifted(first level reported is regions)
  setkey(admin,es1)
  admin['MWI', name_1_fix := fixvector(NAME_2)]
  admin['MWI', name_2_fix := fixvector(NAME_3)]
  
  #locate columns of interest
  es1 <- grep('es1',names(admin))
  one <- grep('name_1_fix',names(admin))
  id_one <- grep('id_1',names(admin))
  
  two <- grep('name_2_fix',names(admin))
  id_two <- grep('id_2',names(admin))
  
  three <- grep('name_3_fix',names(admin))
  id_three <- grep('id_3',names(admin))
  
  four <- grep('name_4_fix',names(admin))
  id_four <- grep('id_4',names(admin))
  
  admin$id_1 <- apply(admin,1,FUN=ones)
  admin[ ,c('id_1','id_2')] <- data.frame(t(apply(admin,1,FUN=twos)))
  admin[ ,c('id_1','id_2','id_3')] <- data.frame(t(apply(admin,1,FUN=threes)))
  
  admin[, id_1 := as.numeric(as.character(id_1))]
  admin[, id_2 := as.numeric(as.character(id_2))]
  admin[, id_3 := as.numeric(as.character(id_3))]
  
  admin <- data.frame(admin)
  admin$shpID<-ifelse(admin$NAME_1 == 1 & admin$NAME_2 == 1 & admin$NAME_3 == 1,
                      admin$es1,
                      ifelse(is.na(admin$id_3) | admin$id_3 == '',
                             ifelse(is.na(admin$id_2) | admin$id_2 == '',
                                    ifelse(is.na(admin$id_1) | admin$id_1 == '',
                                           ifelse(is.na(admin$id_1),
                                                  NA,
                                                  admin$es1),
                                           paste0(admin$es1, formatC(admin$id_1,format="d", flag="0", width=3))),
                                    paste0(admin$es1, formatC(admin$id_1,format="d", flag="0", width=3),
                                           formatC(admin$id_2,format="d", flag="0", width=3))),
                             paste0(admin$es1, formatC(admin$id_1,format="d", flag="0", width=3),
                                    formatC(admin$id_2,format="d", flag="0", width=5),
                                    formatC(admin$id_3,format="d", flag="0", width=5))))
  
  admin <- data.table(admin)
  setkey(df, es1,NAME_1,NAME_2,NAME_3)
  setkey(admin,es1,NAME_1,NAME_2,NAME_3)
  
  df[admin, id_1 := id_1]
  df[admin, id_2 := id_2]
  df[admin, id_3 := id_3]
  df[admin, shpID := shpID]
  
  df<-data.frame(df)
  
  missed_units<-rbind(missed_units,unique(admin[is.na(shpID), c('es1','NAME_1','NAME_2','NAME_3')]))
  
  summary_units<-rbind(summary_units, 
                       as.data.frame(admin %>% 
                         group_by(es1) %>%
                         summarise(num_units = length(NAME_1), num_unmatched = length(NAME_1[is.na(id_1) | is.na(id_2) | is.na(id_3)]))))
                       
  
  #remove unmatched (shpID==NA)
  if(!i %in% (c("/Volumes/farmsize/Desktop/Formatted_data/Tajikistan_cropsByFarmsize_2007.csv",
              "/Volumes/farmsize/Desktop/Formatted_data/Uganda_cropsByFarmsize_2013.csv"))){
    df <- df[!is.na(df$shpID),]
  }
 
  #Dissolve on shpID (for units that are assigned the same ID)
  
  dt.ap<-data.table(df[!is.na(df$shpID) & df$subject != 'Yield',])
  dt.y<-data.table(df[!is.na(df$shpID) & df$subject == 'Yield',])
  
  dt.ap[, value:=as.numeric(value)]
  dt.y[, value:=as.numeric(value)]
  
  dt.ap.agg<-(dt.ap[, lapply(.SD, 
                             function(x)if(class(x) == "numeric"){sum(x,na.rm=TRUE)}else{paste(unique(x),collapse=';')}), 
                    by=list(theme, type, subject, reporting_unit, orig_crop, fs_class_min,
                            fs_class_max, fs_class_unit, year, shpID)])
  
  dt.y.agg<-(dt.y[, lapply(.SD, 
                           function(x)if(class(x) == "numeric"){mean(x,na.rm=TRUE)}else{paste(unique(x),collapse=';')}), 
                  by=list(theme, type, subject, reporting_unit, orig_crop, fs_class_min,
                          fs_class_max, fs_class_unit, year, shpID)])
  
  df<-rbind(data.frame(dt.ap.agg), data.frame(dt.y.agg))
  
  df <- df[ ,match(names_sort[names_sort%in%names(df)],names(df))]
 
  print(i);print(unique(df$subject))
  df$subject[df$subject == "Harvested Area"] <- 'Harvested area'
  #save as intermediary file
  write.csv(df,paste(owd,'3-Processed',paste0('p',rev(strsplit(i,'/')[[1]])[1]),sep='/'), row.names = FALSE)
  write.csv(df,paste("/Volumes/farmsize/Desktop",'Processed_data',paste0('p',rev(strsplit(i,'/')[[1]])[1]),sep='/'), row.names = FALSE)
  #df<-read.csv(paste(owd,'Intermediary/CropsByFarmsize_4.csv',sep='/'), stringsAsFactors = FALSE)
}


#checks
missed_units <- unique(missed_units)
missed_crops <- unique(missed_crops)

summary_crops$per_unmatched <- 100*(summary_crops$sum_unmatched/summary_crops$sum)
summary_units$per_unmatched <- 100*(summary_units$num_unmatched/summary_units$num_units)

all <- do.call(`rbind.fill`,lapply(list.files(paste('/Users/larissa/Lexar','Processed_data', sep='/'), full.names = TRUE), read.csv))

