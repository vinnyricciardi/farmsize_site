#PER_CNA_2012

wd<-'/Users/larissa/Larissa/Earthstat/'
#wd<-'/Volumes/Time Machine Backups/'

#wd<-'/Volumes/larissa/Larissa/Earthstat/'
list.files('/Volumes')
dwd<-'Data/Peru/0-Source/PER_CNA_2012/'
owd<-'/Users/larissa/LUGE/Projects/Vinny/2-Formatted'
#owd<-'/Users/larissa/Lexar/Formatted_data'

file_out<-'Peru_crop_by_farmsize_2012.csv'

library('plyr')
library('foreign')
#library('pdftables')

#See 337-Ficha.pdf for a description of the various modules

# Some detail on the census: Each census is identified by a principal ID (NPRIN). Within the census, the producer is asked to identify individual parcels of the
# farm. Parcels id (NPARCX), area, and location are recorded. Cropping information (crops, fallow, reason for fallow, tree cover, relationship to parcel) is reported 
# separately for each parcel, but only those within the main district. Management data (machinery, fertilizer, farm credit etc...) are reported for the farm as a whole. This will be inportant when it comes to 
# aggregating up by district. Number of parcels assiciated with each census (farm) varies, from 1 to 999

# REC01: II. Características del productor y III. Características de la Unidad Agropecuaria
# REC01A: III. Parcelas que trabaja o conduce en otros distritos
# REC02: IV. Uso de la tierra,....Cultivos que tiene la parcela en la unidad agropecuaria
# REC02A: IV. Datos adicionales de la parcela, Preg. 36 - 40
# REC02B: IV. Árboles frutales, en forma dispersa, que tiene la parcela , Preg. 41
# REC03: V. Siembras realizadas en la unidad agropecuaria
# REC04: VI. Riego, VII. Principales prácticas agrícolas, VIII. Uso de energía eléctrica, mecánica y animal, IX: Preg. 66,68,69,71,73,77 y 78.
# REC04A: IX. Existencia de ganado, aves, otros animales y colmenas
# REC04B: X. Principales prácticas pecuarias a XV. Asociatividad y apreciaciones del productor
# REC05: XVI. Características del hogar del productor - personas
# REC05B: XVI. Características del hogar del productor (continuación) Hogar

#Converts pdf to cvs for information files (only run once, requires API if you rerun). R does a slopppy job of reading this in, but it can give you an idea of what's in 
#each module. For detail open the individual pfs
# for(i in c(229:239)){
#   convert_pdf(paste0(wd,dwd,'337-Modulo',i,'/',list.files(paste0(wd,dwd,'337-Modulo',i))[3]), output_file = NULL, format = "csv",
#               message = TRUE, api_key = 'fgopda82oewd')
#   }

#admin unit lookup (module XX-Modulo86)
admin_units <- read.csv(paste(wd,'Data/Peru/0-Source/Peru_admin_unit_codes.csv',sep = '/'), stringsAsFactors = FALSE, fileEncoding  = 'UTF-8')

#badmin_units<-read.dbf(paste0(wd,dwd,'328-Modulo86/XX-Modulo86/C001.dbf'),as.is=TRUE)
#admin_units$NOM_DPTO<-iconv(admin_units$NOM_DPTO, 'UTF-8', "macroman", sub="")
#admin_units$NOM_PROV<-iconv(admin_units$NOM_PROV, 'UTF-8', "latin1", sub="")
#admin_units$NOM_DIST<-iconv(admin_units$NOM_DIST, 'UTF-8', "latin1", sub="")

#one fix, this unit is in some versions of admin unit lists but not others:
#admin_units<-rbind.fill(admin_units,data.frame(CCDD=12,CCPP=6,CCDI=99,NOM_DPTO='Junin',NOM_PROV='Satipo',NOM_DIST='Mazamari - Pangoa'))

#crop id lookup
cod_perm<-read.csv(paste0(wd,dwd,'codigo_cultivo_perm.csv'),stringsAsFactors = FALSE)
cod_tran<-read.csv(paste0(wd,dwd,'codigo_cultivo_tran.csv'),stringsAsFactors = FALSE)
names(cod_perm)[2]<-'crop'
names(cod_tran)[2]<-'crop'
crop_id<-rbind.fill(cod_perm,cod_tran)

