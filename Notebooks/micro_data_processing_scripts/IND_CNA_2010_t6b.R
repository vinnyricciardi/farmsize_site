#To format scraped India data
wd<-'/Users/larissa/Larissa/Earthstat/'

file_in<-'Data/India/0-Source/IND_CNA_mult/IND_CNA_2010_t6B.csv'
owd<-'/Users/larissa/LUGE/Projects/Vinny/2-Formatted'
file.out<-'India_crop_by_farmsize_2010.csv'

ind<-read.csv(paste(wd,file_in,sep=''),stringsAsFactors = FALSE)

#subset data of interest. Removing any total values or irrelevant information from scraped tables
ind<-ind[ind$size!='ALL CLASSES' &
           ind$crop!='ALL CROPS' &
           ind$State!='ALL INDIA' &
           ind$si_no %in% as.character(c(1:35)),]

ranges<-unique(ind$size)
range_min<-c(0,0.5,1,2,3,4,5,7.5,10,20)
range_max<-c(0.5,1,2,3,4,5,7.5,10,20,NA)

out<-data.frame(cbind(theme='Landuse',
                      NAME_0='India',
                      NAME_1=ind$State,
                      NAME_2=1,NAME_3=1,
                      type='Cropland',
                      subtype="",
                      fs_class_min=range_min[match(ind$size,ranges)],
                      fs_class_max=range_max[match(ind$size,ranges)],
                      fs_class_unit='ha',
                      subject='Crop area',
                      reporting_unit='ha',
                      orig_crop=as.character(ind$crop),
                      value=as.character(ind$Total_Area),
                      data_unit='Ha',
                      year=2010,
                      source='Agricultural Census 2010',
                      comments='',
                      scode='IND_CNA_mult',
                      person_entering='Larissa Jarvis',
                      data_entered='2015-11-16',
                      orig_var='TABLE 6 B: ESTIMATED IRRIGATED AND UNIRRIGATED AREA UNDER CROP',
                      microdata='0',  #Is this microdata 0=no 1=yes
                      weight_corr='0', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='cen' #cen=census data, sur=survey data
), stringsAsFactors = FALSE)  


#Assign crops and crop groups based on FAO classifications where possible

write.csv(out,paste(owd,file.out,sep='/'),row.names=FALSE)
