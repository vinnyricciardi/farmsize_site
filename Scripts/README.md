

### File descriptions<br>

#### check_processing.py
- Checks if combined processed file against all individual country files

#### crop_diversity_bootstrap.py
- Generates bootstrap graph output for crop diversity cumulative area by cumulative richness curves. Note, this process required external script because the Jupyter Notebook kernels could not handle the heavy plotting.

#### data_compilation.py
- Cleans and compiles all country level farm size data files and merges with the food, feed, other and nutrient conversions

#### fao_item_member_key_conversion.py
- Generates lookup table for FAOSTAT item code hierarchy. FAOSTAT commodity statistics are available at varying levels.

#### feed_food_other.py
- Cleans and compiles fao data to make two output files:
    1. food, feed, other
    2. nutrient conversions

#### ffo_interpolation.py & nutrition_interpolation.py
- Tester scripts for def in feed_food_other.py
- Interpolates FOA's feed, food, other and nutrition data