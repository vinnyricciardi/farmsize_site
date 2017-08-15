

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
              width: 175px; 
              padding: 10px; 
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

    <a href=#Top>Top</a><br>
    <a href="javascript:code_toggle()">Toggle Code On/Off</a><br>
    <a href=#LeftOff>Left Off Here</a><br>
    <a href='https://vinnyricciardi.github.io/farmsize_site/'>Site Index</a><br>
</div>
''')
```





<style>
    .yourDiv {position: fixed;top: 100px; right: 0px; 
              background: white;
              height: 100%;
              width: 175px; 
              padding: 10px; 
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

    <a href=#Top>Top</a><br>
    <a href="javascript:code_toggle()">Toggle Code On/Off</a><br>
    <a href=#LeftOff>Left Off Here</a><br>
    <a href='https://vinnyricciardi.github.io/farmsize_site/'>Site Index</a><br>
</div>




<a name="Top"></a>
<center><h1>Data Coverage Overview</h1>



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
PATH = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/Farm_Size/Data/FarmSize_data_fullyProcessed.csv'
df = pd.read_csv(PATH, low_memory=False)
```

<a name="Data"></a>
<h2>Data</h2><br>



```python
num_countries = len(df.NAME_0.unique())
num_crops = len(df.Crop.unique())
num_crops_fao = len(df.query("production_Food_kcal == production_Food_kcal").Crop.unique())
num_admin = len(df.shpID.unique())
num_obs = len(df)
num_micro = len(df.query("microdata == 1").NAME_0.unique())
num_tab = len(df.query("microdata == 0").NAME_0.unique())
num_sur = len(df.query("cen_sur == 'sur'").NAME_0.unique())
num_cen = len(df.query("cen_sur == 'cen'").NAME_0.unique())
avg_year = int(round(df.year.mean(), 0))
min_year = df.year.min().astype(int)
max_year = df.year.max().astype(int)
```

General
- Our dataset caputres the amount of crops produced by farms of different sizes.<br>
- We used the World Census of Agriculture's (WCA) farm size categories to be consistent with other studies.
- Our dataset consists of 564134 observations.<br>
- 58 countries are represented at either the national or subnational level.<br>
- In total, there are 2804 national or subnational units.<br>
- There are 151 crops, of which we were able to match 127 with the FAO's database to calculate the amount of crops produced by farm size class for food, feed, waste, seed, proccessing, and other in terms of kcal.<br>
- We used 37 tabulated datasets, and 21 microdatasets (i.e., data at the household record level)
- 41 agricultural  censuses were used. Where census data was not used, nationally or subnationally representative household surveys were used (17 in total).
- On average the data was from 2011, with the oldest datasets from 2001 and the newest from 2013


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
- Map to be replaced with map of sub-national units (and in a better projection!) after we spatially match all admin units


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


![png](Data_Coverage_files/Data_Coverage_13_0.png)


<a name="LeftOff"></a>
<h3>Left Off</h3>

To Do:
- Need to put into the global context


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
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>Agave fibres nes</td>
      <td>800.0</td>
      <td>Mexico</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>MEX</td>
      <td>MEX</td>
      <td>t</td>
      <td>1.0</td>
      <td>2.0</td>
      <td>sur</td>
      <td>1</td>
      <td>2007.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>37.702929</td>
      <td>37.702929</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.255413</td>
      <td>0.927016</td>
      <td>0.000674</td>
      <td>0.087989</td>
      <td>0.877703</td>
      <td>1.000000</td>
      <td>9.629819</td>
      <td>NaN</td>
      <td>34.951226</td>
      <td>NaN</td>
      <td>37.702929</td>
      <td>NaN</td>
      <td>0.025416</td>
      <td>NaN</td>
      <td>3.317445</td>
      <td>NaN</td>
      <td>33.091975</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>1</th>
      <td>1</td>
      <td>Agave fibres nes</td>
      <td>800.0</td>
      <td>Mexico</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>MEX</td>
      <td>MEX</td>
      <td>t</td>
      <td>20.0</td>
      <td>50.0</td>
      <td>sur</td>
      <td>1</td>
      <td>2007.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>37.702929</td>
      <td>37.702929</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.255413</td>
      <td>0.927016</td>
      <td>0.000674</td>
      <td>0.087989</td>
      <td>0.877703</td>
      <td>1.000000</td>
      <td>9.629819</td>
      <td>NaN</td>
      <td>34.951226</td>
      <td>NaN</td>
      <td>37.702929</td>
      <td>NaN</td>
      <td>0.025416</td>
      <td>NaN</td>
      <td>3.317445</td>
      <td>NaN</td>
      <td>33.091975</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>2</th>
      <td>2</td>
      <td>Almonds, with shell</td>
      <td>221.0</td>
      <td>Colombia</td>
      <td>Amazonas</td>
      <td>La Chorrera</td>
      <td>1</td>
      <td>COL</td>
      <td>COL001002</td>
      <td>ha</td>
      <td>20.0</td>
      <td>50.0</td>
      <td>cen</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>1</td>
      <td>0.0</td>
      <td>0.905842</td>
      <td>1.000000</td>
      <td>0.135892</td>
      <td>0.002301</td>
      <td>0.782199</td>
      <td>0.089903</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>1.0</td>
      <td>0.11</td>
      <td>0.03</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>3</td>
      <td>Almonds, with shell</td>
      <td>221.0</td>
      <td>Colombia</td>
      <td>Amazonas</td>
      <td>La Chorrera</td>
      <td>1</td>
      <td>COL</td>
      <td>COL001002</td>
      <td>ha</td>
      <td>50.0</td>
      <td>100.0</td>
      <td>cen</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>1</td>
      <td>0.0</td>
      <td>0.905842</td>
      <td>1.000000</td>
      <td>0.135892</td>
      <td>0.002301</td>
      <td>0.782199</td>
      <td>0.089903</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>0.000000</td>
      <td>0.0</td>
      <td>1.0</td>
      <td>0.11</td>
      <td>0.03</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>4</td>
      <td>Almonds, with shell</td>
      <td>221.0</td>
      <td>Colombia</td>
      <td>Amazonas</td>
      <td>La Chorrera</td>
      <td>1</td>
      <td>COL</td>
      <td>COL001002</td>
      <td>t</td>
      <td>20.0</td>
      <td>50.0</td>
      <td>cen</td>
      <td>1</td>
      <td>2013.0</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>0.000000</td>
      <td>0</td>
      <td>NaN</td>
      <td>0.905842</td>
      <td>1.000000</td>
      <td>0.135892</td>
      <td>0.002301</td>
      <td>0.782199</td>
      <td>0.089903</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>0.000000</td>
      <td>NaN</td>
      <td>1.0</td>
      <td>0.11</td>
      <td>0.03</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
      <td>0.0</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>




```python
fao = pd.read_csv('/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/FaoStat/FAOSTAT/Production_Crops_E_All_Data_(Norm).csv')
```


```python
fao.head()
```


```python
tmp = fao.copy()
tmp2 = df.copy()
```


```python
tmp1 = tmp[tmp['Element'] == 'Area harvested']
```


```python
tmp1 = pd.merge(tmp1, tmp2, how='inner', left_on='Country', right_on='NAME_0', indicator=True)
tmp1.head()
```


```python

```


```python

```
