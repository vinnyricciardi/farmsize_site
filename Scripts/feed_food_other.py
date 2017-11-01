#!/usr/bin/python
# Goals:
# 1. Calculate feed, food, other percentages from FAO food balance sheets
# 2. Extract kcal, grams, protein, and fat conversion from FAO food balance sheets

import pandas as pd
import numpy as np
from datetime import datetime
# from matplotlib import pyplot as plt

# ------------------------------------ Main ------------------------------------

def main():

startTime = datetime.now()

# Paths
PATH_a = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/'
PATH_b = 'Farm_Size/Data/FAO_FoodBalance/'
PATH_c = 'FaoStat/FAOSTAT/'

# Data
df_nutrition = PATH_a + PATH_c + 'FoodSupply_Crops_E_All_Data_(Norm).csv'
df_ffo = PATH_a + PATH_c + 'CommodityBalances_Crops_E_All_Data_(Norm).csv'
df_lookup = PATH_a + PATH_b + 'FAOStat_Lookup_Codes_fix2.csv'

# Run main
df_nutrition, df_ffo, df_lookup = read_data(path1=df_nutrition, path2=df_ffo, path3=df_lookup)
df_nutrition1, df_ffo1 = clean_data(df_nutrition, df_ffo, df_lookup)
df_nutrition2, df_ffo2 = extract_data(df_nutrition1, df_ffo1)
nut = nutrients(df_nutrition2)
ffo = feed_food_other(df_ffo2)
nut2 = iter_fill(nut)
ffo2 = iter_fill(ffo)

# # Save files
# nut2.to_csv(PATH_a + PATH_b + 'nutrition.csv')
# ffo2.to_csv(PATH_a + PATH_b + 'ffo.csv')

print 'This script including took {} seconds'.format(datetime.now() - startTime)

    return ffo2, nut2


# ------------------------------------ Read in data ------------------------------------

def read_data(path1='/path/', path2='/path/', path3='/path/'):

    print('Reading data')

    ffo_fao = pd.read_csv(path1)
    nut_fao = pd.read_csv(path2)
    look_up = pd.read_csv(path3)

    print('Reading data complete')

    return ffo_fao, nut_fao, look_up

# Todo: check look up table. Seems to be missing Item_Codes to:
# array([ 2501.,  2899.,  2901.,  2903.,  2941.,  2905.,  2907.,  2908.,
#         2909.,  2911.,  2912.,  2913.,  2914.,  2918.,  2919.,  2922.,
#         2923.,  2924.,  2943.,  2945.,  2946.,  2949.,  2948.,  2960.,
#         2961.,  2928.])

# ------------------------------------ Clean data ------------------------------------
def missing(value, name):
    """
    Calculates percent missing per input for diagnostics
    :param value: variable
    :param name: variable name
    :return: print out of percent missing per variable input
    """

    value_missing = round(100 * float(value.isnull().sum()) / float(len(value)), 2)

    if value_missing > 0.0:
        print('{} % of {} are missing'.format(value_missing, name))


def clean_data_helper(data):
    """
    Consolidates cleaning file
    :param data: data input
    :return: data
    """
    data = data.loc[data['Value'] > 0.0]
    data.rename(columns=lambda x: x.replace(' ', '_'), inplace=True)
    data.rename(columns=lambda x: x.replace('.', '_'), inplace=True)
    data['Member_key'] = data['Item_Code'].astype(float)
    data['year'] = data['Year'].astype(float)

    data = data.loc[:, ['Country', 'Element', 'year', 'Value', 'Member_key']]
    data.columns = ['NAME_0', 'Element', 'year', 'Value', 'Member_key']

    return data


