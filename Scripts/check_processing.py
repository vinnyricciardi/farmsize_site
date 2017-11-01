#!/usr/bin/python

import time
import pandas as pd
import numpy as np
import glob
import sys
import datetime as dt
# import matplotlib
# matplotlib.use('Agg')
# import seaborn as sns
# from matplotlib import pyplot as plt
import re

pd.set_option('display.max_columns', 500)
pd.set_option('display.max_rows', 500)


PATH = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/'
out = PATH + 'FarmSize_data_fullyProcessed.csv'

files = glob.glob(PATH + 'Processed_data/*.csv')
files.remove(PATH + 'Processed_data/pEthiopia_cropsByFarmsize_2015.csv')
files.remove(PATH + 'Processed_data/pEurope_crop_by_farmsize_2005-2013.csv')

processed_df = pd.read_csv(out)
processed = processed_df.copy()

fix = {'United States of America': 'USA',
       'Russian Federation': 'Russia',
       'United Republic of Tanzania': 'Tanzania',
       'Czechia': 'Czech Republic'}

processed['NAME_0'] = processed['NAME_0'].replace(fix)


country = []
error = []
subj = []

for file in files:

    check = pd.read_csv(file)

    check['subject'] = check['subject'].replace(['prod'], 'Production')
    check['subject'] = check['subject'].replace(['area'], 'Crop_area')  # Uruguay data required fix
    check['subject'] = check['subject'].replace(['Area'], 'Harvested_area')
    check['subject'] = check['subject'].replace(['Crop area'], 'Crop_area')  # Ethiopia
    check['subject'] = check['subject'].replace(['Planted area'], 'Planted_area')  # Peru
    check['subject'] = check['subject'].replace(['Cultivated area'], 'Cultivated_area')  # Albania
    check['subject'] = check['subject'].replace(['Harvested area'], 'Harvested_area')

    check.rename(columns=lambda x: x.replace('.', '_'), inplace=True)
    check.rename(columns=lambda x: x.replace(' ', '_'), inplace=True)
    names = check.NAME_0.unique()

    for name in names:

        tmp_check = check.loc[(check['NAME_0'] == name)]

        for subject in tmp_check['subject'].unique():

            print name
            tmp_check_sub = tmp_check.loc[(tmp_check['subject'] == subject)]
            tmp_check_sub = tmp_check_sub.loc[(~tmp_check_sub['Crop'].isnull()) &
                                              (~tmp_check_sub['Item_Code'].isnull())]
            tmp_processed = processed.loc[processed['NAME_0'] == name]

            psum = tmp_processed[subject].sum()
            csum = float(tmp_check_sub.value.sum())

            if csum < 0.1:
                erroramt = np.nan

            else:
                erroramt = float(psum) / csum

            country.append(name)
            error.append(erroramt)
            subj.append(subject)


df1 = pd.concat([pd.DataFrame(country, columns=['NAME_0']),
                pd.DataFrame(error, columns=['error']),
                pd.DataFrame(subj, columns=['subject'])], axis=1)

df1 = df1.dropna()

print df1.sort_values('error')
print df1['error'].mean()






##################################################
# to check weirdness above
#
# tmp = pd.read_csv(files[-1])
# tmp.head()
# len(tmp)
# tmp.rename(columns=lambda x: x.replace('.', '_'), inplace=True)
# tmp.rename(columns=lambda x: x.replace(' ', '_'), inplace=True)
# # tmp = tmp.query("Item_Code == Item_Code")
#
# tmp2 = processed.loc[(processed['NAME_0'] == 'USA') & (processed['NAME_1'] == 'Florida')]
# len(tmp2)
# tmp2.iloc[:20, 1:25]
# tmp2['Harvested_area'].sum() / tmp.value.sum()
#
#
#
# len(np.sort(processed.query("Production_fix == Production_fix").NAME_0.unique()))