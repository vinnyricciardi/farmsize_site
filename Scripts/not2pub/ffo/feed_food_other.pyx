#!/usr/bin/python
# Goals:
# 1. Calculate feed, food, other percentages from FAO food balance sheets
# 2. Extract kcal, grams, protein, and fat conversion from FAO food balance sheets

import pandas as pd
import numpy as np
from datetime import datetime

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
    df_lookup = PATH_a + PATH_b + 'FAOStat_Lookup_Codes_fix.csv'

    # Run main
    df_nutrition, df_ffo, df_lookup = read_data(df_nutrition, df_ffo, df_lookup)
    df_nutrition1, df_ffo1 = clean_data(df_nutrition, df_ffo, df_lookup)
    df_nutrition2, df_ffo2 = extract_data(df_nutrition1, df_ffo1)
    nut = nutrients(df_nutrition2)
    ffo = feed_food_other(df_ffo2)

    print 'This script sans interpolation took {}'.format(datetime.now() - startTime)

    # Interpolate ffo and nut (takes a long time - should refactor in cython)
    ffo2 = iter_fillna(ffo, name_out='name_out')
    nut2 = iter_fillna(nut, name_out='name_out')

    # Save files
    nut.to_csv(PATH_a + PATH_b + 'nutrition.csv')
    ffo.to_csv(PATH_a + PATH_b + 'ffo.csv')

    print 'This script including interpolation took {}'.format(datetime.now() - startTime)


# ------------------------------------ Read in data ------------------------------------

def read_data(PATH1, PATH2, PATH3):

    print('Reading data')

    ffo_fao = pd.read_csv(PATH1)
    nut_fao = pd.read_csv(PATH2)
    look_up = pd.read_csv(PATH3)

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

    data.rename(columns = lambda x: x.replace(' ', '_'), inplace = True)
    data.rename(columns = lambda x: x.replace('.', '_'), inplace = True)
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
    data1['Element'] = data1['Element'].str.replace('Fat supply quantity \(g\/capita\/day\)', 'fat')
    data2['Element'] = data2['Element'].str.replace('Other uses', 'Other')
    data2['Element'] = data2['Element'].str.replace('Food supply quantity \(tonnes\)', 'Food')

    data3 = data3.loc[:, ['Member_key', 'value']]
    data3.columns = ['Member_key', 'Item_Code']
    data3['Member_key'] = data3['Member_key'].astype(float)
    data3['Item_Code'] = data3['Item_Code'].astype(float)

    data1 = pd.merge(data1, data3,
                     on = 'Member_key',
                     how = 'left')

    data1 = data1.loc[:, ['NAME_0', 'Element', 'year', 'Value', 'Item_Code', 'Member_key']]

    data2 = pd.merge(data2, data3,
                     on = 'Member_key',
                     how = 'left')

    data2 = data2.loc[:, ['NAME_0', 'Element', 'year', 'Value', 'Item_Code', 'Member_key']]

    missing_dict = {'data1': data1.Item_Code,
                    'data2': data2.Item_Code}

    for key, value in missing_dict.iteritems():
        missing(value, key)

    print('Cleaning data complete')

    return data1, data2


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

    elements = ['Production', 'Waste', 'Processing', 'Food', 'Feed', 'Seed', 'Other']

    for i in elements:
        glb[i] = data2.query("Element == '{}'".format(i))
        glb[i] = glb[i].loc[:, ['NAME_0', 'Item_Code', 'year', 'Value', 'Element']]


    data2 = pd.concat([Production, Waste, Processing, Food, Feed, Seed, Other])
    data2 = data2.dropna()

    missing_dict = {'kcal':       kcal.Value,
                    'protein':    protein.Value,
                    'fat':        fat.Value,
                    'Production': Production.Value,
                    'Waste':      Waste.Value,
                    'Processing': Processing.Value,
                    'Food':       Food.Value,
                    'Feed':       Feed.Value,
                    'Seed':       Seed.Value,
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
                           index = ['NAME_0', 'Item_Code', 'year'],
                           values = 'Value',
                           columns = 'Element')

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

    names = ['Waste', 'Processing', 'Food', 'Feed', 'Seed']
    data['total'] = np.nansum(data.loc[:, names], axis=1)

    for name in names:
        print name
        data['perc_' + name] = data[name] / data['total']

    data = data.loc[:, ['NAME_0',
                        'Item_Code',
                        'year',
                        'perc_Feed',
                        'perc_Food',
                        'perc_Other',
                        'perc_Processing',
                        'perc_Seed',
                        'perc_Waste']]


    # TODO: Allocate oil crops according to Cassidy et al. 2013 weights in supplemental material table S1

    print('Feed, food, and other complete')

    return data


