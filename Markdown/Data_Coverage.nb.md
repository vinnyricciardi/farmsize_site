

```python
from IPython.display import HTML
HTML('''<script>
code_show=true; 
function code_toggle() {
 if (code_show){
 $('div.input').hide();
 } else {
 $('div.input').show();
 }
 code_show = !code_show
} 
$( document ).ready(code_toggle);
</script>''')
```




<script>
code_show=true; 
function code_toggle() {
 if (code_show){
 $('div.input').hide();
 } else {
 $('div.input').show();
 }
 code_show = !code_show
} 
$( document ).ready(code_toggle);
</script>



<a name="Top"></a>


```python
from IPython.display import HTML
HTML('''
<style>
    .yourDiv {position: fixed;top: 100px; right: 0px; 
              background: white;
              height: 100%;
              width: 300px; 
              padding: 20px; 
              z-index: 10000}
</style>
<script>
function showthis(url) {
	window.open(url, "pres", 
                "toolbar=yes,scrollbars=yes,resizable=yes,top=10,left=400,width=500,height=500");
	return(false);
}
</script>

<div class=yourDiv>
    <h4>MENU</h4><br>
    <a href=#Data>1. Data</a><br>
    <a href=#SpatialCoverage>2. Spatial Coverage</a><br>
    <a href=#TemporalCoverage>3. Temporal Coverage</a><br>
    <a href=#ClassOverlaps>4. Farm size class overlaps</a><br>
    <a href=#YieldLookUpTable>5. Yield look-up table</a><br><br>

    <a href="javascript:code_toggle()">Toggle Code On/Off</a><br>
    <a href=#Top>Top</a><br>
    <a href=#LeftOff>Left Off Here</a><br>
</div>
''')
```





<style>
    .yourDiv {position: fixed;top: 100px; right: 0px; 
              background: white;
              height: 100%;
              width: 300px; 
              padding: 20px; 
              z-index: 10000}
</style>
<script>
function showthis(url) {
	window.open(url, "pres", 
                "toolbar=yes,scrollbars=yes,resizable=yes,top=10,left=400,width=500,height=500");
	return(false);
}
</script>

<div class=yourDiv>
    <h4>MENU</h4><br>
    <a href=#Data>1. Data</a><br>
    <a href=#SpatialCoverage>2. Spatial Coverage</a><br>
    <a href=#TemporalCoverage>3. Temporal Coverage</a><br>
    <a href=#ClassOverlaps>4. Farm size class overlaps</a><br>
    <a href=#YieldLookUpTable>5. Yield look-up table</a><br><br>

    <a href="javascript:code_toggle()">Toggle Code On/Off</a><br>
    <a href=#Top>Top</a><br>
    <a href=#LeftOff>Left Off Here</a><br>
</div>




# <center>Data Coverage Overview</center>
## <center>What portion of the global food supply is produced by smallholders?</center>
### <center>Vinny Ricciardi, Larissa Jarvis, Navin Ramankutty</center>


<a name="Data"></a>
<h2>Data</h2><br>
1. Harvested area per farm size class
2. Yield per crop per farm size class

To Dos:

- Update this document with new database codes. This is partially updated, but after the spartial coverage section, it relies on the old data.


```python
# Import dependencies
import warnings
warnings.filterwarnings('ignore')
import pandas as pd
import geopandas as gpd
import seaborn as sns
from matplotlib import pyplot as plt
import matplotlib.pyplot as plt
from matplotlib.path import Path
import matplotlib.patches as patches
from matplotlib.pyplot import cm 
import matplotlib as mpl
import numpy as np
import re
import geopy
import mpld3
import plotly.plotly as py
import cmocean

pd.set_option('display.max_columns', 500)
%matplotlib inline
```


```python
# Set all plotting params:
title_sz = 20
x_lab_tick_sz = 18
y_lab_tick_sz = 18
x_lab_label_sz = 18
y_lab_label_sz = 18
lengend_sz = 16
```


```python
# Import data
# df = pd.read_csv('/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/'
#                  'CropbyFarmsize_2_20170711.csv',
#                  low_memory=False)

# df = pd.read_csv('/Users/Vinny_Ricciardi/Downloads/farmsize_df.csv',                 
#                  low_memory=False)

PATH = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/FarmSize_data_fullyProcessed.csv'
df = pd.read_csv(PATH, low_memory=False)
```


```python
# df = df.query("theme == 'Landuse'")
```

<a name="SpatialCoverage"></a>
<h2>Spatial Coverage</h2>


