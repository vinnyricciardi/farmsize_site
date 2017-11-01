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


# ------------------------------------ Main ------------------------------------

def main():

    startTime = time.time()
    PATH = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/'
    PATH_f = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/FaoStat/FAOSTAT/'
    path1 = PATH_f + 'Production_Crops_E_All_Data_(Normalized)_with_regions.csv'
    path2 = PATH + 'FAO_FoodBalance/ffo.csv'
    path3 = PATH + 'FAO_FoodBalance/nutrition.csv'
    path4 = PATH + 'FAO_FoodBalance/FAO_regional_lookup.csv'
    df_fao1, df_ffo1, df_nut1, df_regional1 = read_fao_data(path1, path2, path3, path4)
    df_fs1, files1, variables = compile_farmsize_data(PATH)
    df_fs2, df_fao2 = clean_data(df_fs1, df_fao1)
    df_fs3 = calc_production(df_fs2, df_fao2, variables, df_regional1)
    tmp_x, df_fao3 = clean_data(df_fs1, df_fao1, element='area')
    df_fs4 = calc_area(df_fs3, df_fao3)
    df_fs5 = feed_food_other(df_fs4, df_ffo1)
    df_fs6 = nutrients(df_fs5, df_nut1)


    print '{} countries have production estimates'.format(len(df_fs6.query("Production_fix > 0").NAME_0.unique()))
    df_fs6.to_csv(PATH + 'FarmSize_data_fullyProcessed.csv')

    tmp = df_fs6.loc[(df_fs6['Crop_area'] > 0.0) |
                     (df_fs6['Cultivated_area'] > 0.0) |
                     (df_fs6['Harvested_area'] > 0.0) |
                     (df_fs6['Planted_area'] > 0.0) |
                     (df_fs6['Production'] > 0.0)]

    unresolved = tmp['production_Food_kcal'].isnull().sum() / float(len(tmp))
    print "Could not convert {}% of data we had in crop area (or similar metric) " \
          "due to unresolved matching to FAO database".format(100 * round(unresolved, 2))

    has = tmp.NAME_0.unique()
    tmp2 = df_fs6.copy()
    tmp2['all_names'] = tmp2.NAME_0.isin(has)
    unresolved_names = tmp2.loc[tmp2['all_names'] == False].NAME_0.unique()
    len(has) + len(unresolved_names)
    print "The countries unresolved are: {}".format(unresolved_names)
    print "All countries in database: {}".format(np.sort(df_fs6['NAME_0'].unique()))
    print ('The script took {0} seconds!'.format(round(time.time() - startTime), 2))


# ------------------------------------ Read in data ------------------------------------
def compile_farmsize_data(PATH):
    """
    :param path: filepath to farm size data
    :param run: if should compile data from individual country files
    :param date_input: if run == False, input date of compiled file
    :return:
    """

    print('Compiling data')

    # Need to subset Europe to 2013
    tmp = pd.read_csv(PATH + 'Processed_data/pEurope_crop_by_farmsize_2005-2013.csv')
    tmp = tmp.loc[tmp['year'] == 2013]
    tmp.to_csv(PATH + 'Processed_data/pEurope_crop_by_farmsize_2013.csv')


    variables = ['Crop', 'Item.Code', 'NAME_0', 'NAME_1', 'NAME_2', 'NAME_3', 'es1', 'shpID',
                 'data_unit', 'fs_class_min', 'fs_class_max', 'cen_sur', 'microdata',
                 'year', 'subject', 'value', 'fs_proxy']
                 # 'weight_corr']  # TODO: The USA data does not contain this variable yet, will with next export

    files = glob.glob(PATH + 'Processed_data/*.csv')
    files.remove(PATH + 'Processed_data/pEthiopia_cropsByFarmsize_2015.csv')
    files.remove(PATH + 'Processed_data/pEurope_crop_by_farmsize_2005-2013.csv')
    files.remove(PATH + 'Processed_data/pIndia_crop_by_farmsize_2005.csv')

    data = pd.read_csv(files[0])
    data = data.loc[:, variables]

    for f in files[1:]:
        tmp = pd.read_csv(f)
        tmp = tmp.loc[:, variables]
        data = pd.concat([data, tmp])

    today = dt.date.today().strftime('%m%d%Y')
    data.to_csv(PATH + 'CropbyFarmsize_2_{}.csv'.format(today))

    print('Compiling data complete')

    variables[1] = 'Item_Code'

    return data, files, variables