#farm size classes (WSUP01)
fs.id<-c(1:23)
fs.min<-c(NA, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0,  10.0,  15.0,  20.0,  25.0,  30.0,  35.0,  40.0,  50.0, 100.0, 200.0, 300.0, 500.0, 1000.0, 2500.0,3000.0)
fs.max<-c(0.5,0.9, 1.9, 2.9, 3.9, 4.9, 5.9, 9.9,  14.9,  19.9,  24.9,  29.9,  34.9,  39.9,  49.9,  99.9, 199.9, 299.9, 499.9, 999.9, 2499.9, 2999.9,NA)

#wca farm size classes (for our own classification)
wca.classes <- c(0,1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, NA)
xi<-cbind.data.frame(fs_class_min=wca.classes[-12],
                     fs_class_max=wca.classes[-1],
                     class=letters[1:11],
                     stringsAsFactors=FALSE)

list<-lapply(paste0(wd,dwd,'337-Modulo',c(229:239)),function(x) paste0(x,'/',unlist(list.files(x)[3])[1]))
all_variables <- unique(do.call(`rbind.fill`,lapply(list, read.csv, header=T,skip=2))[,c("Nombre.del.Campo", "Descripcion")])

#read in data for all departments
for (i in c(229:239)){
  files<-lapply(paste0(wd,dwd,c(337:(337+24)),'-Modulo',i),function(x) paste0(x,'/',unlist(list.files(x)[2])[1]))
  assign(paste0('m',i),do.call(`rbind.fill`,lapply(files, read.dbf,as.is=TRUE)))
} 

#'P001' = Departamento
#'P002' = Provincia
#'P003' = Distrito
#'NPRIN' = Número de cédula principal (Census form id, to match results from different modules)
#'P020_01' = Cuál es la superficie total de todas las parcelas o chacras que trabaja o conduce en este distrito? - total farm area in main district
#'P023_04' = CUÁL ES LA SUPERFICIE DE CADA UNA DE LAS PARCELAS O CHACRAS QUE TRABAJA O CONDUCE EN OTROS DISTRITOS? - total farm area in other distrcits
#'P024_03' = Cultivo: Código
#'P025' = Cultivo: Superficie sembrada en ha.
#'P028' = ¿CUÁL SERÁ EL DESTINO DE LA MAYOR PARTE DE LA PRODUCCIÓN?
#'WSUP01' = farm size class (defined in pdfs) There appear to be 3 classifcations, the other two being 'WSUP02' and 'WSUP02A' (with fewer farm size classes)

#Show variables reported by module
# for (i in c(229:239)){
#   print(paste0('MODULE ',paste0('m',i)))
#   print(paste0(all_variables$Nombre.del.Campo[all_variables$Nombre.del.Campo %in% names(get(paste0('m',i)))],': ',all_variables$Descripcion[all_variables$Nombre.del.Campo %in% names(get(paste0('m',i)))]))
# }

#Total farm size will equal the sum of P020_01 and P023_4, but we have to be careful when aggregating to district levels as some parcels fall in different districts.
#The classification (WSUP01-02) into farm size classes doesn't seem to include parcels in other districts (this is how they report in their tabulated data), so that
#is how we are calculating as well

farm.size<-unique(m229[,c('P001','P002','P003','P020_01','NPRIN')])
#aggregated by district
farm.size.admin<-aggregate(P020_01~P001+P002+P003,data=farm.size,sum)


##############################
#Crops by farm size formatting

#Aggregate crops to farm level. We exclude P024_01=c(90:97), which are pasture, forest, fallow etc....
crops<-aggregate(P025~P001+P002+P003+NPRIN+P024_03,data=m231[!m231$P024_01 %in% c(90:97),],sum)

#Then attach farm size class data to crop data
#using original classes
# crops.farmsize<-merge(crops,m229[!is.na(m229$WSUP01),],by=c('P001','P002','P003','NPRIN'))

#using our classes
#assign class based on total farm area
m229$wca <- ifelse(m229$P020_01 > 0 & m229$P020_01 < 1, 'a',
               ifelse(m229$P020_01 >= 1  & m229$P020_01 < 2, 'b',
                      ifelse(m229$P020_01 >= 2 & m229$P020_01 < 5, 'b',
                             ifelse(m229$P020_01 >=  5 & m229$P020_01 < 10, 'd',
                                    ifelse(m229$P020_01 >=  10 & m229$P020_01 < 20, 'e',
                                           ifelse(m229$P020_01 >=  20 & m229$P020_01 < 50, 'f',
                                                  ifelse(m229$P020_01 >=  50 & m229$P020_01 < 100, 'g',
                                                         ifelse(m229$P020_01 >=  100 & m229$P020_01 < 200, 'h',
                                                                ifelse(m229$P020_01 >=  200 & m229$P020_01 < 500, 'i',
                                                                       ifelse(m229$P020_01 >=  500 & m229$P020_01 < 1000, 'j',
                                                                              ifelse(m229$P020_01 >=  1000,'k',
                                                                                     NA)))))))))))

