
import warnings
warnings.filterwarnings('ignore')
import subprocess
import seaborn as sns
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import matplotlib.gridspec as gridspec
from matplotlib import colors
from matplotlib import lines
import copy
from collections import OrderedDict
from pivottablejs import pivot_ui  # may have to use: python setup.py install --user
import scipy.stats as st
# import statsmodels.stats.api as sms
from scipy.stats import linregress
import matplotlib.patches as patches
from sklearn import linear_model
# import statsmodels.api as sm
# import statsmodels.formula.api as smf
import math
import itertools
from collections import OrderedDict
import matplotlib as mpl
from scipy.stats.stats import pearsonr
from scipy.stats.stats import spearmanr
import geopandas as gpd
import matplotlib.patches as mpatches
from matplotlib.collections import PatchCollection
# from scikits import bootstrap

plt.style.use('seaborn-muted')
pd.set_option('display.max_columns', 500)
pd.set_option('display.max_rows', 500)


def read_data_init(path):
    data = pd.read_csv(path, low_memory=False)
    data['fs_class_max'] = np.where(data['fs_class_max'].isnull(), 10000, data['fs_class_max'])
    data['Farm_Sizes'] = pd.cut(data['fs_class_max'],
                                bins=[0, 1, 2, 5, 10, 20, 50,
                                      100, 200, 500, 1000, 100000])

    data = data.replace(0.0, np.nan)  # there were many zero values

    return data

print 'reading files'

try:
    PATH = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/FarmSize_data_fullyProcessed.csv'
    data_orig = read_data_init(PATH)
except:
    PATH = '/home/vinny_ricciardi/Documents/Data_Library_SSD/Survey/Global/Farm_Size/Data/FarmSize_data_fullyProcessed.csv'
    data_orig = read_data_init(PATH)

# data_orig['Farm_Sizes'] = data_orig['Farm_Sizes'].astype(str)

data_orig['production_kcal'] = data_orig['Production_fix'] * data_orig['kcal']
data_orig['Item_Code_ix'] = data_orig['Item_Code'].copy()
world = gpd.read_file(
    '/home/vinny_ricciardi/Documents/Data_Library_SSD/Survey/Global/Farm_Size/Data/Shapefile/FSize.shp')
world = world.query("geometry == geometry")
world = world.to_crs({'init': 'epsg:3410'})
world['area'] = world['geometry'].area * 0.0001  # converts m**2 to ha
world = world.loc[:, ['shpID', 'area']]
data_orig = pd.merge(data_orig, world, on='shpID', how='left')



t = pd.pivot_table(data_orig, index=['Farm_Sizes'], values='NAME_0', aggfunc='count').reset_index()
t['perc'] = 100* t['NAME_0'] / t['NAME_0'].sum()
large_obs = round(t.iloc[-1, -1], 2)

# richness1 = pd.pivot_table(data_orig,
#                           index=['shpID', 'Farm_Sizes'],  # 'NAME_0
#                           values='Item_Code',
#                           aggfunc=lambda x: len(x.unique())).reset_index()
#
# richness2 = pd.pivot_table(richness1,
#                            index=['shpID'],  # 'NAME_0
#                            values='Item_Code',
#                            aggfunc=np.nansum).reset_index()
#
# richness = pd.merge(richness1, richness2, on='shpID', how='outer')
# richness = pd.merge(richness, world, on='shpID', how='left')
#
# richness['Item_Code_perc'] = richness['Item_Code_x'] / richness['Item_Code_y']
#
fs_order = ['(0, 1]', '(1, 2]', '(2, 5]', '(5, 10]', '(10, 20]',
            '(20, 50]', '(50, 100]', '(100, 200]', '(200, 500]',
            '(500, 1000]', '(1000, 100000]']

