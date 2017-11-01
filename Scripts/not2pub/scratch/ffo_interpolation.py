#!/usr/bin/python

import pandas as pd
import numpy as np


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
    df = pd.read_csv('/Users/Vinny_Ricciardi/Downloads/test_ffo.csv')
    df['NAME_0'] = df.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")
    df = iter_run(df)
    print(df.head())
    df.to_csv('/Users/Vinny_Ricciardi/Downloads/test_out.csv')