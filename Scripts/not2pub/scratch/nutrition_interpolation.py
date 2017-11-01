#!/usr/bin/python

import pandas as pd
import numpy as np

# def inter(data, crop = 51.0, name = 'name', year = 1961, col='col'):
#
#     print('iter is running')
#
#     data = data.query("""
#     Item_Code == {} & NAME_0 == "{}" & year == {}""".format(crop, name, year))
#     data = data[col].interpolate(method='nearest')
#
#     return data
#
#
# def inter_run(data):
#
#     print('iter_run is running')
#
#     tmp1 = inter(data, crop=crops[0], name=names[0], year=years[0], col=cols[0])
#
#     for crop in crops[1:]:
#         for name in names[1:]:
#             for year in years[1:]:
#                 for col in cols[1:]:
#                     print(crop, name, year, col)
#                     tmp2 = inter(data, crop=crop, name=name, year=year, col=col)
#                     tmp1 = pd.concat([tmp1, tmp2])
#
#     return tmp1

def iter_run(data):

    names = data['NAME_0'].unique()
    data = data.iloc[:, 2:]
    cols = data.columns
    tmp1 = pd.DataFrame([], columns=cols)

    for name, num_n in zip(names, range(0, len(names))):

        tmp = data.query("""NAME_0 == "{}" """.format(name))
        crops = tmp['Item_Code'].unique()

        for crop, num_c in zip(crops, range(0, len(crops))):
            perc_n = round(num_n / float(len(names)), 2)
            perc_c = round(num_c / float(len(crops)), 2)
            print '{}.........{}.........{}'.format(perc_n, perc_c, name)

            tmp2 = tmp.query("Item_Code == {}".format(crop))
            tmp2 = np.array(tmp2)
            tmp2 = pd.DataFrame(tmp2)
            tmp2.columns = cols

            for col in cols[3:]:

                nan_check = float(np.mean(tmp2[col]))

                if nan_check > 0.0:
                    tmp2[col][0] = nan_check
                    tmp2[col] = tmp2[col].astype(float)
                    tmp2[col] = tmp2[col].interpolate(method='nearest', limit_direction='both')
                else:
                    tmp2[col] = tmp2[col]

            tmp1 = tmp1.append(tmp2)

    print len(tmp1.Item_Code.unique()) / float(len(df.Item_Code.unique()))
    print len(tmp1.NAME_0.unique()) / float(len(df.NAME_0.unique()))

    return tmp1



if __name__ == '__main__':
    df = pd.read_csv('/Users/Vinny_Ricciardi/Downloads/test_nuts.csv')
    df['NAME_0'] = df.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")
    df = iter_run(df)
    print(df.head())
    df.to_csv('/Users/Vinny_Ricciardi/Downloads/test_out_nuts.csv')