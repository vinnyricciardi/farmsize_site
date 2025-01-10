#Colombia 2014 census. SPSS files
dwd <- '/Users/larissa/Larissa/Earthstat/Data/Colombia/0-Source/COL_CNA_2014'
file.out <- '/Users/larissa/LUGE/Projects/Vinny/2-Formatted/Colombia_CropsByFarmsize_2014.csv'

library('plyr')
library('foreign')
library('gdata')
library(data.table)

#lookups
admin.id <- read.xls(paste(dwd,'TEMATICA_DISENO DE REGISTRO CNA2014.xlsx',sep='/'), sheet = 3,skip = 1, header = TRUE,fileEncoding='latin1',stringsAsFactors = FALSE)
crop.id <-  read.xls(paste(dwd,'TEMATICA_DISENO DE REGISTRO CNA2014.xlsx',sep='/'), sheet = 4, header = TRUE,fileEncoding='latin1',stringsAsFactors = FALSE)

#farm size classification

#wca farm size classes (for our own classification)
wca.classes  <-  c(0,1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, NA)
xi <- cbind.data.frame(fs_class_min = wca.classes[-12],
                     fs_class_max = wca.classes[-1],
                     class = letters[1:11],
                     stringsAsFactors = FALSE)

folders <- list.dirs(paste(dwd,sep='/'))[!grepl('.txt',list.dirs(paste(dwd,sep='/')))]
folders <- folders[!grepl("0_Backup",folders) & !(grepl("Total_Nacional",folders))]

for (i in c('S01_15(Unidad_productora).sav','S06A(Cultivos).sav'#,'S06BD(Frutales_y_forestales_dispersos,_y_viveros).sav'
            # ,'S06BD(Frutales_y_forestales_dispersos,_y_viveros).sav','S07D(Acuicultura).sav',
            # 'S08(Pesca_artesanal).sav','S09(Maquinaria_uso_agropecuario).sav','S10(Construcciones_uso_agropecuario).sav','S14(Actividad_no_agropecuaria).sav',
            # 'S15H(Hogares).sav','S15P(Personas).sav','S15V(Viviendas).sav'
            )){
  files <- paste(folders,i,sep='/')
  
  assign(strsplit(i,'\\(')[[1]][1],do.call(`rbind.fill`,lapply(files[c(3:34,2)], read.spss,to.data.frame = TRUE,use.value.labels = FALSE)))
}

#variables of interest:

#S01_15$P_S5PAUTOS: Área total de la UPA o UP (S5P40)- 'farm size', in m2
#S01_15$P_S12P142: Hoy; ¿Cuánta es el área con cultivos presentes transitorios; cultivos permanentes; 
#plantaciones forestales; pastos sembrados y pastos o sabanas naturales? (ÁREA CON USO AGROPECUARIO) (P_S12P142)
#S01_15$P_S12P143	Hoy; ¿ Cuánta es el área en BARBECHO?
#S01_15$P_S12P144	Hoy; ¿ Cuánta es el área en DESCANSO?
#S01_15$P_S12P145	Hoy; ¿Cuánta es el área en RASTROJOS?
#S01_15$P_S12P146	Hoy; ¿Cuánta es el área en BOSQUES NATURALES?
#S01_15$P_S12P147	Hoy; ¿ Cuánta es el área en CONSTRUCCIONES O INFRAESTRUCTURA AGROPECUARIA?
#S01_15$P_S12P148	Hoy; ¿ Cuánta es el área en INFRAESTRUCTURA NO AGROPECUARIA? (casa; canchas deportivas; piscina; zonas verdes; área de : trapiche; extracción de aceites; planta de elaboración alimentos para animales;)
#S01_15$P_S12P150A	¿ Cuánta es el ÁREA TOTAL de la Unidad Productora Agropecuaria?
#S06A$P_S6P46: ¿Cuál cultivo o plantación forestal tiene en el lote.? 'crop'
#S06A$P_S12P149	Hoy; ¿ Cuánta es el área en OTROS USOS y COBERTURAS de la tierra? (Bosque natural; vegetación de páramo; cuerpos de agua natural; suelos desnudos; afloramientos rocosos; áreas mineras a cielo abierto; etc.)
#S06A$AREA_SEMBRADA (ha)
#S06A$AREA_COSECHADA (ha)
#S06A$P_S6P59_UNIF: Rendimiento (Ton/ Ha)
#S06A$P_S6P57A: Cantidad obtenida 
#S06A$Cantidad Harvested amount, permanent crops
#S06A$CODIGO crop code (I think...)
#In order to match the numbers reported in the aggregated census data (CNATomo2-Resultados.pdf), 
# we have to separate out UNAP and UAP based on whether they report agro-livestock activity (we are focusing on UAP)
#The variable ENCUESTA is the unique ID for each census that is filled out, although it is sometimes repeated in a table
# because there are different parcels in different departments etc.... 
#The reported total UNAP in the actual Colombia census report is equal to the number of non-unique records,
# not the number of unique ENCUESTAs, not sure why.

