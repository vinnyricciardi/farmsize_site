#### Read in and format Brazil 2006 census data from excel spreadsheets ####

library('plyr')
library('gdata')
#library('xlsx')
library(RColorBrewer)
library(reshape)
#requires FAO_crop_lookup.R and FAO_food_balance_sheets.R

## BRASIL

cna<-'Data/Brazil/0-Source/BRA_CNA_2006/03ufs/'
wd<-'/Users/larissa/Larissa/Earthstat/'
#wd<-'/Volumes/Time Machine Backups/'

owd<-'/Users/larissa/LUGE/Projects/Vinny/2-Formatted'
#owd<-'/Users/larissa/Lexar/Formatted_data'

file.out<-'Brazil_crop_by_farmsize_2006.csv'
#vars we are interested in
vars<-c("Produzida ( mil frutos )",'Área colhida (ha)','Colhida ( t )','Produzida ( t )','Produzida ( mil frutos )','Área plantada (ha)')

Range<-c("0-0.1","0.1-0.2","0.2-0.5","0.5-1","1-2","2-3","3-4","4-5","5-10","10-20","20-50","50-100","100-200","200-500","500-1000","1000-2500","2500+","0-0")
Range_min<-unlist(lapply(Range,function(x)(strsplit(x,'-')[[1]][1])))
Range_max<-unlist(lapply(Range,function(x)(strsplit(x,'-')[[1]][2])))

#To read in all table headers:
#all.tables<-
all.files<-unlist(lapply(paste0(wd,cna,list.files(paste(wd,cna,sep='')),'/T06/'),function(x) paste0(x,unlist(list.files(x)))))
#all unique tables
all.tables<-unique(unlist(lapply(unlist(lapply(all.files,function(x) strsplit(x,"\\.")[[1]][1])), function(x) strsplit(x, "_")[[1]][6])))

#To read in select tables and format/plot data (here it is for harvested area by farm size and crop)

rm(BR)

