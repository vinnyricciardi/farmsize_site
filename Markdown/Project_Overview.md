

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
    <a href=#RQs>1. RQ's</a><br>
    <a href=#Background>2. Background</a><br>
    <a href=#Goals>3. Goals</a><br>
    <a href=#Data>4. Data</a><br>
    <a href=#Analysis>5. Analysis</a><br><br>

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
    <a href=#RQs>1. RQ's</a><br>
    <a href=#Background>2. Background</a><br>
    <a href=#Goals>3. Goals</a><br>
    <a href=#Data>4. Data</a><br>
    <a href=#Analysis>5. Analysis</a><br><br>

    <a href=#Top>Top</a><br>
    <a href="javascript:code_toggle()">Toggle Code On/Off</a><br>
    <a href=#LeftOff>Left Off Here</a><br>
    <a href='https://vinnyricciardi.github.io/farmsize_site/'>Site Index</a><br>
</div>




<center><h1> Project Overview</h1>
<h2>What portion of the global food supply is produced by smallholders?</h2>
<h3>Vinny Ricciardi, Larissa Jarvis, Brenton Chookolingo, and Navin Ramankutty<br><br>
Institute for Resources, Environment, and Sustainability<br><br>
University of British Columbia</h3></center>

<a name="RQs"></a>
<h2>RQ's</h2><br>

-	What is the contribution of small farms to global food security?
-	Are smallholders producing a greater diversity of crops than largeholders?
-	Are smallholders yielding more production than largeholders on the crops they both grow (IR)?

<a name="Background"></a>
<h2>Background</h2><br>

During the 2014 United Nations (UN) International Year of the Family Farm, food security agencies called for increased support for ‘small-scale farmers’, reporting they produce 70-80% of the world’s food (1,2) and represent 84% of farms globally (3), yet are among the most food-insecure population (4). Despite the over-arching message of the UN’s call to support resource strained and often vulnerable smallholder farmers in the Global South, the statistics commonly used by food security agencies and advocacy groups is highly uncertain.<br><br>

There have been multiple attempts to quanitify several aspects of smallholders globally. 
1. Lowder et al. 2015 presented estiamtes of how many smallholder farmers there are globally.
2. Greaub et al. 2015 quantified the number of family farms in the world and their global production contrbutions. This study measured family farm impacts, where family farms are often associated with smallholders and/or share common types of management tactics as smallholders, such as reliance on family labor and on shortened supply chains (grow their own food). Then estimated production contributions per family versus non-family farms. However, while this contribution is helpful to better understand the unique challenges of family versus commercial operations, the connection between family farms and small farms is not clear cut. For example, many family farms in their case study of Brazil and other major producing areas, a farm may be family owned but spatially very large.
3. Samberg et al. 2016 was the first attempt to place a number on the production contributions of smallholders to the global food system. This attempt was a first step in understanding how much food smallholders produced, but may have resulted in faulty estimates for two main methodological reasons. First, this attempt relied on estimating where smallholder farmers lived by calculating the mean farm size in a given area (i.e., grid cell), hence they did not capture farm size distributions in a given area. Second, their mean farm size metric was then used to assign an equal share of the crop production produced by that given area to the smallholders and largeholders. This analysis neglects to incorporate over 50-years worth of on-farm observations and economic assessments that have observed smaller farms are able to have higher yields, referred to as the inverse farm-size relationship (IR).

To do:
- Explain the most up to date reasoning driving IR


<a name="Goals"></a>
<h2>Goals</h2><br>

We compiled a semi-global database that includes crop production contributions by farm size in order to move policy debates beyond faulty estimates and test the accuracy of the past attempts to measure smallholder production contributions. Quantifying the production contributions of smallholders allows for: 1) baseline assessment of semi-global patterns, 2) regional and cross-national comparisons, and 3) linkages with other global datasets (e.g., climate, crop land, water availability, etc.).

<a name="Data"></a>
<h2>Data</h2><br>

All available national census statistics that report crop production and/or harvest area by farm size were compiled into a single dataset ([see data coverage python notebook for details](https://vinnyricciardi.github.io/farmsize_site/Html/Data_Coverage)). Since many sub-national level datasets do not report production by farm size, our main dataset captures harvested area by farm size per crop. A second dataset was compiled and used as a yield look up table per crop per farm size class. Due to the IR, this yield look up table will be necessary to calculate a more accurate estimate of production contributions by farm size stratum than previous attempts (5,8).

<a name="Analysis"></a>
<h2>Analysis</h2><br>

1.	What is the contribution of small farms to global food security?
a.	What percentage of smallholders’ production is grown for food versus other (based on FAO definitions)?
b.	How does this compare to largeholders’ production?<br><br>
2.	Are smallholders producing a greater diversity of crops than largeholders?
a.	We will test the relationship between farm size and contribution to diverse crop production using the Shannon-Weaver and Simpson’s indices, which are commonly used in ecology to represent biological diversity (9).<br><br>
3.	Are smallholders yielding more production than largeholders on the crops they both grow (IR)?
a.	This can be per crop and net yield, since net yield may be a better indication of food availability for smallholders, often reliant on short supply chains to local markets and subsistence-surplus production.

<a name="LeftOff"></a>

<a name="LeftOff"></a>