dictionary = dict(zip(fs_order, range(0, len(fs_order))))  # used to circumvent categorical indexing
# richness['ix'] = richness['Farm_Sizes'].map(dictionary)
#
#
# r, p = spearmanr(richness['ix'], richness['Item_Code_perc'])
#
# fig = plt.figure(figsize=[10, 5])
# ax = fig.add_subplot(111)
# y = richness['Item_Code_perc'] * 100
# x = richness['ix']
# pv = pd.pivot_table(richness, index='ix', values='Item_Code_perc', aggfunc=np.nanmean).reset_index()
# y = pv['Item_Code_perc']*100
# se = np.sqrt((y - y.mean())**2)
# se = np.mean(se)
# h = y + se
# l = y - se
#
# ax.fill_between(pv['ix'], h, l, color='grey', alpha=0.2)
# ax.plot(pv['ix'], pv['Item_Code_perc']*100, '-r', alpha=1)
#
# ax.set_xlabel('Farm Sizes (ha)')
# ax.set_xticks(np.arange(0, 10))
# ax.set_xticklabels([x[1:-1] for x in fs_order], rotation=45)
# ax.set_ylabel('Percent species richness \nsum richness / admin area\n')
# ax.set_title('Species Richness\nSpearmanr: {} (p = {})\n'.format(round(r, 2), round(p, 2)), fontsize=14)
#
# plt.show()


def area_richness_parallel(farmsizes=[0, 2], boots=2, grouped=False):
    farmsizes = range(farmsizes[0], farmsizes[-1])

    tmp = data_orig.copy()
    tmp['ix'] = tmp['Farm_Sizes'].map(dictionary)

    if grouped is True:

        tmp['Farm_Sizes'] = np.where(tmp['ix'] >= 7,
                                     '(100, 100000]',
                                     np.where(tmp['ix'] <= 3,
                                              '(0, 10]',
                                              '(10, 100]'))

        tmp = tmp.loc[(tmp['Farm_Sizes'] == '(100, 100000]') |
                      (tmp['Farm_Sizes'] == '(0, 10]') |
                      (tmp['Farm_Sizes'] == '(10, 100]')]

        fs_order = ['(0, 10]',
                    '(10, 100]',
                    '(100, 100000]']

    else:

        fs_order = ['(0, 1]', '(1, 2]', '(2, 5]', '(5, 10]', '(10, 20]',
                    '(20, 50]', '(50, 100]', '(100, 200]', '(200, 500]',
                    '(500, 1000]', '(1000, 100000]']

    variables = ['Farm_Sizes', 'Item_Code', 'shpID', 'area']
    tmp = tmp.loc[:, variables]
    tmp = tmp.loc[tmp['area'] > 0.]
    tmp = tmp[variables].drop_duplicates()

    for f in xrange(farmsizes[0], farmsizes[-1]):

        print fs_order[f]
        items = []

        tmp1 = tmp.loc[tmp['Farm_Sizes'] == fs_order[f]]

        grouped = tmp1.groupby(['Farm_Sizes', 'shpID', 'area'])
        out = grouped.aggregate(lambda x: tuple(x)).reset_index()

        for i in xrange(0, boots):

            out2 = out.iloc[np.random.permutation(len(out))]
            out2 = out2.reset_index(drop=True)

            for j in xrange(0, len(out2) - 1):

                item = list(out2['Item_Code'][j])

                if j is 0:
                    item = item

                else:
                    item = list(item + items)

                nitem = list(out2['Item_Code'][j + 1])
                items = list(item + nitem)

                out2.at[j, 'Item_Code'] = items

            out2['cumsum_area_{}'.format(i)] = out2['area'].cumsum()
            out2['cumsum_items_{}'.format(i)] = out2['Item_Code'].apply(lambda x: len(set(x)))

            out2 = out2.loc[:, ['Farm_Sizes',
                                'shpID',
                                'cumsum_area_{}'.format(i),
                                'cumsum_items_{}'.format(i)]]

            if i is 0:

                out3 = out2.copy()

            else:

                out3 = pd.merge(out3, out2, on=['Farm_Sizes', 'shpID'], how='outer')

        if f is farmsizes[0]:

            out4 = out3.copy()

        else:

            out4 = pd.concat([out4, out3], axis=0)

    return out4