for (i in list.files(paste(wd,cna,sep=''))){
  files<-list.files(paste(wd,cna,i,'/T06/',sep=''))
  for (j in files){   
    df = read.xls(paste0(wd,cna,i,'/T06/',j), sheet = 1, header = TRUE,fileEncoding='latin1',stringsAsFactors=FALSE)
    var_x<-unlist(lapply(vars,function(x) if(fixvector(x) %in% fixvector(gsub('\n',' ',df[2,]))){2}else 
      if(fixvector(x) %in% fixvector(gsub('\n',' ',df[3,]))){3}else
        if(fixvector(x) %in% fixvector(gsub('\n',' ',df[4,]))){4}else{NA}))
    #Some notes:
    #we exclude tables that reported planting by month, as the area distribution is not farm area
    if(grepl('mesdoplantio', fixvector(names(df)[1]))){print(paste('Excluded (not useful): ',names(df)[1]));next}
    #Same with tables that report areas less than or bigger than 'pés plantado'. This means individual plants/treees, not the literal
    #translation of 'feet'. Once again, these are reported by group of harvested area, not farm area.
    if(grepl('50pes', fixvector(names(df)[1]))){print(paste('Excluded (not useful): ',names(df)[1]));next}
    if(length(var_x[!is.na(var_x)])==0){print(paste('Excluded (no vars): ',names(df)[1]));next}
    
    #Exlcuding flowers, wood, forestry, ornamental plants, rubber, firewood
    if(grepl('flores', fixvector(names(df)[1])) |
       grepl('madeira', fixvector(names(df)[1])) |
       grepl('silvicultura', fixvector(names(df)[1])) |
       grepl('ornamentais', fixvector(names(df)[1])) |
       grepl('borracha', fixvector(names(df)[1])) |
       grepl('lenha', fixvector(names(df)[1]))
    ){print(paste('Excluded: ',names(df)[1]));next}
    
    
    #identify crop name row
    if(grepl('producao',fixvector(names(df)[1]))){
      if(grepl('areacolhida',fixvector(names(df)[1]))){
        rCrop<-2
        crop<-unique(df[rCrop,][!is.na(df[rCrop,])])[-1]
        if(length(crop)>1){
        
          print('FIX multiple crops areacolhida')
          break
        }else{
          if(TRUE %in% grepl('gruposdeareacolhidaha',fixvector(df[[1]]))){
            x<-df[35:44,c(1,3,6)]
          }else{
            x<-df[seq(grep('gruposareatotalha',fixvector(df[[1]]))+1,grep('gruposareatotalha',fixvector(df[[1]]))+18),c(1,3,6)]
            }
          }
          names(x)<-c('table',gsub('\n',' ',df[rCrop+2,c(3)]),gsub('\n',' ',df[rCrop+1,c(6)]))
          xx<-melt.data.frame(x,id=names(x)[1])
          xx$crop<-crop
      }else{
        rCrop<-2
        crop<-unique(df[rCrop,][!is.na(df[rCrop,])])[-1]
        if(length(crop)>1){
          vars.x<-which(fixvector(df[rCrop+2,]) %in% fixvector(vars))
          x<-df[seq(grep('gruposareatotalha',fixvector(df[[1]]))+1,grep('gruposareatotalha',fixvector(df[[1]]))+18),c(1,vars.x)]
         # names(x)[1]<-c('table',gsub('\n',' ',df[rCrop+2,c(vars.x)]))
          xx<-data.frame(melt(x,id=names(x[1])), stringsAsFactors = FALSE)
          xx$crop<-rep(crop,each=length(c(39:56)))
          xx$variable<-rep(gsub('\n',' ',df[rCrop+2,c(vars.x)]),each=length(c(39:56)))
        }else{
          xx<-data.frame(cbind(df[39:56,1],variable=fixvector(df[rCrop+2,3]),value=df[39:55,3]), stringsAsFactors = FALSE)
          xx$crop<-crop
        }
      }
    }
      
    # if(grepl('estabelecimentos',fixvector(names(df)[1]))){
    #   rCrop<-2
    #   crop<-unique(df[rCrop,][!is.na(df[rCrop,])])[-1]
    #   if(length(crop)>1){
    #    print('FIX multiple crops existabelecimentos')
    #   }else{
    #     if(TRUE %in% grepl('gruposdeareacolhidaha',fixvector(df[[1]]))){
    #       x<-df[35:44,c(1,3,6)]
    #     }else{
    #       x<-df[seq(grep('gruposareatotalha',fixvector(df[[1]]))+1,grep('gruposareatotalha',fixvector(df[[1]]))+18),c(1,3,6)]
    #     }
    #     names(x)<-c('table',gsub('\n',' ',df[rCrop+2,c(3,8:9)]))
    #     xx<-data.frame(melt(x,id=names(x[1])), stringsAsFactors = FALSE)
    #     xx$crop<-crop
    #   }
    # }
      
    out<-data.frame(cbind(theme='Landuse',
                          NAME_0='Brazil',NAME_1=substr(i,3,4),NAME_2=1,NAME_3=1,
                          type='Cropland',
                          subtype="",
                          fs_class_min=if(TRUE %in% grepl('gruposdeareacolhidaha',fixvector(df[[1]]))){c(0,1,2,5,10,20,50,100,200,500,'Sim declaracao')}else{Range_min},
                          fs_class_max=if(TRUE %in% grepl('gruposdeareacolhidaha',fixvector(df[[1]]))){c(1,2,5,10,20,50,100,200,500,NA,'Sim declaracao')}else{Range_max},
                          fs_class_unit='ha',
                          subject=unlist(lapply(xx$variable, function(x) if(x=='Colhida ( t )' | x=='Produzida ( t )' |  x=='Produzida ( 1000 frutos )' | x=="Produzida ( mil frutos )"){'Production'}else
                            if(x=='Área colhida (ha)'){'Harvested area'}else
                              if(x=='Área plantada (ha))'){'Planted area'})),
                          reporting_unit='Per crop',
                          orig_crop=xx$crop,
                          value=as.numeric(as.character(gsub(' ','',xx$value))),
                          data_unit=unlist(lapply(xx$variable, function(x) if(x=='Colhida ( t )'| x=='Produzida ( t )'){'t'}else
                            if(x=='Produzida ( mil frutos )'| x=='Produzida ( 1000 frutos )'){'1000 fruit'}else
                              if(x=='Área plantada (ha))' | x=='Área colhida (ha)'){'Ha'})),
                          year=2006,
                          source='Censo Agropecuario 2006',
                          scode='BRA_CNA_mult',
                          comments=paste('Table: ',j),
                          person_entering='Larissa Jarvis',
                          data_entered='2017-01-30',
                          orig_var=as.character(xx$variable),
                          microdata='0',  #Is this microdata 0=no 1=yes
                          weight_corr='0', #Is this corrected by household weight 0=no 1=yes
                          cen_sur='cen'
    ), stringsAsFactors = FALSE)
  
if(exists('BR')){BR<-rbind(BR,out)}else{BR<-data.frame(out,stringsAsFactors = FALSE)}
  }
}

BR$fs_class_min[BR$fs_class_min=='2500+'] <- 2500
BR$fs_class_min <- as.numeric(BR$fs_class_min)
BR$fs_class_max <- as.numeric(BR$fs_class_max)

#remove landless
BR <- BR[!(BR$fs_class_min == 0 & BR$fs_class_max == 0),]
unique(BR$orig_crop) 
write.csv(BR,paste(owd,file.out,sep='/'),row.names=FALSE)
  
  
  