def clean_data(data1, data2, data3):
    """
    Cleans data, ensures proper format
    :param data1: nutrients
    :param data2: feed, food, other
    :param data3: member_key to item_key lookup table
    :return: data1, data2,
    """

    print('Cleaning data')

    data1 = clean_data_helper(data1)
    data2 = clean_data_helper(data2)

    data1['Element'] = data1['Element'].str.replace('Food supply \(kcal\/capita\/day\)', 'kcal')
    data1['Element'] = data1['Element'].str.replace('Protein supply quantity \(g\/capita\/day\)', 'protein')
    data1['Element'] = data1['Element'].str.replace('Food supply quantity \(tonnes\)', 'Food')
    data1['Element'] = data1['Element'].str.replace('Fat supply quantity \(g\/capita\/day\)', 'fat')
    data2['Element'] = data2['Element'].str.replace('Other uses', 'Other')
    data2['Element'] = data2['Element'].str.replace('Food supply quantity \(tonnes\)', 'Food')

    data3['Member_key'] = data3['Member_key'].astype(float)
    data3['Item_Code'] = data3['value'].astype(float)

    # data3a = data3.query("data == 'food'")
    data3a = data3.loc[data3['data'] == 'food']
    data3a = data3a.loc[:, ['Member_key', 'value']]
    data3a.columns = ['Member_key', 'Item_Code']

    data1 = pd.merge(data1, data3a,
                     on='Member_key',
                     how='left')

    data1 = data1.loc[:, ['NAME_0', 'Element', 'year', 'Value', 'Item_Code', 'Member_key']]

    data3b = data3.query("data == 'commodity'")
    data3b = data3b.loc[:, ['Member_key', 'value']]
    data3b.columns = ['Member_key', 'Item_Code']

    data2 = pd.merge(data2, data3b,
                     on='Member_key',
                     how='left')

    data2 = data2.loc[:, ['NAME_0', 'Element', 'year', 'Value', 'Item_Code', 'Member_key']]

    missing_dict = {'data1': data1.Item_Code,
                    'data2': data2.Item_Code}

    for key, value in missing_dict.iteritems():
        missing(value, key)

    print('Cleaning data complete')

    return data1, data2

# debug
# clean_data(df_nutrition, df_ffo, df_lookup)
# data3 = df_lookup
#

# ------------------------------------ Extract data ------------------------------------
# Feed
# Data refer to the quantity of the commodity in question available for feeding to the livestock
# and poultry during the reference period, whether domestically produced or imported.

# Food
# Data refer to the total amount of the commodity available as human food during the reference period.
# Data include the commodity in question, as well as any commodity derived therefrom as a result of
# further processing. Food from maize, for example, comprises the amount of maize, maize meal and any
# other products derived therefrom available for human consumption. Food from milk relates to the
# amounts of milk as such, as well as the fresh milk equivalent of dairy products.

# Losses/Waste
# Amount of the commodity in question lost through wastage (waste) during the year at all stages between
# the level at which production is recorded and the household, i.e. storage and transportation. Losses
# occurring before and during harvest are excluded. Waste from both edible and inedible parts of the
# commodity occurring in the household is also excluded. Quantities lost during the transformation of
# primary commodities into processed products are taken into account in the assessment of respective
# extraction/conversion rates. Distribution wastes tend to be considerable in countries with hot humid
# climate, difficult transportation and inadequate storage or processing facilities. This applies to the
# more perishable foodstuffs, and especially to those which have to be transported or stored for a long
# time in a tropical climate. Waste is often estimated as a fixed percentage of availability, the latter
# being defined as production plus imports plus stock withdrawals.

# Other uses
# Data refer to quantities of commodities used for non-food purposes, e.g. oil for soap. In order not to
# distort the picture of the national food pattern quantities of the commodity in question consumed mainly
# by tourists are included here (see also "Per capita supply"). In addition, this variable covers pet food.

# Seed
# Data include the amounts of the commodity in question set aside for sowing or planting (or generally for
# reproduction purposes, e.g. sugar cane planted, potatoes for seed, eggs for hatching and fish for bait,
# whether domestically produced or imported) during the reference period. Account is taken of double or
# successive sowing or planting whenever it occurs. The data of seed include also, when it is the case, the
#  quantities necessary for sowing or planting the area relating to crops harvested green for fodder or for
#  food.(e.g. green peas, green beans, maize for forage)  Data for seed element are stored in tonnes (t).
# Whenever official data were not available, seed figures have been estimated either as a percentage of supply
# (e.g. eggs for hatching) or by multiplying a seed rate with the area under the crop of the subsequent year.

def extract_data(data1, data2):
    """
    Extracts feed, food, other, etc. and kcal, protein, fat conversions
    :param data1: nutrients
    :param data2: feed, food, other
    :return: data1, data2
    """

    print('Extracting data')

    glb = globals()

    elements = ['kcal', 'protein', 'fat']

    for i in elements:
        glb[i] = data1.query("Element == '{}'".format(i))
        glb[i] = glb[i].loc[:, ['NAME_0', 'Item_Code', 'year', 'Value', 'Element']]

    data1 = pd.concat([kcal, protein, fat])
    data1 = data1.dropna()

    glb = globals()

    elements = ['Production', 'Waste', 'Food', 'Feed', 'Seed', 'Processing', 'Other']

    for i in elements:
        glb[i] = data2.query("Element == '{}'".format(i))
        glb[i] = glb[i].loc[:, ['NAME_0', 'Item_Code', 'year', 'Value', 'Element']]


    data2 = pd.concat([Production, Waste, Food, Feed, Seed, Processing, Other])
    data2 = data2.dropna()

    missing_dict = {'kcal':       kcal.Value,
                    'protein':    protein.Value,
                    'fat':        fat.Value,
                    'Production': Production.Value,
                    'Waste':      Waste.Value,
                    'Food':       Food.Value,
                    'Feed':       Feed.Value,
                    'Seed':       Seed.Value,
                    'Processing': Processing.Value,
                    'Other':      Other.Value}

    for key, value in missing_dict.iteritems():
        missing(value, key)

    print('Extracting data complete')

    return data1, data2


