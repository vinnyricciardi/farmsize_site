#!/usr/bin/python

import pandas as pd
import numpy as np
from interp import iter_run


PATH_a = '/Users/Vinny_Ricciardi/Documents/Data_Library_Big/Survey/Global/'
PATH_b = 'Farm_Size/Data/FAO_FoodBalance/'

nut = pd.read_csv(PATH_a + PATH_b + 'nutrition.csv')
ffo = pd.read_csv(PATH_a + PATH_b + 'ffo.csv')

ffo['NAME_0'] = ffo.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")
nut['NAME_0'] = nut.NAME_0.replace("C\xf4te d'Ivoire", "Cote dIvoire")

ffo = iter_run(ffo)
nut = iter_run(nut)

print(ffo.head())
print(nut.head())

ffo.to_csv('/Users/Vinny_Ricciardi/Downloads/test_ffo_out.csv')
nut.to_csv('/Users/Vinny_Ricciardi/Downloads/test_nut_out.csv')