#Bulk downloaded survey/census data https://quickstats.nass.usda.gov/tutorials
wd<-'/Users/larissa/Larissa/Earthstat/'
dwd<-'Data/USA/0-Source/USA_CNA_multc/qs.crops_20170127.txt'
owd<-'/Users/larissa/Larissa/LUGE/Projects/Vinny/2-Formatted'
file.out<-'USA_crop_by_farmsize_2012.csv'
#dwd<-'Data/USA/0-Source/Non-census/USA_ASR_mult/qs.census2002.txt'
#dwd<-'Data/USA/0-Source/Non-census/USA_ASR_mult/qs.census2007.txt'

library(plyr)
library(data.table)

#x_07<-read.csv(paste0(wd,dwd),sep='\t',stringsAsFactors = FALSE)
#x_02<-read.csv(paste0(wd,dwd),sep='\t',stringsAsFactors = FALSE)
x_crop<-fread(paste0(wd,dwd),sep='\t',stringsAsFactors = FALSE)


#Area harvested and production by operated area (crop by farmsize project)
ha_prod = subset(x_crop,AGG_LEVEL_DESC == 'STATE' & 
              !UNIT_DESC %in% c('OPERATIONS','SQ FT','TREES') & 
              (STATISTICCAT_DESC=='AREA HARVESTED'  | STATISTICCAT_DESC== 'PRODUCTION') &
              x_crop$PRODN_PRACTICE_DESC=="ALL PRODUCTION PRACTICES"&      
              DOMAIN_DESC == 'AREA OPERATED' & 
              COMMODITY_DESC != 'CUT CHRISTMAS TREES' & COMMODITY_DESC != 'SHORT TERM WOODY CROPS')

x<-ha_prod
out<-data.frame(cbind(theme='Landuse',
                      NAME_0='USA',
                      NAME_1=proper(x$STATE_NAME),
                      NAME_2=1,NAME_3=1,
                      type='Cropland',
                      subtype="",
                      fs_class_min=numform(unlist(lapply(x$DOMAINCAT_DESC,function(x)unlist(strsplit(x, split="[-+*/)( ]"))[4]))),
                      fs_class_max=numform(unlist(lapply(x$DOMAINCAT_DESC,function(x)unlist(strsplit(x, split="[-+*/)( ]"))[6]))),
                      fs_class_unit='acre',
                      fs_proxy= '0',
                      fs_orig_var = 'AREA OPERATED',
                      subject=unlist(lapply(x$STATISTICCAT_DESC, function(x) if(x=='PRODUCTION'){'Production'}else
                        if(x=='AREA HARVESTED'){'Harvested area'})),
                      reporting_unit='Per crop',
                      orig_crop=proper(x$COMMODITY_DESC),
                      orig_group=proper(x$GROUP_DESC),
                      value=as.numeric(numform(x$VALUE)),
                      data_unit=x$UNIT_DESC,
                      year=x$YEAR,
                      source='USDA National Agricultural Statistics Service',
                      scode='USA_CNA_multc',
                      comments=unlist(lapply(x$VALUE,function(x) if (x== "(D)") {'Withheld to avoid disclosing data for individual operations.'}else
                                                              if(x=="(NA)") {'Not available.'}else
                                                              if(x=="(X)") {'Not applicable.'}else
                                                              if(x=="(Z)") {'Less than half the rounding unit.'}else
                                                                {''})),
                      person_entering='Larissa Jarvis',
                      data_entered='2017-01-27',
                      orig_var='Area harvested',
                      microdata='0',  #Is this microdata 0=no 1=yes
                      weight_corr='0', #Is this corrected by household weight 0=no 1=yes
                      cen_sur='cen' 
), stringsAsFactors = FALSE) 

#out$Value[is.na(out$Value)]<--9999
out$value<-as.numeric(out$value)

write.csv(out,paste(owd,file.out,sep='/'),row.names=FALSE)



# NA Not available.
# S Insufficient number of reports to establish an estimate.
# X Not applicable.
# Z Less than half the rounding unit.

#data.frame(rename(x_,c('variable' = 'Year')))
# D Withheld to avoid disclosing data for individual operations.

# test<-x_[ #x_$SECTOR_DESC=='CROPS'& 
#          #x$GROUP_DESC %in% c("FIELD CROPS","FRUIT & TREE NUTS","HORTICULTURE")&
#          #x_$CLASS_DESC=='ALL CLASSES'&
#          #x_$PRODN_PRACTICE_DESC == 'ALL PRODUCTION PRACTICES'&
#          #x_$UTIL_PRACTICE_DESC == 'ALL UTILIZATION PRACTICES'&
#          #x_$STATISTICCAT_DESC == 'AREA HARVESTED'&
#          #x_$UNIT_DESC =='ACRES'&
#          lapply(x_$DOMAINCAT_DESC,function(x)unlist(strsplit(x,"[(]")[[1]][1])) == 'AREA OPERATED: '& 
#          lapply(x_$DOMAINCAT_DESC,function(x)length(unlist(strsplit(x,"[(]")))) == 2,] 
# 
# unique(test[test$SHORT_DESC=='AG LAND, CROPLAND, HARVESTED - ACRES',"COMMODITY_DESC"])
# 


# CV Coefficient of variation. Available for the 2012 Census of Agriculture
# only. County-level CVs are generalized.
# D Withheld to avoid disclosing data for individual operations.
# GE Greater than or equal.
# GT Greater than
# H Coefficient of variation or generalized coefficient of variation is
# greater than or equal to 99.95 percent or the standard error is greater
# than or equal to 99.95 percent of the mean.
# L Coefficient of variation or generalized coefficient of variation is less
# than 0.05 percent or the standard error is less than 0.05 percent of
# the mean.
# LE Less than or equal.
# LT Less than.
# NA Not available.
# S Insufficient number of reports to establish an estimate.
# X Not applicable.
# Z Less than half the rounding unit.
