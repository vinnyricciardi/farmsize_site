
wd<-'/Users/larissa/Larissa/Earthstat/'
dwd<-'Data/Paraguay/0-Source/PRY_CNA_2008/'
owd<-'/Users/larissa/LUGE/Projects/Vinny/2-Formatted'
file.out<-'Paraguay_crop_by_farmsize_2008.csv'


library('plyr')
library('foreign')
library('pdftools')
library('data.table')

#Read in allpages of interest. Determine if they are the startof a new table or not; parse accordingly.
fs.brk<-c(0,1,5,10,20,50,100,200,500,1000,5000,10000,'')
#read in ppdf text
text<-pdf_text(paste0(wd,dwd,'Book 2.pdf'))
tables<-NA

#Section 6, temporary crops
df<-data.frame(cbind(text[c(167:236)]),stringsAsFactors = FALSE)
df$tab<-lapply(df[[1]],function(x) if(grepl('CUADRO',x)){TRUE}else{FALSE})

for(i in 1:nrow(df)){
  if(df$tab[i]==TRUE){
    if(grepl('CUADRO',strsplit(df[i,1],'\n')[[1]][2])){
      orig_crops<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][4],'  ')[[1]])
      orig_crops<-orig_crops[orig_crops!='']
      table<-strsplit(strsplit(df[i,1],'\n')[[1]][2],':')[[1]][1]
      admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(7,22,37)],function(x) strsplit(x,'  ')[[1]][1]))
      data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(10:21,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
    }else{
      orig_crops<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][3],'  ')[[1]])
      orig_crops<-orig_crops[orig_crops!='']
      table<-strsplit(strsplit(df[i,1],'\n')[[1]][1],',')[[1]][1]
      if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
        admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(7,22,37)],function(x) strsplit(x,'  ')[[1]][1]))
        data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(10:21,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
      }else{
        admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(6,21,36)],function(x) strsplit(x,'  ')[[1]][1]))
        data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(9:20,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
      }
    }
    #data<-data[data!=''][c(rep(5:10, 11) + rep(seq(0,130 ,13), each=6),146:151)]
  }else{
    if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(5,20,35)],function(x) strsplit(x,'  ')[[1]][1]))
      data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(8:19,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
    }else{
      admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(4,19,34)],function(x) strsplit(x,'  ')[[1]][1]))
      admin<-admin[admin!='']
      data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(7:18,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
    }
  }
  
  if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
    data<-data[data!=''][c(rep(c(rep(5:9, 11) + rep(seq(0,130 ,12), each=5),135:139),length(admin)) + rep(seq(0,(length(admin)-1)*139,139),each=60))]
  }else{
    data<-data[data!=''][c(rep(c(rep(5:10, 11) + rep(seq(0,130 ,13), each=6),146:151),length(admin)) + rep(seq(0,(length(admin)-1)*151,151),each=72))]
  }
  
  landuse<-data.frame(cbind(
    theme='Land use',
    NAME_0='Paraguay',
    NAME_1=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(admin,each=36)
    }else{rep(admin,each=24)}, 
    NAME_2=1,
    NAME_3=1,
    type='Cropland',
    subtype='',
    subject=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(c('Cultivated area','Cultivated area','Production'))
    }else{rep(c('Cultivated area','Production'), each=24*length(admin))},
    reporting_unit='Per crop',
    value=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      data[c(rep(c(2,4,5), 12 * length(admin)) + rep(seq(0,length(admin)*59,5),each=3))]
    }else{data[c(seq(2,length(data),by=3),seq(3,length(data),by=3))]},
    data_unit=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(c('Ha', 'Ha','T'))
    }else{rep(c('Ha','T'), each=24*length(admin))},
    year='2008',
    source='Censo Agropecuario Nacional 2008',
    scode='PRY_CNA_2008',
    comments=table,
    person_entering='Larissa Jarvis',
    data_entered='2017-02-23',
    orig_var=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(c('Superficie cultivada', 'Superficie cultivada','Producción obtenida'))
    }else{rep(c('Superficie cultivada','Producción obtenida'),each=24*length(admin))}, 
    orig_crop=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      c(trimws(unlist(strsplit(orig_crops,'y')))[1],trimws(unlist(strsplit(orig_crops,'y')))[2],trimws(unlist(strsplit(orig_crops,'y')))[2])
    }else{rep(trimws(unlist(strsplit(orig_crops,'y'))),each=1)},
    fs_class_min=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(fs.brk[1:12],each=3)
    }else{rep(fs.brk[1:12],each=2)},
    fs_class_max=if(table=="CUADRO 19. CULTIVOS TEMPORALES. Caña de Azúcar."){
      rep(fs.brk[-1],each=3)
    }else{rep(fs.brk[-1],each=2)},
    #fs_class_min=unlist(lapply(crops.by.farmsize$P020_01,function(x)rev(fs.min)[which(rev(fs.min)-as.numeric(x)<=0)][1])),
    #fs_class_max=unlist(lapply(crops.by.farmsize$P020_01,function(x)fs.max[which(as.numeric(x)-fs.max<=0)][1])),
    fs_class_unit='Ha'
  ), stringsAsFactors = FALSE) 
  if(df$tab[i]==TRUE){
    assign(fixvector(strsplit(table,'\\.')[[1]][1]),landuse)
  }else{
    assign(fixvector(strsplit(table,'\\.')[[1]][1]),rbind(get(fixvector(strsplit(table,'\\.')[[1]][1])),landuse))
  }
  tables<-c(tables,fixvector(strsplit(table,'\\.')[[1]][1]))
}