```python
df['NAME_0'].replace(['United States of America'], ['United States'], inplace=True)
df['NAME_0'].replace(['Bosnia and Herzegovina'], ['Bosnia and Herz.'], inplace=True)
df['NAME_0'].replace(['United Republic of Tanzania'], ['Tanzania'], inplace=True)
df['NAME_0'].replace(['Russian Federation'], ['Russia'], inplace=True)
df['NAME_0'].replace(['Czech Republic'], ['Czech Rep.'], inplace=True)
df['NAME_0'].replace(['Czech Republic'], ['Czech Rep.'], inplace=True)
df['NAME_0'].replace(['Czech Republic'], ['Czech Rep.'], inplace=True)

```

To do:
- What percentage of global production does our sample represent?


```python
pivoted = pd.pivot_table(df, 
                         index='NAME_0', 
                         values='Crop', 
                         aggfunc=lambda x: len(x.unique()))
pivoted = pivoted.reset_index()
pivoted = pivoted.sort_values('Crop', ascending=False)
pivoted['Data_Available'] = pivoted['Crop'].astype(int)

world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))

world = world.to_crs(epsg=3786)

world = pd.merge(world, pivoted, 
                 how='outer', 
                 left_on='name', 
                 right_on='NAME_0')

world['Orig_crop'] = world['Crop'].fillna(0)
world['coverage'] = np.where(world['Crop'] > 0, 
                             'Found and downloaded', 
                             np.where(world['Crop'] == -1, 
                                      'Found not downloaded', 
                                      'No data found'))

warnings.filterwarnings('ignore')

x = len(pivoted.NAME_0.unique())

try:
    fig, ax = plt.subplots(figsize=(20, 10))
    ax.set_aspect('equal')
    world.plot(column='coverage', cmap='Accent', ax=ax, alpha=0.7, linewidth=0.1)  #cmocean.cm.deep
except:
    pass

ndf, fad = world.coverage.value_counts()
cmap_ = cmocean.tools.get_dict(cmocean.cm.deep, N=4)

p1 = mpl.lines.Line2D([], [], 
                             color=[x / 255. for x in [128, 128, 130]],
                             linewidth=10, 
                             label='Data not found ({})'.format(ndf))
p2 = mpl.lines.Line2D([], [], 
                             color=[x / 255. for x in [148, 207, 150]], 
                             linewidth=10, 
                             label='Found and in database ({})'.format(fad))

handles = [p1, p2]
labels = [h.get_label() for h in handles] 

legend = ax.legend(handles=handles, labels=labels, frameon=True, 
                   fontsize=14, loc='lower left')

legend.get_frame().set_facecolor('#ffffff')

plt.show()
```


![png](Data_Coverage.nb_files/Data_Coverage.nb_13_0.png)


<a name="TemporalCoverage"></a>
<h2>Temporal Coverage</h2>


```python
df = df.sort_values('NAME_0')
grouped = df.groupby('NAME_0').mean()
grouped['year'] = grouped['year'].astype(int)
grouped = grouped.sort('year')

fig = plt.figure(figsize=(10, 5))
ax = fig.add_subplot(111)
sns.countplot(x=grouped.year, color='#FF5733', ax=ax)
ax.set_title('\n Median year per country collected \n', fontsize=title_sz-4)
ax.set_xlabel('\nYear\n', fontsize=y_lab_tick_sz-4)
ax.set_ylabel('\nCount of Countries\n', fontsize=y_lab_tick_sz-4)
mpl.rcParams['xtick.labelsize'] = x_lab_tick_sz-8
mpl.rcParams['ytick.labelsize'] = y_lab_tick_sz-8
plt.show()
```


![png](Data_Coverage.nb_files/Data_Coverage.nb_15_0.png)


<a name="ClassOverlaps"></a>
<h2>Farm size class overlaps</h2>

<p>First, I counted the number of records per farm size stratum, then plotted each farm size stratum by the amount of records per stratum.<br>

Here is the resulted graph of records per farm size stratum. The x-axis is the size of the farm size stratum, where each rectangle's horizontal plane represents the range the farm size stratum covers. The y-axis is the relative amount of records per farm size stratum; to make the overlaps easier to see, each subsequent rectangle starts a little higher than the previous (hence, the y-axis is only relative).</p>


```python
df = df.query("fs_class_min != ['Total', 'defined', 'landless', 'undefined'] & "
              "fs_class_max != 'MORE'")

df['fs_class_min'] = df['fs_class_min'].astype(str).str.replace(u'+', '')
df['fs_class_min'] = df['fs_class_min'].astype(float)

# df['fs_class_min'] = (df['fs_class_min'] * 0.404686).where(df['fs_class_unit'] == 'acre') # not needed in the future

df['fs_class_max'] = df['fs_class_max'].astype(float)
# df['fs_class_max'] = (df['fs_class_max'] * 0.404686).where(df['fs_class_unit'] == 'acre') # not needed in the future

df['fs_Range'] = df['fs_class_min'].astype('str').map(str) + '_' + df['fs_class_max'].astype(str)

df = df.sort_values(['fs_Range'])

grouped = df.groupby(['fs_Range', 'fs_class_min', 'fs_class_max']).count()
grouped = grouped.reset_index()
grouped1 = grouped.loc[:, ['fs_Range', 'NAME_0']]
grouped2 = grouped1.fs_Range.str.split('_', expand=True)
grouped = grouped1.join(grouped2)
grouped.columns = ['fs_Range', 'Count', 'Low', 'High']
grouped['Low'] = grouped['Low'].astype(float)
grouped['High'] = grouped['High'].astype(float)
grouped = grouped.sort_values(['Low', 'High'])
# grouped['Count_sqrt'] = np.sqrt(grouped['Count'])
grouped['Count_sqrt'] = grouped['Count']
grouped['High'].fillna(-999, inplace=True)
grouped['High'] = np.where(grouped['High'] == -999, 100, grouped['High'])
```


