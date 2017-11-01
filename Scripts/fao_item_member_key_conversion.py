# construct look up tables for FAO member key to Item_Cod

import pandas as pd
import re


def look_up(PATH='/file/', dataset='crops_primary_equivalent'):

    df = pd.read_csv(PATH)
    df = df.iloc[:, :-4]
    df['Description'] = df['Description'].str.replace('Default composition: ', '')
    string = df['Description'][1]

    cols = ['Member_key', 'value', 'Crop']
    out = pd.DataFrame(columns=cols)

    for i in xrange(1, len(df)):

        tmp = df['Description'].str.split('(\d+\s+)', expand=True).iloc[i, :].transpose()
        tmp = tmp.dropna()
        ix = df['Item Code'].iloc[i]

        for j, k in zip(range(1, len(tmp), 2), range(2, len(tmp)+1, 2)):

            code = tmp[j][:-1]
            item = tmp[k][:]
            lst = pd.DataFrame([ix, code, item]).transpose()
            lst.columns = cols
            out = pd.concat([out, lst])

    out['data'] = dataset
    return out


PATH1 = '/Users/Vinny_Ricciardi/Desktop/FAO_food_supply.csv'
PATH2 = '/Users/Vinny_Ricciardi/Desktop/FAO_CommodityBalance.csv'
tmp1 = look_up(PATH1, dataset='food')
tmp2 = look_up(PATH2, dataset='commodity')
tmp = pd.concat([tmp1, tmp2])
tmp.to_csv('/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/FAO_FoodBalance/FAOStat_Lookup_Codes_fix2.csv')
tmp.tail()



