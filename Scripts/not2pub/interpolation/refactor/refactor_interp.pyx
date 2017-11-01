
import pandas as pd
import numpy as np
import time


def iter_fillna(data, name_out='name_out'):

    start = time.time()

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

    pd.DataFrame(out1).to_csv('/Users/Vinny_Ricciardi/Downloads/{}_out.csv'.format(name_out))

    end = time.time()
    print(end - start)


def main():

    PATH_a = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/'
    PATH_b = 'Farm_Size/Data/FAO_FoodBalance/'

    nut = pd.read_csv(PATH_a + PATH_b + 'nutrition.csv')
    ffo = pd.read_csv(PATH_a + PATH_b + 'ffo.csv')

    ffo['NAME_0'] = ffo.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")
    nut['NAME_0'] = nut.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")

    dfs = {'ffo': ffo,
           'nut': nut}

    for key, value in dfs.iteritems():
        iter_fillna(value, name_out=key)


if __name__ == '__main__':

    main()