```python
def plt_farmSize_A(level=None, ax=ax):
    
    color = cm.get_cmap('Set2')
    # color2 = cm.rainbow(np.linspace(0,1,len(grouped)))
    
    for i in range(0, len(grouped)):
        
        try:
            verts = [
                (grouped['Low'][i], grouped['High'][i]), # left, bottom
                (grouped['Low'][i], grouped['Count_sqrt'][i]), # left, top
                (grouped['High'][i], grouped['Count_sqrt'][i]), # right, top
                (grouped['High'][i], grouped['High'][i]), # right, bottom
                (0., 0.), # ignored
                ]

            codes = [Path.MOVETO,
                     Path.LINETO,
                     Path.LINETO,
                     Path.LINETO,
                     Path.CLOSEPOLY,
                     ]

            path = Path(verts, codes)
            patch = patches.PathPatch(path, facecolor=color(4*i), lw=1, alpha=0.2)
            ax.add_patch(patch)    

        except:
            pass
        
    if level:
        ax.set_xlim(0, level[0])
        ax.set_ylim(0, level[1])
        
        major_ticks = np.arange(0, level[1], 2)                                              
        minor_ticks = np.arange(0, level[1], 1)                                               
        
    else:
        ax.set_xlim(0, grouped['Count_sqrt'].max() / 10)
        ax.set_ylim(-100, grouped['High'].max() + (grouped['High'].max() / 5))
        
        major_ticks = np.arange(0, grouped['High'].max(), round(grouped['High'].max()+1,0) / 10)                                             
        minor_ticks = np.arange(0, grouped['High'].max(), round(grouped['High'].max()+1,0) / 10)                                               
    
    ax.set_xticks(major_ticks)                                                       
    ax.set_xticks(minor_ticks, minor=True)
    ax.set_title('\n Farm Size Stratum by Frequency of Stratum Used \n', fontsize=title_sz)
    ax.set_xlabel('\n Size (ha) \n', fontsize=x_lab_label_sz)
    ax.set_ylabel('\n Number of records \n', fontsize=x_lab_label_sz)
    mpl.rcParams['xtick.labelsize'] = x_lab_tick_sz
    mpl.rcParams['ytick.labelsize'] = y_lab_tick_sz

    return plt.show()
```


```python
fig, ax = plt.subplots(figsize=(20, 10))
plt_farmSize_A(level=None, ax=ax)
# ax.set_xlim([0, 9])
plt.show()
```


![png](Data_Coverage.nb_files/Data_Coverage.nb_19_0.png)


From the above graph, the larger farm size stratum have less overlap, while the smaller farm size stratum contain a lot of overlap. Here is a zoomed in plot of the smaller farm size stratum.

*Note: if the acres are all covnerted to hectares, then there is no overlap, but if not converted there is a large amount of overlap - at this point, they are converted to ha , but I am not certain the data needs to be converted or is already in ha form.*


```python
fig, ax = plt.subplots(figsize=(20, 10))
plt_farmSize_A(level=[1, 90], ax=ax)
plt.show()
```


![png](Data_Coverage.nb_files/Data_Coverage.nb_21_0.png)


<a name="LeftOff"></a>
<h3>Left Off</h3>


```python
# dd = df
# grouped.fs_Range.unique()

# fig = plt.figure(figsize=(20, 10));
# ax = fig.add_subplot(111);

# sns.barplot(grouped['Count'], grouped['fs_Range'], 
#             linewidth=2.5, facecolor=(1, 1, 1, 0), 
#             errcolor='0.2', edgecolor='0.2',
#             ax=ax);
# ax.set_xlabel('');
# ax.set_ylabel('');
```