# We are excluding these crops
# Section 7, horticultural crops (this section only reports area planted, and only by farms size at the national level
# df<-data.frame(cbind(text[c(237:240)]),stringsAsFactors = FALSE)
# df$tab<-lapply(df[[1]],function(x) if(grepl('CUADRO',x)){TRUE}else{FALSE})
# 
# for(i in 1:nrow(df)){
#   if(grepl("CUADRO 27", df[[1]][i])){next}#skipping table only reporting orchard area
#   orig_crops<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][3],'  ')[[1]])
#   orig_crops<-orig_crops[orig_crops!='']
#   table<-strsplit(strsplit(df[i,1],'\n')[[1]][1],',')[[1]][1]
#   admin<-" PARAGUAY 2008"
# 
#   data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][9:20], ' '))
#   
#   data<-data[data!=''][c(rep(5:8, 11) + rep(seq(0,110,11), each=4),124:127)]
#   
#   landuse<-data.frame(cbind(
#     theme='Land use',
#     NAME_0='Paraguay',
#     NAME_1=1, 
#     NAME_2=1,
#     NAME_3=1,
#     type='Cropland',
#     subtype='',
#     subject=rep(c('Planted area'), each=1),
#     reporting_unit='Per crop',
#     value=data[c(seq(2,length(data),by=2))],
#     data_unit='Ha',
#     year='2008',
#     source='Censo Agropecuario Nacional 2008',
#     scode='PRY_CNA_2008',
#     comments=table,
#     person_entering='Larissa Jarvis',
#     data_entered='2017-02-23',
#     orig_var=rep(c('Superficie sembrada'),each=1), 
#     orig_crop=rep(trimws(unlist(strsplit(orig_crops,'y'))),each=1),
#     fs_class_min=rep(fs.brk[1:12],each=2),
#     fs_class_max=rep(fs.brk[-1],each=2),
#     #fs_class_min=unlist(lapply(crops.by.farmsize$P020_01,function(x)rev(fs.min)[which(rev(fs.min)-as.numeric(x)<=0)][1])),
#     #fs_class_max=unlist(lapply(crops.by.farmsize$P020_01,function(x)fs.max[which(as.numeric(x)-fs.max<=0)][1])),
#     fs_class_unit='Ha'
#   ), stringsAsFactors = FALSE) 
#   if(df$tab[i]==TRUE){
#     assign(fixvector(strsplit(table,'\\.')[[1]][1]),landuse)
#   }
#   tables<-c(tables,fixvector(strsplit(table,'\\.')[[1]][1]))
# }


#Section 8, permanent crops
df<-data.frame(cbind(text[c(241:280)]),stringsAsFactors = FALSE)
df$tab<-lapply(df[[1]],function(x) if(grepl('CUADRO',x)){TRUE}else{FALSE})