#Unidades Productoras No Agropecuaria (UNAP)
UNAP <- subset(S01_15, P_S3P9 == 2 & P_S3P10 == 2 & P_S3P11 == 2 & P_S3P12 == 2 & P_S3P13 == 2 & P_S3P14 == 2)
#UNAP <- subset(S01_15, P_S3P9=='No' & P_S3P10=='No' & P_S3P11=='No' & P_S3P12=='No' & P_S3P13=='No' & P_S3P14=='No')
nrow(UNAP);sum(UNAP$P_S5PAUTOS) #these match reported totals

#Unidades Productoras Agropecuaria (UAP)
UAP <- subset(S01_15, P_S3P9 == 1 | P_S3P10 == 1 | P_S3P11 == 1 | P_S3P12 == 1 | P_S3P13 == 1 | P_S3P14 == 1) #all farming activity (crops and pasture and forest)
View(UAP[which(rowSums(UAP[,c('P_S12P142','P_S12P143','P_S12P144','P_S12P145','P_S12P146','P_S12P147','P_S12P148','P_S12P149')],
                          na.rm = TRUE) != UAP$P_S12P150A),c('P_S12P142','P_S12P143','P_S12P144','P_S12P145','P_S12P146','P_S12P147','P_S12P148','P_S12P149','P_S12P150A')])
#UAP.crop <- subset(S01_15, P_S3P9 == 1 | P_S3P10 == 1 | P_S3P11 == 1) #UAP <- subset(S01_15, P_S3P9=='Si' | P_S3P10=='Si' | P_S3P11=='Si' | P_S3P12=='Si' | P_S3P13=='Si' | P_S3P14=='Si')
nrow(UAP);sum(UAP$P_S5PAUTOS);sum(UAP$farmsize_calc) #these match reported totals

#Calculating farm size for each ENCUESTA
#This is what we are summing to obtain our farm size variable
UAP$farmsize_calc  <-  rowSums(UAP[,c('P_S12P142','P_S12P143','P_S12P144','P_S12P145','P_S12P147')],na.rm = TRUE)

#For censuses with multiple departments and municipios, we assign the sum to the admin area with the largest area
UAP.area <- data.table(UAP[,c('P_DEPTO','P_MUNIC','ENCUESTA','farmsize_calc')])

#aggregate all farm size by ENCUESTA
UAP.encuesta.agg <- data.frame(UAP.area[, farmsize_calc_sum:=sum(farmsize_calc, na.rm = TRUE),by = ENCUESTA])

#Select admin areas with largest amount of farm size for each ENCUESTA
admin.select <- data.frame(UAP.area[UAP.area[, .I[farmsize_calc == max(farmsize_calc)], by = ENCUESTA]$V1])

#Aggregate all crop area for each Encuesta ID and crop ID
crop.temp <- data.frame(data.table(
  S06A[,c('ENCUESTA','P_S6P46','P_S6P57A','AREA_COSECHADA','AREA_SEMBRADA')])
                      [, list(P_S6P57A = sum(P_S6P57A, na.rm = TRUE),AREA_COSECHADA = sum(AREA_COSECHADA, na.rm = TRUE),AREA_SEMBRADA = sum(AREA_SEMBRADA, na.rm = TRUE)),
                        by = .(ENCUESTA,P_S6P46)])

#Attach crop data to farm size data
df <- merge(subset(admin.select,select=-farmsize_calc),crop.temp,by='ENCUESTA',all.x = TRUE)
df <- melt(df,id = c('ENCUESTA','P_DEPTO','P_MUNIC','farmsize_calc_sum','P_S6P46'))