# ------------------------------------ Calculate percentages ------------------------------------

def wide_form(data):
    """
    Recasts data into wide format
    :param data: data from extract data
    :return: data
    """

    print('Recasting data to wide form')

    pivot = pd.pivot_table(data,
                           index=['NAME_0', 'Item_Code', 'year'],
                           values='Value',
                           columns='Element')

    pivot = pivot.reset_index()

    print('Recasting data to wide form complete')

    return pivot


def nutrients(data):
    """
    Creates nutrients conversion table
    :param data: data from wide form
    :return: data
    """

    print('Nutrients')

    data = wide_form(data)

    data = data.loc[:, ['NAME_0',
                        'Item_Code',
                        'year',
                        'kcal',
                        'fat',
                        'protein']]

    missing_dict = {'kcal':       data.kcal,
                    'protein':    data.protein,
                    'fat':        data.fat}

    for key, value in missing_dict.iteritems():
        missing(value, key)

    print('Nutrients complete')

    return data


def feed_food_other(data):
    """
    Creates feed, food, other, conversion table
    :param data: data from wide form
    :return: data
    """

    print('Feed, food, and other')

    data = wide_form(data)

    # names = ['Waste', 'Food', 'Feed', 'Seed']
    names = ['Feed', 'Food', 'Seed', 'Waste', 'Processing', 'Other']
    data['total'] = np.nansum(data.loc[:, names], axis=1)

    for name in names:
        print name
        data['perc_' + name] = data[name] / data['total']

    data = data.loc[:, ['NAME_0',
                        'Item_Code',
                        'year',
                        'perc_Feed',
                        'perc_Food',
                        'perc_Seed',
                        'perc_Waste',
                        'perc_Processing',
                        'perc_Other']]


    # TODO: Allocate oil crops according to Cassidy et al. 2013 weights in supplemental material table S1

    print('Feed, food, and other complete')

    return data


# ------------------------------------ Fill data gaps ------------------------------------

def iter_fill(data):

    print 'Interpolating missing data'

    data = data.sort_values(['NAME_0', 'Item_Code', 'year'])

    multi_index = pd.MultiIndex.from_product([data['NAME_0'].unique(),
                                              data['Item_Code'].unique(),
                                              data['year'].unique()],
                                             names=['NAME_0', 'Item_Code', 'year'])

    data = data.set_index(['NAME_0', 'Item_Code', 'year']).reindex(multi_index).reset_index()

    org = data.set_index(['NAME_0', 'Item_Code', 'year'])
    new = org.interpolate(method='linear',
                          axis=0,
                          limit_direction='both')

    new = new.reset_index()

    print 'Interpolating missing data complete'

    return new


def check_interp(d='nut'):

    # note: hard coded from def(main) for quick check

    if d is 'nut':
        org = nut.copy()
        new = nut2.copy()
        # names = org.query("Item_Code == 15. & kcal != kcal").NAME_0.unique()
        print org.isnull().sum()
        print new.isnull().sum()

        org = org.query("Item_Code == 15. & NAME_0 == 'Cambodia'")
        new = new.query("Item_Code == 15. & NAME_0 == 'Cambodia'")

        plt.plot(new['year'], new['kcal'], 'ko-', label='interpolated')
        plt.plot(org['year'], org['kcal'], 'ro-', label='original')
        plt.legend()

    else:
        org = ffo.copy()
        new = ffo2.copy()
        print org.isnull().sum()
        print new.isnull().sum()

        org = org.query("Item_Code == 1277. & NAME_0 == 'Zimbabwe'")
        new = new.query("Item_Code == 1277. & NAME_0 == 'Zimbabwe'")

        plt.plot(new['year'], new['perc_Food'], 'ko-', label='interpolated')
        plt.plot(org['year'], org['perc_Food'], 'ro-', label='original')
        plt.legend()



# ------------------------------------ Run main ------------------------------------

if __name__ == '__main__':

    main()