# def iter_run(data, data_name='ffo'):
#     """
#     Interpolates via nearest, both directions for missing data
#     :param data: ffo or nut
#     :param data_name: 'ffo' or 'nut'
#     :return: data
#     """
#
#     print('Interpolating data')
#
#     names = data['NAME_0'].unique()
#     # data = data.iloc[:, 2:]
#     cols = data.columns
#     tmp1 = pd.DataFrame([], columns=cols)
#
#     for name, num_n in zip(names, range(0, len(names))):
#
#         tmp = data.query("""NAME_0 == "{}" """.format(name))
#         crops = tmp['Item_Code'].unique()
#
#         for crop, num_c in zip(crops, range(0, len(crops))):
#             perc_n = round(num_n / float(len(names)), 2)
#             perc_c = round(num_c / float(len(crops)), 2)
#             print '{}.........{}.........{}'.format(perc_n, perc_c, name)
#
#             tmp2 = tmp.query("Item_Code == {}".format(crop))
#             tmp2 = np.array(tmp2)
#             tmp2 = pd.DataFrame(tmp2)
#             tmp2.columns = cols
#
#             for col in cols[3:]:
#
#                 nan_check = float(np.mean(tmp2[col]))
#
#                 if nan_check > 0.0:
#                     tmp2[col][0] = nan_check
#                     tmp2[col] = tmp2[col].astype(float)
#                     tmp2[col] = tmp2[col].interpolate(method='nearest',
#                                                       limit_direction='both')
#                 else:
#                     tmp2[col] = tmp2[col]
#
#             tmp1 = tmp1.append(tmp2)
#
#     check_i = round(len(tmp1.Item_Code.unique()) / float(len(data.Item_Code.unique())), 2)
#     check_n = round(len(tmp1.NAME_0.unique()) / float(len(data.NAME_0.unique())), 2)
#
#     print('{}% of crops and {}% of countries are in the dataframe'.format(check_i, check_n))
#     print('Interpolating data complete')
#
#     return tmp1


def iter_fillna(data, name_out='name_out'):

    names = data['NAME_0'].unique()
    items = data['Item_Code'].unique()
    cols = data.columns

    tmp1 = data.as_matrix()

    tmp1 = tmp1[:, 1:]
    loop1 = np.empty([len(tmp1), 9])

    for n in xrange(len(names)):

        print names[n]

        tmp2 = tmp1[(tmp1[:, 0] == names[n])]
        loop2 = np.empty([len(tmp2), 9])

        for i in xrange(len(items)):

            tmp2 = tmp2[(tmp2[:, 1] == items[i])]

            data = tmp2[:, 3:]
            check = np.array(data.ravel(), dtype='float64')

            if np.count_nonzero(~np.isnan(check)) > 0:

                ixs = tmp2[:, :3]
                loop3 = np.empty([len(data), 6])

                for c in xrange(data.shape[1]):

                    loop = data[:, c: c+1]  # to be made into loop

                    if data[0, c: c+1] == np.nan is False:
                        mean_fill = np.nanmean(data[:, c:c+1])
                        np.put(loop, 0, mean_fill)
                    else:
                        pass

                    loop = loop.ravel()
                    loop = np.array(loop, dtype='float64')

                    if np.count_nonzero(~np.isnan(loop)) > 0:

                        mask = np.isnan(loop)
                        loop[mask] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), loop[~mask])
                    else:
                        pass

                    loop3[:, c:c+1] = loop.reshape(len(loop), 1)
                    out3 = np.concatenate((ixs, loop3), axis=1)
            else:
                pass

            out2 = np.concatenate((out3, loop2), axis=0)

        out1 = np.concatenate((out2, loop1), axis=0)

    return out1
# ------------------------------------ Run main ------------------------------------

if __name__ == '__main__':

    main()