def plot_cumulative_richness(data=None, fs_range=3, boots=1, ax=None, grouped=True):
    if ax is None:

        fig = plt.figure(figsize=[15, 5])
        ax = fig.add_subplot(131)
        ax2 = fig.add_subplot(132)
        ax3 = fig.add_subplot(133)

    else:
        ax = ax

    if grouped is True:

        fs_order = ['(0, 10]',
                    '(10, 100]',
                    '(100, 100000]']

        color_p = 'Set2'
        color_n = 3
        alpha = 0.1

    else:

        fs_order = ['(0, 1]', '(1, 2]', '(2, 5]', '(5, 10]', '(10, 20]',
                    '(20, 50]', '(50, 100]', '(100, 200]', '(200, 500]',
                    '(500, 1000]', '(1000, 100000]']

        color_p = 'BuPu_r'
        color_n = 11
        alpha = 0.05

    for i in xrange(len(fs_order)):

        x = data.loc[data['Farm_Sizes'] == fs_order[i]]

        for c in xrange(boots):

            y = x.sort_values('cumsum_area_{}'.format(c)).reset_index(drop=True)
            df_y = y.loc[:, ['cumsum_area_{}'.format(c), 'cumsum_items_{}'.format(c)]]
            df_y = df_y.loc[(df_y['cumsum_items_{}'.format(c)] > 100) &
                            (df_y['cumsum_items_{}'.format(c)] < 140)]

            if c is 0:
                out = df_y.copy()
            else:
                out = pd.concat([out, df_y], axis=1)

            ax.plot(y['cumsum_area_{}'.format(c)][:-1],
                    y['cumsum_items_{}'.format(c)][:-1], '-',
                    color=sns.color_palette(color_p, color_n)[i],
                    linewidth=0.5,
                    alpha=alpha)

        out['areas'] = out.filter(regex='area').mean(axis=1)
        out['items'] = out.filter(regex='items').mean(axis=1)

        xlim_max_i = out['areas'].max()

        if i is 0:
            xlim_max = xlim_max_i
        else:
            if xlim_max < xlim_max_i:
                xlim_max = xlim_max
            else:
                xlim_max = xlim_max_i

        out = out.loc[(out['items'] > 100) & (out['items'] < 140)]
        out = out.loc[:, ['areas', 'items']]
        out['Farm_Sizes'] = fs_order[i]

        if i is 0:
            out2 = out.copy()

        else:
            out2 = pd.concat([out2, out], axis=0)

    for i in xrange(len(fs_order)):
        x = out2.loc[out2['Farm_Sizes'] == fs_order[i]]

        ax.plot(x['areas'][:-1],
                x['items'][:-1],
                color=sns.color_palette(color_p, color_n)[i],
                alpha=1.,
                linewidth=1)

    ax.set_xlabel('Cumulative area (10e9 ha)')
    ax.set_ylabel('Cumulative species richness')
    #     ax.set_xlim([ax.get_xlim()[0], xlim_max])
    # ax.set_xlim([out['areas'].min(), xlim_max])
    #     ax.set_ylim([out['items'].min(), out['items'].max()])

    if ax is None:

        fig.tight_layout()
        return plt.show()

    else:

        return ax


print 'bootstrapping'

boots = 100
f_range = 12
t = area_richness_parallel(farmsizes=[0, f_range], boots=boots, grouped=False)
# t = area_richness_parallel(farmsizes=[0, 4], boots=boots, grouped=True)


data = t

fs_order = ['(0, 1]',
            '(1, 2]',
            '(2, 5]',
            '(5, 10]',
            '(10, 20]',
            '(20, 50]',
            '(50, 100]',
            '(100, 200]',
            '(200, 500]',
            '(500, 1000]',
            '(1000, 100000]']
#
# fs_order = ['(0, 10]',
#             '(10, 100]',
#             '(100, 100000]']

print 'plotting'

fig = plt.figure(figsize=[10, 15])
ax = fig.add_subplot(211)

plot_cumulative_richness(data=t, fs_range=len(fs_order), boots=boots, grouped=(len(fs_order) is 3), ax=ax)

mx = np.ceil(np.log(data['cumsum_area_0']).max())
my = np.ceil(np.log(data['cumsum_items_0']).max())

ax2 = fig.add_subplot(212)

for i in range(len(fs_order)):
    ax2.plot(mx, my,
             color=sns.color_palette('Set2', len(fs_order))[i],
             alpha=1,
             linewidth=0)

h = []

for i in xrange(len(fs_order)):
    h.append(sns.color_palette('Set2', len(fs_order))[i])

legend = ax2.legend(h, labels=[x[1:-1] for x in fs_order],
                    loc='center left',
                    bbox_to_anchor=(0.8, 1.45))

for l in legend.legendHandles:
    l.set_linewidth(10)

frame = legend.get_frame()
frame.set_facecolor('w')
frame.set_edgecolor('w')

# ax.set_xlim([7.5, mx])
ax.set_ylim([100, 150])
ax.set_title('Cumulative area to cumulative species richness')

# plt.show();
fig.savefig('/home/vinny_ricciardi/Downloads/fig2.png')   # save the figure to file
plt.close(fig)    # close the figure