#Excluding any farms that have no reported crop area, excluding planted area, and those with Encuesta id= 999999999
#Ignoring Encuesta = 999999999 because we aren't sure what it indicates
#They represent 1021 (of 2379078) UAPs across the country, only in the 'ethnic group' of 'Ninguno de los anteriores',
#17904457 (of 108993335ha, 16%) of total farm area, 1138456 (of 6705677ha, 17%) of total harvested area,
#and 5101258t (of 33998002t, 15%)
df <- df[df$ENCUESTA %in% S06A$ENCUESTA & df$ENCUESTA != 999999999 & df$variable!='AREA_SEMBRADA',]
x <- df
#attach farm size class based on total farm area reported
#first convert farmsize_calc_sum from m2 to ha
x$farmsize_calc_sum  <-  x$farmsize_calc_sum * 0.0001
x$wca  <-  ifelse(x$farmsize_calc_sum > 0 & x$farmsize_calc_sum < 1, 'a',
                   ifelse(x$farmsize_calc_sum >= 1  & x$farmsize_calc_sum < 2, 'b',
                          ifelse(x$farmsize_calc_sum >= 2 & x$farmsize_calc_sum < 5, 'b',
                                 ifelse(x$farmsize_calc_sum >=  5 & x$farmsize_calc_sum < 10, 'd',
                                        ifelse(x$farmsize_calc_sum >=  10 & x$farmsize_calc_sum < 20, 'e',
                                               ifelse(x$farmsize_calc_sum >=  20 & x$farmsize_calc_sum < 50, 'f',
                                                      ifelse(x$farmsize_calc_sum >=  50 & x$farmsize_calc_sum < 100, 'g',
                                                             ifelse(x$farmsize_calc_sum >=  100 & x$farmsize_calc_sum < 200, 'h',
                                                                    ifelse(x$farmsize_calc_sum >=  200 & x$farmsize_calc_sum < 500, 'i',
                                                                           ifelse(x$farmsize_calc_sum >=  500 & x$farmsize_calc_sum < 1000, 'j',
                                                                                  ifelse(x$farmsize_calc_sum >=  1000,'k',
                                                                                         NA)))))))))))

#aggregate all data to municipio level
x  <-  aggregate(value~P_DEPTO+P_MUNIC+variable+P_S6P46+wca,data = subset(x,select=-farmsize_calc_sum),sum)

landuse <- cbind.data.frame(
  theme='Land use',
  NAME_0='Colombia',
  NAME_1 = admin.id$Nombre.del.departamento[match(as.numeric(as.character(x$P_DEPTO)),admin.id$P_DEPTO)],
  NAME_2 = admin.id$Nombre.del.municipio[match(as.numeric(as.character(x$P_MUNIC)),admin.id$P_MUNIC)],
  NAME_3 = 1,
  type='Cropland',
  subject = ifelse(x$variable == "AREA_SEMBRADA", "Planted area",
                 ifelse(x$variable == "P_S6P57A", "Production",
                        ifelse(x$variable == "AREA_COSECHADA", 'Harvested area',''))),
  reporting_unit='Per crop',
  orig_crop = crop.id$X.Cultivo.o.plantación.forestal[match(as.numeric(as.character(x$P_S6P46)),crop.id$cod_cultivo)], 
  value = as.numeric(x$value),
  data_unit = ifelse(x$variable=="AREA_SEMBRADA" | x$variable=="AREA_COSECHADA","ha",
                   ifelse(x$variable=="P_S6P57A", "t",'')),
  fs_class_min = xi$fs_class_min[match(x$wca,xi$class)], 
  fs_class_max = xi$fs_class_max[match(x$wca,xi$class)],
  fs_class_unit='ha',
  fs_proxy='0', #Is it a proxy for farm size (ie: summed crop area, summed harvested area... 0 = no,1 = yes
  fs_orig_var='Área total de la UPA o UP', #Whatever the orignal variable we are using for farm size is described as: ie: area of farm, crop area...etc
  year='2013',
  source='II Censo Agropecuario', #source name
  scode='COL_CNA_2014', #This is the code we assign for the source ie: TZA_HHS_2007
  comments='',
  orig_var = ifelse(x$variable == "AREA_SEMBRADA", "AREA_SEMBRADA",
                  ifelse(x$variable == "AREA_COSECHADA", "AREA_COSECHADA",
                         ifelse(x$variable == "P_S6P57A", "Cantidad obtenida",''))),
  person_entering='Larissa Jarvis',
  data_entered='2017-06-06',
  cen_sur='cen',
  microdata='1',  #Is this microdata 0 = no 1 = yes
  weight_corr='0', #Is this corrected by household weight 0 = no 1 = yes,
  stringsAsFactors = FALSE)

for(i in 1:ncol(landuse)){
  landuse[[i]] <- iconv(landuse[[i]],'UTF-8','UTF-8')
  #print(Encoding(landuse[[i]]))
}

write.csv(landuse, paste(file.out, sep = '/'), row.names = FALSE)