def read_fao_data(path1, path2, path3, path4):
    """
    :param path1: fao yield data
    :param path2: fao nutrition data
    :param path3: fao food, feed, other data
    :return: data1, data2, data3 each corresponds to path1..3
    """

    paths = path1, path2, path3, path4

    glb = globals()

    for i in range(0, len(paths)):
        glb['data' + str(i+1)] = pd.read_csv(paths[i], low_memory=False)

    return data1, data2, data3, data4


# ---------------------------------- testing if all variables are in all files ----------------------------------
# Not all files have same variables, and spelling is not consistent

def check_variables_in_file(files, variables):
    """
    :param files: individual country files
    :param variables: variables to check if files contain
    :return: data contains files and variables missing. If empty, no missing variables.
    """
    # Todo: debug check_variables_in_file().

    flist = []  # file list
    vlist = []  # variable list
    tlist = []  # check

    for f in files[1:]:

        tmp = pd.read_csv(f)

        for i in variables:
            result = i in tmp.columns
            flist.append(f[95:-26])
            vlist.append(i)
            tlist.append(result)

    data = pd.DataFrame([flist, vlist, tlist]).transpose()
    data.columns = ['f', 'v', 'b']
    data['b'] = data['b'].astype(int)

    data = pd.pivot_table(data, values='b', columns='f')
    data = data.reset_index()
    print(data)
    data = data.query("b != 1.0")

    return data


# ------------------------------------ Clean data ------------------------------------
# Fix column headers to have no spaces or periods

def clean_data(data1, data2, element='yield'):
    """
    :param data1: farm size data
    :param data2: fao data
    :return: data1, data 2
    """

    dfs = [data1, data2]

    for i in dfs:
        i.rename(columns=lambda x: x.replace(' ', '_'), inplace=True)
        i.rename(columns=lambda x: x.replace('.', '_'), inplace=True)

    # Fix country names to match FAO spellings
    fix = {'USA':      'United States of America',
           'Russia':   'Russian Federation',
           'Tanzania': 'United Republic of Tanzania',
           'Czech Republic': 'Czechia'}

    data1['NAME_0'] = data1['NAME_0'].replace(fix)
    # try:
    data1['Item_Code'] = data1['Item_Code'].replace('-', np.nan)
    # except:
    #     pass

    # Fix variables list with underscores
    # variables[:] = [s.replace('.', '_') for s in variables]

    # Fix factors with spaces in df['subject']. Will become column headers later
    data1['subject'] = data1['subject'].str.replace(' ', '_')
    data1['subject'] = data1['subject'].replace(['prod'], 'Production')
    data1['subject'] = data1['subject'].replace(['area'], 'Crop_area')  # Uruguay data1 required fix
    data1['subject'] = data1['subject'].replace(['Area'], 'Harvested_area')
    data1['subject'] = data1['subject'].replace(['Crop area'], 'Crop_area')  # Ethipoia
    data1['subject'] = data1['subject'].replace(['Planted area'], 'Planted_area')  # Peru
    data1['subject'] = data1['subject'].replace(['Cultivated area'], 'Cultivated_area')  # Albania
    data1['subject'] = data1['subject'].replace(['Harvested area'], 'Harvested_area')
    data1['fs_class_max'] = np.where(data1['fs_class_max'] == np.nan, 2000,  data1['fs_class_max'])
    data1['fs_class_min'] = np.where(data1['fs_class_min'] == np.nan, 0.01,  data1['fs_class_min'])
    data1['shpID'] = np.where(data1['shpID'].isnull(), 'NULL999', data1['shpID'])

    # Extract key variables and harmonize names from df_fao
    if element is 'yield':

        data2 = data2.query("Element == 'Yield'")
        data2 = data2.loc[:, ['Area', 'Year', 'Value', 'Item_Code']]
        data2.columns = ['NAME_0', 'year', 'Yield_FAO', 'Item_Code']

    elif element is 'area':

        data2 = data2.query("Element == 'Area harvested'")
        data2 = data2.loc[:, ['Area', 'Year', 'Value', 'Item_Code']]
        data2.columns = ['NAME_0', 'year', 'Area_FAO', 'Item_Code']

    # Ensure Item_Codes and year are floats in all dfs
    data1['Item_Code'] = data1['Item_Code'].astype(float)
    data1['year'] = data1['year'].astype(float)
    data2['Item_Code'] = data2['Item_Code'].astype(float)
    data2['year'] = data2['year'].astype(float)

    return data1, data2