```python
df.head()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Unnamed: 0</th>
      <th>Crop</th>
      <th>Item_Code</th>
      <th>NAME_0</th>
      <th>NAME_1</th>
      <th>NAME_2</th>
      <th>NAME_3</th>
      <th>es1</th>
      <th>shpID</th>
      <th>data_unit</th>
      <th>fs_class_min</th>
      <th>fs_class_max</th>
      <th>cen_sur</th>
      <th>microdata</th>
      <th>year</th>
      <th>Crop_area</th>
      <th>Cultivated_area</th>
      <th>Harvested_area</th>
      <th>Planted_area</th>
      <th>Production</th>
      <th>Production_fix</th>
      <th>Production_fix_dummy</th>
      <th>Production_constant</th>
      <th>perc_Feed</th>
      <th>perc_Food</th>
      <th>perc_Seed</th>
      <th>perc_Waste</th>
      <th>perc_Processing</th>
      <th>perc_Other</th>
      <th>production_Feed</th>
      <th>production_Feed_k</th>
      <th>production_Food</th>
      <th>production_Food_k</th>
      <th>production_Other</th>
      <th>production_Other_k</th>
      <th>production_Seed</th>
      <th>production_Seed_k</th>
      <th>production_Waste</th>
      <th>production_Waste_k</th>
      <th>production_Processing</th>
      <th>production_Processing_k</th>
      <th>kcal</th>
      <th>fat</th>
      <th>protein</th>
      <th>production_Feed_kcal</th>
      <th>production_Feed_k_kcal</th>
      <th>production_Food_kcal</th>
      <th>production_Food_k_kcal</th>
      <th>production_Other_kcal</th>
      <th>production_Other_k_kcal</th>
      <th>production_Seed_kcal</th>
      <th>production_Seed_k_kcal</th>
      <th>production_Waste_kcal</th>
      <th>production_Waste_k_kcal</th>
      <th>production_Processing_kcal</th>
      <th>production_Processing_k_kcal</th>
      <th>production_Feed_fat</th>
      <th>production_Feed_k_fat</th>
      <th>production_Food_fat</th>
      <th>production_Food_k_fat</th>
      <th>production_Other_fat</th>
      <th>production_Other_k_fat</th>
      <th>production_Seed_fat</th>
      <th>production_Seed_k_fat</th>
      <th>production_Waste_fat</th>
      <th>production_Waste_k_fat</th>
      <th>production_Processing_fat</th>
      <th>production_Processing_k_fat</th>
      <th>production_Feed_protein</th>
      <th>production_Feed_k_protein</th>
      <th>production_Food_protein</th>
      <th>production_Food_k_protein</th>
      <th>production_Other_protein</th>
      <th>production_Other_k_protein</th>
      <th>production_Seed_protein</th>
      <th>production_Seed_k_protein</th>
      <th>production_Waste_protein</th>
      <th>production_Waste_k_protein</th>
      <th>production_Processing_protein</th>
      <th>production_Processing_k_protein</th>
      <th>fs_Range</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>277068</th>
      <td>277068</td>
      <td>Maize</td>
      <td>56.0</td>
      <td>South Africa</td>
      <td>North West</td>
      <td>1</td>
      <td>1</td>
      <td>ZAF</td>
      <td>ZAF006</td>
      <td>kg</td>
      <td>0.0</td>
      <td>0.5</td>
      <td>sur</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>3506.214143</td>
      <td>3506.214143</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.353458</td>
      <td>0.577147</td>
      <td>0.011652</td>
      <td>0.043327</td>
      <td>3.134402e-03</td>
      <td>0.013312</td>
      <td>1239.299599</td>
      <td>NaN</td>
      <td>2023.601409</td>
      <td>NaN</td>
      <td>46.673506</td>
      <td>NaN</td>
      <td>40.855561</td>
      <td>NaN</td>
      <td>151.912037</td>
      <td>NaN</td>
      <td>10.989885</td>
      <td>NaN</td>
      <td>963.666667</td>
      <td>8.643333</td>
      <td>24.616667</td>
      <td>1.194272e+06</td>
      <td>NaN</td>
      <td>1.950077e+06</td>
      <td>NaN</td>
      <td>4.497770e+04</td>
      <td>NaN</td>
      <td>39371.142355</td>
      <td>NaN</td>
      <td>146392.566499</td>
      <td>NaN</td>
      <td>1.059059e+04</td>
      <td>NaN</td>
      <td>10711.679531</td>
      <td>NaN</td>
      <td>17490.661513</td>
      <td>NaN</td>
      <td>403.414668</td>
      <td>NaN</td>
      <td>353.128233</td>
      <td>NaN</td>
      <td>1313.026375</td>
      <td>NaN</td>
      <td>94.989235</td>
      <td>NaN</td>
      <td>30507.425119</td>
      <td>NaN</td>
      <td>49814.321356</td>
      <td>NaN</td>
      <td>1148.946133</td>
      <td>NaN</td>
      <td>1005.727728</td>
      <td>NaN</td>
      <td>3739.567982</td>
      <td>NaN</td>
      <td>270.534324</td>
      <td>NaN</td>
      <td>0.0_0.5</td>
    </tr>
    <tr>
      <th>517122</th>
      <td>517122</td>
      <td>Taro (cocoyam)</td>
      <td>136.0</td>
      <td>South Africa</td>
      <td>KwaZulu-Natal</td>
      <td>1</td>
      <td>1</td>
      <td>ZAF</td>
      <td>ZAF003</td>
      <td>kg</td>
      <td>0.0</td>
      <td>0.5</td>
      <td>sur</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>2752.762018</td>
      <td>2752.762018</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.945150</td>
      <td>0.088123</td>
      <td>0.088911</td>
      <td>0.032152</td>
      <td>6.978855e-01</td>
      <td>0.923138</td>
      <td>2601.772425</td>
      <td>NaN</td>
      <td>242.580561</td>
      <td>NaN</td>
      <td>2541.178647</td>
      <td>NaN</td>
      <td>244.750116</td>
      <td>NaN</td>
      <td>88.505907</td>
      <td>NaN</td>
      <td>1921.112714</td>
      <td>NaN</td>
      <td>6.785714</td>
      <td>0.032621</td>
      <td>0.398929</td>
      <td>1.765488e+04</td>
      <td>NaN</td>
      <td>1.646082e+03</td>
      <td>NaN</td>
      <td>1.724371e+04</td>
      <td>NaN</td>
      <td>1660.804360</td>
      <td>NaN</td>
      <td>600.575799</td>
      <td>NaN</td>
      <td>1.303612e+04</td>
      <td>NaN</td>
      <td>84.872067</td>
      <td>NaN</td>
      <td>7.913188</td>
      <td>NaN</td>
      <td>82.895446</td>
      <td>NaN</td>
      <td>7.983961</td>
      <td>NaN</td>
      <td>2.887139</td>
      <td>NaN</td>
      <td>62.668359</td>
      <td>NaN</td>
      <td>1037.921357</td>
      <td>NaN</td>
      <td>96.772317</td>
      <td>NaN</td>
      <td>1013.748767</td>
      <td>NaN</td>
      <td>97.637814</td>
      <td>NaN</td>
      <td>35.307535</td>
      <td>NaN</td>
      <td>766.386751</td>
      <td>NaN</td>
      <td>0.0_0.5</td>
    </tr>
    <tr>
      <th>64575</th>
      <td>64575</td>
      <td>Beans, dry</td>
      <td>176.0</td>
      <td>South Africa</td>
      <td>Limpopo</td>
      <td>1</td>
      <td>1</td>
      <td>ZAF</td>
      <td>ZAF004</td>
      <td>kg</td>
      <td>0.0</td>
      <td>0.5</td>
      <td>sur</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>489505.717731</td>
      <td>489505.717731</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.544437</td>
      <td>0.880528</td>
      <td>0.095791</td>
      <td>0.023681</td>
      <td>8.528724e-01</td>
      <td>0.742447</td>
      <td>266505.189514</td>
      <td>NaN</td>
      <td>431023.518971</td>
      <td>NaN</td>
      <td>363432.150132</td>
      <td>NaN</td>
      <td>46890.115329</td>
      <td>NaN</td>
      <td>11592.083431</td>
      <td>NaN</td>
      <td>417485.893937</td>
      <td>NaN</td>
      <td>8.666667</td>
      <td>0.036667</td>
      <td>0.586667</td>
      <td>2.309712e+06</td>
      <td>NaN</td>
      <td>3.735537e+06</td>
      <td>NaN</td>
      <td>3.149745e+06</td>
      <td>NaN</td>
      <td>406380.999517</td>
      <td>NaN</td>
      <td>100464.723067</td>
      <td>NaN</td>
      <td>3.618211e+06</td>
      <td>NaN</td>
      <td>9771.856949</td>
      <td>NaN</td>
      <td>15804.195696</td>
      <td>NaN</td>
      <td>13325.845505</td>
      <td>NaN</td>
      <td>1719.304229</td>
      <td>NaN</td>
      <td>425.043059</td>
      <td>NaN</td>
      <td>15307.816111</td>
      <td>NaN</td>
      <td>156349.711182</td>
      <td>NaN</td>
      <td>252867.131130</td>
      <td>NaN</td>
      <td>213213.528077</td>
      <td>NaN</td>
      <td>27508.867660</td>
      <td>NaN</td>
      <td>6800.688946</td>
      <td>NaN</td>
      <td>244925.057776</td>
      <td>NaN</td>
      <td>0.0_0.5</td>
    </tr>
    <tr>
      <th>356066</th>
      <td>356066</td>
      <td>Onions, shallots, green</td>
      <td>402.0</td>
      <td>South Africa</td>
      <td>KwaZulu-Natal</td>
      <td>1</td>
      <td>1</td>
      <td>ZAF</td>
      <td>ZAF003</td>
      <td>kg</td>
      <td>0.0</td>
      <td>0.5</td>
      <td>sur</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>608.991577</td>
      <td>608.991577</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.029214</td>
      <td>0.872882</td>
      <td>0.012694</td>
      <td>0.097903</td>
      <td>8.622064e-07</td>
      <td>0.058187</td>
      <td>17.791161</td>
      <td>NaN</td>
      <td>531.578067</td>
      <td>NaN</td>
      <td>35.435591</td>
      <td>NaN</td>
      <td>7.730775</td>
      <td>NaN</td>
      <td>59.622349</td>
      <td>NaN</td>
      <td>0.000525</td>
      <td>NaN</td>
      <td>27.333333</td>
      <td>0.263333</td>
      <td>1.220000</td>
      <td>4.862917e+02</td>
      <td>NaN</td>
      <td>1.452980e+04</td>
      <td>NaN</td>
      <td>9.685728e+02</td>
      <td>NaN</td>
      <td>211.307854</td>
      <td>NaN</td>
      <td>1629.677549</td>
      <td>NaN</td>
      <td>1.435209e-02</td>
      <td>NaN</td>
      <td>4.685006</td>
      <td>NaN</td>
      <td>139.982224</td>
      <td>NaN</td>
      <td>9.331372</td>
      <td>NaN</td>
      <td>2.035771</td>
      <td>NaN</td>
      <td>15.700552</td>
      <td>NaN</td>
      <td>0.000138</td>
      <td>NaN</td>
      <td>21.705216</td>
      <td>NaN</td>
      <td>648.525241</td>
      <td>NaN</td>
      <td>43.231421</td>
      <td>NaN</td>
      <td>9.431546</td>
      <td>NaN</td>
      <td>72.739266</td>
      <td>NaN</td>
      <td>0.000641</td>
      <td>NaN</td>
      <td>0.0_0.5</td>
    </tr>
    <tr>
      <th>356062</th>
      <td>356062</td>
      <td>Onions, shallots, green</td>
      <td>402.0</td>
      <td>South Africa</td>
      <td>Free State</td>
      <td>1</td>
      <td>1</td>
      <td>ZAF</td>
      <td>ZAF008</td>
      <td>kg</td>
      <td>0.0</td>
      <td>0.5</td>
      <td>sur</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>23531.608014</td>
      <td>23531.608014</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.029214</td>
      <td>0.872882</td>
      <td>0.012694</td>
      <td>0.097903</td>
      <td>8.622064e-07</td>
      <td>0.058187</td>
      <td>687.455531</td>
      <td>NaN</td>
      <td>20540.327921</td>
      <td>NaN</td>
      <td>1369.241324</td>
      <td>NaN</td>
      <td>298.719354</td>
      <td>NaN</td>
      <td>2303.824563</td>
      <td>NaN</td>
      <td>0.020289</td>
      <td>NaN</td>
      <td>27.333333</td>
      <td>0.263333</td>
      <td>1.220000</td>
      <td>1.879045e+04</td>
      <td>NaN</td>
      <td>5.614356e+05</td>
      <td>NaN</td>
      <td>3.742593e+04</td>
      <td>NaN</td>
      <td>8164.995665</td>
      <td>NaN</td>
      <td>62971.204710</td>
      <td>NaN</td>
      <td>5.545688e-01</td>
      <td>NaN</td>
      <td>181.029956</td>
      <td>NaN</td>
      <td>5408.953019</td>
      <td>NaN</td>
      <td>360.566882</td>
      <td>NaN</td>
      <td>78.662763</td>
      <td>NaN</td>
      <td>606.673801</td>
      <td>NaN</td>
      <td>0.005343</td>
      <td>NaN</td>
      <td>838.695748</td>
      <td>NaN</td>
      <td>25059.200063</td>
      <td>NaN</td>
      <td>1670.474416</td>
      <td>NaN</td>
      <td>364.437611</td>
      <td>NaN</td>
      <td>2810.665966</td>
      <td>NaN</td>
      <td>0.024753</td>
      <td>NaN</td>
      <td>0.0_0.5</td>
    </tr>
  </tbody>
</table>
</div>



To Do:
- We will need to see what these overlaps look like once the dataset compilation is complete, then determine the farm size classes we want to use.
- Also plot per farm size range on the y-axis, farm size on the x-axis??


```python
pivot = pd.pivot_table(df, index=['NAME_0', 'fs_class_min', 'fs_class_max'], values='Production_fix', aggfunc='count')
pivot = pivot.reset_index()
pivot
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>NAME_0</th>
      <th>fs_class_min</th>
      <th>fs_class_max</th>
      <th>Production_fix</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>Albania</td>
      <td>0.000000</td>
      <td>1.000000</td>
      <td>165</td>
    </tr>
    <tr>
      <th>1</th>
      <td>Albania</td>
      <td>1.000000</td>
      <td>2.000000</td>
      <td>143</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Albania</td>
      <td>2.000000</td>
      <td>5.000000</td>
      <td>136</td>
    </tr>
    <tr>
      <th>3</th>
      <td>Albania</td>
      <td>5.000000</td>
      <td>10.000000</td>
      <td>77</td>
    </tr>
    <tr>
      <th>4</th>
      <td>Albania</td>
      <td>10.000000</td>
      <td>20.000000</td>
      <td>43</td>
    </tr>
    <tr>
      <th>5</th>
      <td>Albania</td>
      <td>20.000000</td>
      <td>50.000000</td>
      <td>2</td>
    </tr>
    <tr>
      <th>6</th>
      <td>Albania</td>
      <td>50.000000</td>
      <td>100.000000</td>
      <td>4</td>
    </tr>
    <tr>
      <th>7</th>
      <td>Austria</td>
      <td>2.000000</td>
      <td>4.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>8</th>
      <td>Austria</td>
      <td>5.000000</td>
      <td>9.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>9</th>
      <td>Austria</td>
      <td>10.000000</td>
      <td>19.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>10</th>
      <td>Austria</td>
      <td>20.000000</td>
      <td>29.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>11</th>
      <td>Austria</td>
      <td>30.000000</td>
      <td>49.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>12</th>
      <td>Austria</td>
      <td>50.000000</td>
      <td>99.000000</td>
      <td>840</td>
    </tr>
    <tr>
      <th>13</th>
      <td>Belgium</td>
      <td>2.000000</td>
      <td>4.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>14</th>
      <td>Belgium</td>
      <td>5.000000</td>
      <td>9.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>15</th>
      <td>Belgium</td>
      <td>10.000000</td>
      <td>19.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>16</th>
      <td>Belgium</td>
      <td>20.000000</td>
      <td>29.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>17</th>
      <td>Belgium</td>
      <td>30.000000</td>
      <td>49.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>18</th>
      <td>Belgium</td>
      <td>50.000000</td>
      <td>99.000000</td>
      <td>1008</td>
    </tr>
    <tr>
      <th>19</th>
      <td>Bosnia and Herz.</td>
      <td>0.000000</td>
      <td>1.000000</td>
      <td>84</td>
    </tr>
    <tr>
      <th>20</th>
      <td>Bosnia and Herz.</td>
      <td>1.000000</td>
      <td>2.000000</td>
      <td>80</td>
    </tr>
    <tr>
      <th>21</th>
      <td>Bosnia and Herz.</td>
      <td>2.000000</td>
      <td>5.000000</td>
      <td>84</td>
    </tr>
    <tr>
      <th>22</th>
      <td>Bosnia and Herz.</td>
      <td>5.000000</td>
      <td>10.000000</td>
      <td>77</td>
    </tr>
    <tr>
      <th>23</th>
      <td>Bosnia and Herz.</td>
      <td>10.000000</td>
      <td>20.000000</td>
      <td>49</td>
    </tr>
    <tr>
      <th>24</th>
      <td>Bosnia and Herz.</td>
      <td>20.000000</td>
      <td>50.000000</td>
      <td>30</td>
    </tr>
    <tr>
      <th>25</th>
      <td>Bosnia and Herz.</td>
      <td>50.000000</td>
      <td>100.000000</td>
      <td>18</td>
    </tr>
    <tr>
      <th>26</th>
      <td>Bosnia and Herz.</td>
      <td>100.000000</td>
      <td>200.000000</td>
      <td>33</td>
    </tr>
    <tr>
      <th>27</th>
      <td>Bosnia and Herz.</td>
      <td>200.000000</td>
      <td>1000.000000</td>
      <td>20</td>
    </tr>
    <tr>
      <th>28</th>
      <td>Brazil</td>
      <td>0.100000</td>
      <td>0.200000</td>
      <td>1288</td>
    </tr>
    <tr>
      <th>29</th>
      <td>Brazil</td>
      <td>0.200000</td>
      <td>0.500000</td>
      <td>1288</td>
    </tr>
    <tr>
      <th>...</th>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
    </tr>
    <tr>
      <th>405</th>
      <td>Uganda</td>
      <td>2.000000</td>
      <td>5.000000</td>
      <td>67</td>
    </tr>
    <tr>
      <th>406</th>
      <td>Uganda</td>
      <td>5.000000</td>
      <td>10.000000</td>
      <td>30</td>
    </tr>
    <tr>
      <th>407</th>
      <td>Uganda</td>
      <td>10.000000</td>
      <td>20.000000</td>
      <td>15</td>
    </tr>
    <tr>
      <th>408</th>
      <td>Uganda</td>
      <td>20.000000</td>
      <td>50.000000</td>
      <td>10</td>
    </tr>
    <tr>
      <th>409</th>
      <td>United Kingdom</td>
      <td>2.000000</td>
      <td>4.000000</td>
      <td>3248</td>
    </tr>
    <tr>
      <th>410</th>
      <td>United Kingdom</td>
      <td>5.000000</td>
      <td>9.000000</td>
      <td>3256</td>
    </tr>
    <tr>
      <th>411</th>
      <td>United Kingdom</td>
      <td>10.000000</td>
      <td>19.000000</td>
      <td>3252</td>
    </tr>
    <tr>
      <th>412</th>
      <td>United Kingdom</td>
      <td>20.000000</td>
      <td>29.000000</td>
      <td>3248</td>
    </tr>
    <tr>
      <th>413</th>
      <td>United Kingdom</td>
      <td>30.000000</td>
      <td>49.000000</td>
      <td>3236</td>
    </tr>
    <tr>
      <th>414</th>
      <td>United Kingdom</td>
      <td>50.000000</td>
      <td>99.000000</td>
      <td>3248</td>
    </tr>
    <tr>
      <th>415</th>
      <td>United States</td>
      <td>0.404685</td>
      <td>4.006381</td>
      <td>487</td>
    </tr>
    <tr>
      <th>416</th>
      <td>United States</td>
      <td>4.046850</td>
      <td>20.193782</td>
      <td>664</td>
    </tr>
    <tr>
      <th>417</th>
      <td>United States</td>
      <td>20.234250</td>
      <td>28.287482</td>
      <td>584</td>
    </tr>
    <tr>
      <th>418</th>
      <td>United States</td>
      <td>28.327950</td>
      <td>40.428032</td>
      <td>610</td>
    </tr>
    <tr>
      <th>419</th>
      <td>United States</td>
      <td>40.468500</td>
      <td>56.251215</td>
      <td>634</td>
    </tr>
    <tr>
      <th>420</th>
      <td>United States</td>
      <td>56.655900</td>
      <td>72.438615</td>
      <td>623</td>
    </tr>
    <tr>
      <th>421</th>
      <td>United States</td>
      <td>72.843300</td>
      <td>88.626015</td>
      <td>570</td>
    </tr>
    <tr>
      <th>422</th>
      <td>United States</td>
      <td>89.030700</td>
      <td>104.813415</td>
      <td>573</td>
    </tr>
    <tr>
      <th>423</th>
      <td>United States</td>
      <td>105.218100</td>
      <td>201.937815</td>
      <td>687</td>
    </tr>
    <tr>
      <th>424</th>
      <td>United States</td>
      <td>202.342500</td>
      <td>404.280315</td>
      <td>679</td>
    </tr>
    <tr>
      <th>425</th>
      <td>United States</td>
      <td>404.685000</td>
      <td>808.965315</td>
      <td>644</td>
    </tr>
    <tr>
      <th>426</th>
      <td>Uruguay</td>
      <td>1.000000</td>
      <td>2.000000</td>
      <td>102</td>
    </tr>
    <tr>
      <th>427</th>
      <td>Uruguay</td>
      <td>2.000000</td>
      <td>5.000000</td>
      <td>230</td>
    </tr>
    <tr>
      <th>428</th>
      <td>Uruguay</td>
      <td>5.000000</td>
      <td>10.000000</td>
      <td>288</td>
    </tr>
    <tr>
      <th>429</th>
      <td>Uruguay</td>
      <td>10.000000</td>
      <td>20.000000</td>
      <td>312</td>
    </tr>
    <tr>
      <th>430</th>
      <td>Uruguay</td>
      <td>20.000000</td>
      <td>50.000000</td>
      <td>412</td>
    </tr>
    <tr>
      <th>431</th>
      <td>Uruguay</td>
      <td>50.000000</td>
      <td>100.000000</td>
      <td>330</td>
    </tr>
    <tr>
      <th>432</th>
      <td>Uruguay</td>
      <td>100.000000</td>
      <td>200.000000</td>
      <td>302</td>
    </tr>
    <tr>
      <th>433</th>
      <td>Uruguay</td>
      <td>200.000000</td>
      <td>500.000000</td>
      <td>246</td>
    </tr>
    <tr>
      <th>434</th>
      <td>Uruguay</td>
      <td>500.000000</td>
      <td>1000.000000</td>
      <td>200</td>
    </tr>
  </tbody>
</table>
<p>435 rows × 4 columns</p>
</div>




```python
tmp = pivot.query("NAME_0 == 'Albania'")
# plt.barh(tmp['fs_class_min'], tmp['fs_class_max'])
```


```python
plt.bar(tmp['fs_class_min'], tmp['fs_class_min'])
```




    <Container object of 7 artists>




![png](Data_Coverage.nb_files/Data_Coverage.nb_28_1.png)



```python

```