crops.farmsize<-merge(crops,m229[!is.na(m229$wca),],by=c('P001','P002','P003','NPRIN'))

#Fruit trees etc. NOTE! this is number of trees
trees<-aggregate(P041_03~P001+P002+P003+NPRIN+P041_04,data=m233,sum)

#now aggregate up to district level by crop and farm size class
crops.by.farmsize<-aggregate(P025~P001+P002+P003+wca+P024_03,data=crops.farmsize,sum)

#add crop names
crops.by.farmsize$crop<-crop_id$crop[match(crops.by.farmsize$P024_03,crop_id$CODIGO)]
#Crop id 1486 is not listed anywhere in the crop definitions. It appears to be some sort of grass (sequentially it should fit in as a grass, but it is not identified).
#For now we are assigning Pasto, other
crops.by.farmsize$crop[crops.by.farmsize$P024_03==1486]<-'Pasto, other'
#Add admin units names
#crops.by.farmsize<-merge(crops.by.farmsize,admin_units[,c("CCDD","CCPP","CCDI","NOM_DPTO","NOM_PROV","NOM_DIST")],by.x=c('P001','P002','P003'),by.y=c('CCDD',"CCPP","CCDI"),all.x=TRUE)
crops.by.farmsize$P001 <- as.numeric(crops.by.farmsize$P001)
crops.by.farmsize$P002 <- as.numeric(crops.by.farmsize$P002)
crops.by.farmsize$P003 <- as.numeric(crops.by.farmsize$P003)

crops.by.farmsize<-merge(crops.by.farmsize,admin_units[,c("Department","Province","District","X","X.1","X.2")],by.x=c('P001','P002','P003'),by.y=c('Department',"Province","District"),all.x=TRUE)
names(crops.by.farmsize)[names(crops.by.farmsize) == 'X'] <- "NOM_DPTO"
names(crops.by.farmsize)[names(crops.by.farmsize) == 'X.1'] <- "NOM_PROV"
names(crops.by.farmsize)[names(crops.by.farmsize) == 'X.2'] <- "NOM_DIST"

#Land use
landuse<-data.frame(cbind(
  theme='Land use',
  NAME_0='Peru',
  NAME_1=trimws(crops.by.farmsize$NOM_DPTO, which = "right"), 
  NAME_2=trimws(crops.by.farmsize$NOM_PROV, which = "right"),
  NAME_3=trimws(crops.by.farmsize$NOM_DIST, which = "right"),
  type='Cropland',
  subtype='',
  subject='Planted area',
  reporting_unit='Per crop',
  value=crops.by.farmsize$P025,
  data_unit='Ha',
  year='2012',
  source='IV Censo Agropecuario',
  comments='Aggregated from microdata variables P025, P024_03, WSUP01',
  person_entering='Larissa Jarvis',
  data_entered='2017-02-23',
  scode='PER_CNA_2012',
  orig_var='Superficie del cultivo en ha.', 
  orig_crop=trimws(crops.by.farmsize$crop),
  fs_class_min=xi$fs_class_min[match(crops.by.farmsize$wca,xi$class)],
  fs_class_max=xi$fs_class_max[match(crops.by.farmsize$wca,xi$class)],
  #fs_class_min=unlist(lapply(crops.by.farmsize$P020_01,function(x)rev(fs.min)[which(rev(fs.min)-as.numeric(x)<=0)][1])),
  #fs_class_max=unlist(lapply(crops.by.farmsize$P020_01,function(x)fs.max[which(as.numeric(x)-fs.max<=0)][1])),
  fs_class_unit='Ha',
  microdata='1',  #Is this microdata 0=no 1=yes
  weight_corr='0', #Is this corrected by household weight 0=no 1=yes
  cen_sur='cen' #cen=census data, sur=survey data
), stringsAsFactors = FALSE) 

#crops that are reported as a rotation (cropa - crop b) are only included under the first crop (this is how thye appear to have tabulated the data into their final reports)
#Here we will drop the second crop, if any

landuse$orig_crop <- unlist(lapply(landuse$orig_crop, function(x) strsplit(x, '-')[[1]][1]))
out<-landuse


write.csv(out,paste(owd,file_out,sep='/'),row.names=FALSE)
##############################