# ------------------------------------ Wide format farm size data ------------------------------------
# Need to make data into long form for all sensitivity analyses needs

def wide_format(data):
    """
    :param data: farm size data
    :param variables: variable list
    :return: data
    """

    data = data.loc[(~data['Crop'].isnull()) & (~data['Item_Code'].isnull())]

    data.head()
    del data['data_unit']
    variables = ['Crop',
                 'Item_Code',
                 'NAME_0',
                 'NAME_1',
                 'NAME_2',
                 'NAME_3',
                 'es1',
                 'shpID',
                 'fs_class_min',
                 'fs_class_max',
                 'cen_sur',
                 'microdata',
                 'fs_proxy',
                 'year']

    data = data.set_index(variables)
    t = pd.pivot_table(data,
                       index=data.index,
                       columns='subject',
                       values='value',
                       aggfunc=np.sum)
    t = t.reset_index()
    t = t.set_index(pd.MultiIndex.from_tuples(t['index']))
    t = t.reset_index()

    cols = ['Crop',
            'Item_Code',
            'NAME_0',
            'NAME_1',
            'NAME_2',
            'NAME_3',
            'es1',
            'shpID',
            'fs_class_min',
            'fs_class_max',
            'cen_sur',
            'microdata',
            'fs_proxy',
            'year',
            'ix',
            'Crop_area',
            'Cultivated_area',
            'Harvested_area',
            'Planted_area',
            'Production',
            'Yield']

    t.columns = cols
    del t['ix']


    return t


# ------------------------------------ Calculate production ------------------------------------
# Need to calculate production based on constant yields for data sources only containing:
# 'Cultivated area', 'Harvested Area', Crop area', 'Harvested area', 'Area', and 'Planted area'
# Note: 'Cultivated area', Crop area', and 'Planted area' are grouped to 'Sown area'
# Note: all EU data has 0 for no cropping area and ; for no data available