for(i in 1:nrow(df)){
  if(df$tab[i]==TRUE){
    if(grepl('CUADRO',strsplit(df[i,1],'\n')[[1]][2])){
      orig_crops<-strsplit(strsplit(df[i,1],'\n')[[1]][2],'\\.')[[1]][3]
      table<-strsplit(strsplit(df[i,1],'\n')[[1]][2],':')[[1]][1]
      admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(10,25,40)],function(x) strsplit(x,'  ')[[1]][1]))
      data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(13:24,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
    }else{
      orig_crops<-strsplit(strsplit(df[i,1],'\n')[[1]][1],'\\.')[[1]][3]
      table<-strsplit(strsplit(df[i,1],'\n')[[1]][1],',')[[1]][1]
      admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(9,24,39)],function(x) strsplit(x,'  ')[[1]][1]))
      data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(12:23,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
    }
    
    #data<-data[data!=''][c(rep(5:10, 11) + rep(seq(0,130 ,13), each=6),146:151)]
  }else{
    admin<-unlist(lapply(strsplit(df[i,1],'\n')[[1]][c(7,22,37)],function(x) strsplit(x,'  ')[[1]][1]))
    admin<-admin[admin!='']
    data<-unlist(strsplit(strsplit(df[i,1],'\n')[[1]][c(rep(10:21,length(admin)) + rep(seq(0,(length(admin)-1)*15,15),each=12))], ' '))
  }
  
  data<-data[data!=''][c(rep(c(rep(5:12, 11) + rep(seq(0,150 ,15), each=8),168:175),length(admin)) + rep(seq(0,(length(admin)-1)*175,175),each=96))]
  
  landuse<-data.frame(cbind(
    theme='Land use',
    NAME_0='Paraguay',
    NAME_1=rep(admin,each=12), 
    NAME_2=1,
    NAME_3=1,
    type='Cropland',
    subtype='',
    subject=rep(c('Area','Production'), each=12*length(admin)),
    reporting_unit='Per crop',
    value=data[c(seq(2,length(data),by=8),seq(8,length(data),by=8))],
    data_unit=rep(c('Ha','T'), each=12*length(admin)),
    year='2008',
    source='Censo Agropecuario Nacional 2008',
    scode='PRY_CNA_2008',
    comments=table,
    person_entering='Larissa Jarvis',
    data_entered='2017-02-23',
    orig_var=rep(c('Superficie en forma compacta','Producción'),each=12*length(admin)), 
    orig_crop=rep(trimws(unlist(strsplit(orig_crops,'y'))),each=1),
    fs_class_min=rep(fs.brk[1:12],each=1),
    fs_class_max=rep(fs.brk[-1],each=1),
    #fs_class_min=unlist(lapply(crops.by.farmsize$P020_01,function(x)rev(fs.min)[which(rev(fs.min)-as.numeric(x)<=0)][1])),
    #fs_class_max=unlist(lapply(crops.by.farmsize$P020_01,function(x)fs.max[which(as.numeric(x)-fs.max<=0)][1])),
    fs_class_unit='Ha'
  ), stringsAsFactors = FALSE) 
  if(df$tab[i]==TRUE){
    assign(fixvector(strsplit(table,'\\.')[[1]][1]),landuse)
  }else{
    assign(fixvector(strsplit(table,'\\.')[[1]][1]),rbind(get(fixvector(strsplit(table,'\\.')[[1]][1])),landuse))
  }
  tables<-c(tables,fixvector(strsplit(table,'\\.')[[1]][1]))
}


x.list <- lapply(unique(tables[!is.na(tables)]), get)
out<-do.call("rbind.fill", x.list)

out$microdata<-'0'  #Is this microdata 0=no 1=yes
out$weight_corr<-'0' #Is this corrected by household weight 0=no 1=yes
out$cen_sur='cen'
#Remove extra rows from procesing
out<-out[!is.na(out$NAME_1) & out$NAME_1 != '',]
#Number format: '.' designates a comma, so we are removing.
out$value<-as.numeric(gsub('\\.','',out$value))

#replace NAME_1 value of PARAGUAY 2008 with 1 (national level data)
out$NAME_1[grep("PARAGUAY 2008",out$NAME_1)] <- 1

#remove national level data
out <- out[out$NAME_1 != 1, ]

#Exclude regional level data (everything is reported at a lower level)
out <- out[!(out$NAME_1 %in% c(" REGION ORIENTAL", "REGION OCCIDENTAL" ) &
               out$orig_crop %in% out$orig_crop[!out$NAME_1 %in% c("1"," REGION ORIENTAL", "REGION OCCIDENTAL" )]), ]

write.csv(out,paste(owd,file.out,sep='/'),row.names=FALSE)