def calc_production(data1, data2, variables, regional_lookup):
    """
    :param data1: farm size data
    :param data2: fao yield data
    :param variables: variables
    :param regional_lookup: fao regional lookup table to match regions and countries
    :return: data1
    """
    ########################################
    # # for testing use
    # data1 = df_fs2.copy()
    # data2 = df_fao2.copy()
    # regional_lookup = df_regional1.copy()
    ########################################

    data1 = wide_format(data1)

    data2 = data2.sort_values(['NAME_0', 'Item_Code', 'year'])

    multi_index = pd.MultiIndex.from_product([data2['NAME_0'].unique(),
                                              data2['Item_Code'].unique(),
                                              data2['year'].unique()],
                                             names=['NAME_0', 'Item_Code', 'year'])

    data2 = data2.set_index(['NAME_0', 'Item_Code', 'year']).reindex(multi_index).reset_index()

    data2 = data2.set_index(['NAME_0', 'Item_Code', 'year'])
    data2 = data2.interpolate(method='linear',
                              axis=0,
                              limit_direction='both')

    data2 = data2.reset_index()

    regional_lookup = regional_lookup.loc[:, ['Country Group', 'Country']]
    regional_lookup.columns = ['Region', 'NAME_0']
    regions = ['Australia & New Zealand', 'Caribbean', 'Central America',
               'Central Asia', 'Eastern Africa', 'Eastern Asia',
               'Eastern Europe', 'Melanesia', 'Micronesia', 'Middle Africa',
               'Northern Africa', 'Northern America', 'Northern Europe',
               'Oceania', 'Polynesia', 'South America', 'South-Eastern Asia',
               'Southern Africa', 'Southern Asia', 'Southern Europe',
               'Western Africa', 'Western Asia', 'Western Europe']

    regional_lookup = regional_lookup[regional_lookup['Region'].isin(regions)]

    data3 = data2.copy()
    world_yields = data3[data3['NAME_0'] == 'World']
    regional_yields = data3[data3['NAME_0'].isin(regions)]  # regional_yields??

    world_yields.columns = ['World', 'Item_Code', 'year', 'World_Yield_FAO']
    regional_yields.columns = ['Region', 'Item_Code', 'year', 'Regional_Yield_FAO']

    data2 = pd.merge(data2, regional_lookup,
                     on='NAME_0',
                     how='left')

    data1['year'] = np.where(data1['year'] > 2013., 2013., data1['year'])

    data1 = pd.merge(data1, regional_lookup,
                     on='NAME_0',
                     how='left')

    data1 = pd.merge(data1, data2,
                     on=['Item_Code', 'NAME_0', 'year', 'Region'],
                     how='left')

    data1 = pd.merge(data1, regional_yields,
                     on=['Item_Code', 'Region', 'year'],
                     how='left')

    data1['World'] = 'World'
    data1 = pd.merge(data1, world_yields,
                     on=['Item_Code', 'World', 'year'],
                     how='left')
    data1 = data1.drop('World', 1)


    miss_prod = round(100 * data1['Production'].isnull().sum() / float(len(data1['Production'])), 2)
    print("{}% of sample's production estimates will be based on constant yield".format(miss_prod))
    print("Regional yields and country yields have a spearman rank correlation of: {}".format(
        data1['Regional_Yield_FAO'].corr(data1['Yield_FAO'], method='spearman')))
    print("Regional yields and country yields have a pearson r correlation of: {}".format(
        data1['Regional_Yield_FAO'].corr(data1['Yield_FAO'], method='pearson')))


    # Calculate production based on constant yields where there are only area values
    data1 = data1.fillna(-1)
    data1['Production_fix'] = np.where(data1['Production'] > 0.0,
                                       data1['Production'],

                                np.where((data1['Harvested_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                         data1['Harvested_area'] * data1['Yield_FAO'] * 0.0001,
                                         np.where((data1['Harvested_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                  data1['Harvested_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                  np.where((data1['Harvested_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                  data1['Harvested_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                  np.where((data1['Cultivated_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                           data1['Cultivated_area'] * data1['Yield_FAO'] * 0.0001,
                                                           np.where((data1['Cultivated_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                           data1['Cultivated_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                    np.where((data1['Cultivated_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                             data1['Cultivated_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                                    np.where((data1['Crop_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                             data1['Crop_area'] * data1['Yield_FAO'] * 0.0001,
                                                                             np.where((data1['Crop_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                             data1['Crop_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                                      np.where((data1['Crop_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                               data1['Crop_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                                                      np.where((data1['Planted_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                                               data1['Planted_area'] * data1['Yield_FAO'] * 0.0001,
                                                                                               np.where((data1['Planted_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                                               data1['Planted_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                                                        np.where((data1['Planted_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                                                 data1['Planted_area'] * data1['World_Yield_FAO'] * 0.0001,
                                                                                                                 np.nan)))))))))))))


    data1['Production_fix_regional_count'] = np.where(data1['Production'] > 0.0,
                                       data1['Production'],

                                np.where((data1['Harvested_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                         0,
                                         np.where((data1['Harvested_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                  1,
                                                  np.where((data1['Harvested_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                  2,

                                                  np.where((data1['Cultivated_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                           0,
                                                           np.where((data1['Cultivated_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                           1,
                                                                    np.where((data1['Cultivated_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                             2,

                                                                    np.where((data1['Crop_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                             0,
                                                                             np.where((data1['Crop_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                             1,
                                                                                      np.where((data1['Crop_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                               2,

                                                                                      np.where((data1['Planted_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                                               0,
                                                                                               np.where((data1['Planted_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                                               1,
                                                                                                        np.where((data1['Planted_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                                                 2,
                                                                                                                 np.nan)))))))))))))



    # Calculate production for all values based on constant yields
    data1['Production_constant'] = np.where((data1['Harvested_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                            data1['Harvested_area'] * data1['Yield_FAO'] * 0.0001,
                                            np.where((data1['Harvested_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                     data1['Harvested_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                     np.where((data1['Harvested_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                              data1['Harvested_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                     np.where((data1['Cultivated_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                              data1['Cultivated_area'] * data1['Yield_FAO'] * 0.0001,
                                                              np.where((data1['Cultivated_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                       data1['Cultivated_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                       np.where((data1['Cultivated_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                data1['Cultivated_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                                       np.where((data1['Crop_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                                data1['Crop_area'] * data1['Yield_FAO'] * 0.0001,
                                                                                np.where((data1['Crop_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                                         data1['Crop_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                                         np.where((data1['Crop_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                                  data1['Crop_area'] * data1['World_Yield_FAO'] * 0.0001,

                                                                                         np.where((data1['Planted_area'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                                                                  data1['Planted_area'] * data1['Yield_FAO'] * 0.0001,
                                                                                                  np.where((data1['Planted_area'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                                                                           data1['Planted_area'] * data1['Regional_Yield_FAO'] * 0.0001,
                                                                                                           np.where((data1['Planted_area'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                                                                    data1['Planted_area'] * data1['World_Yield_FAO'] * 0.0001,
                                                                                                                    np.nan))))))))))))
    data1 = data1.replace(-1.0, np.nan)
    data1['Production_fix_dummy'] = np.where((data1['Production'].isnull()) & (~data1['Production_fix'].isnull()), 1, 0)
    data1['Production_fix_dummy'] = np.where(data1['NAME_0'] == 'Uruguay', 1,
                                             np.where((data1['Production'].isnull()) & (~data1['Production_fix'].isnull()),
                                                      1, 0))

    tmp = data1.loc[data1['Production_fix_regional_count'] == 1]
    print 'regional yields were used for {}% of the data'.format(100 *
             round(len(tmp['Production_fix_regional_count']) /
                   float(len(data1['Production_fix_regional_count'])), 2))

    tmp = data1.loc[data1['Production_fix_regional_count'] == 2]
    print 'global yields were used for {}% of the data'.format(100 *
           round(len(tmp['Production_fix_regional_count']) /
                 float(len(data1['Production_fix_regional_count'])), 2,))

    return data1


# ------------------------------------ Calculate area ------------------------------------

def calc_area(data1, data2):
    """
    :param data1: farm size data
    :param data2: fao area data
    :param variables: variables
    :return: data1
    """

    data2 = data2.sort_values(['NAME_0', 'Item_Code', 'year'])

    multi_index = pd.MultiIndex.from_product([data2['NAME_0'].unique(),
                                              data2['Item_Code'].unique(),
                                              data2['year'].unique()],
                                             names=['NAME_0', 'Item_Code', 'year'])

    data2 = data2.set_index(['NAME_0', 'Item_Code', 'year']).reindex(multi_index).reset_index()

    data2 = data2.set_index(['NAME_0', 'Item_Code', 'year'])
    data2 = data2.interpolate(method='linear',
                              axis=0,
                              limit_direction='both')

    data2 = data2.reset_index()

    data1['year'] = np.where(data1['year'] > 2013., 2013, data1['year'])

    data1 = pd.merge(data1, data2,
                     on=['Item_Code', 'NAME_0', 'year'],
                     how='left')

    miss_prod = round(100 * data1['Harvested_area'].isnull().sum() / float(len(data1['Harvested_area'])), 2)
    print("{}% of sample's harvest area estimates will be based on constant yield".format(miss_prod))

    # Calculate production based on constant yields where there are only area values
    data1 = data1.fillna(-1)
    data1['Area_fix'] = np.where((data1['Production_fix'] > 0.0) & (data1['Harvested_area'] > 0.0),
                                 data1['Harvested_area'],

                                 np.where(data1['Area_FAO'] > 0.0,
                                          data1['Area_FAO'],

                                          np.where((data1['Production_fix'] > 0.0) & (data1['Yield_FAO'] > 0.0),
                                                   data1['Production_fix'] / data1['Yield_FAO'],

                                                   np.where((data1['Production_fix'] > 0.0) & (data1['Regional_Yield_FAO'] > 0.0),
                                                            data1['Production_fix'] / data1['Regional_Yield_FAO'],

                                                            np.where((data1['Production_fix'] > 0.0) & (data1['World_Yield_FAO'] > 0.0),
                                                                     data1['Production_fix'] / data1['World_Yield_FAO'],
                                                                     np.nan)))))

    data1 = data1.replace(-1.0, np.nan)

    return data1

# ------------------------------------ Calculate feed, food, other from production ------------------------------------ 

def feed_food_other(data1, data2):
    """
    :param data1: farm size data
    :param data2: fao feed, food, other data
    :return: data 1
    """
    data1['year'] = np.where(data1['year'] > 2013., 2013, data1['year'])

    data1 = pd.merge(data1, data2,
                     on=['Item_Code', 'NAME_0', 'year'],
                     how='left')

    names = ['perc_Feed', 'perc_Food', 'perc_Other', 'perc_Seed', 'perc_Waste', 'perc_Processing']

    for i in range(0, len(names)):
        data1['production_' + names[i][5:]] = data1[names[i]] * data1['Production_fix']
        data1['production_' + names[i][5:] + '_k'] = data1[names[i]] * data1['Production_constant']

    return data1


# ------------------------------------ Convert production to kcal ------------------------------------

def nutrients(data1, data2):
    """
    :param data1: farm size data
    :param data2: fao nutrient lookup table
    :return: data1
    """
    data1['year'] = np.where(data1['year'] > 2013., 2013, data1['year'])

    data1 = pd.merge(data1, data2,
                     on=['Item_Code', 'NAME_0', 'year'],
                     how='left')

    names = ['kcal', 'fat', 'protein']

    calc_vars = ['production_Feed', 'production_Feed_k',
                 'production_Food', 'production_Food_k',
                 'production_Other', 'production_Other_k',
                 'production_Seed', 'production_Seed_k',
                 'production_Waste', 'production_Waste_k',
                 'production_Processing',
                 'production_Processing_k']

    for name in names:
        for calc_var in calc_vars:
            data1[calc_var + '_' + name] = data1[name] * data1[calc_var]


    data1 = data1.drop(['Unnamed: 0_x', 'Unnamed: 0_y'], axis=1)

    # data1 = data1.drop(['perc_Feed', 'perc_Food', 'perc_Other', 'perc_Seed', 'perc_Waste', 'perc_Processing',
    #                 'Unnamed: 0_x', 'Unnamed: 0_y', 'kcal', 'fat', 'protein',
    #                 'Yield', 'Yield_FAO'], axis=1)  # May want to drop all of these variables in future

    return data1


# ------------------------------------ Run main ------------------------------------
if __name__ == '__main__':

    main()

