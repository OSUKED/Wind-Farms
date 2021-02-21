# Initialisation



```python
#exports
import json
import numpy as np
import pandas as pd
```

```python
from IPython.display import JSON
```

<br>

### User Inputs

```python
raw_data_dir = '../data/raw'
wind_farms_dir = '../data/endpoints/wind_farms'
```

```python
df_power_dict = pd.read_csv(f'{raw_data_dir}/power_dict.csv', index_col='osuked_id')

df_power_dict.head()
```




|   ('Unnamed: 0_level_0', 'osuked_id') | ('esail_id', 'Unnamed: 1_level_1')   | ('gppd_idnr', 'Unnamed: 2_level_1')   | ('name', 'Unnamed: 3_level_1')   | ('sett_bmu_id', 'Unnamed: 4_level_1')             |   ('longitude', 'Unnamed: 5_level_1') |   ('latitude', 'Unnamed: 6_level_1') | ('fuel_type', 'Unnamed: 7_level_1')   |   ('capacity_mw', 'Unnamed: 8_level_1') |
|--------------------------------------:|:-------------------------------------|:--------------------------------------|:---------------------------------|:--------------------------------------------------|--------------------------------------:|-------------------------------------:|:--------------------------------------|----------------------------------------:|
|                                 10000 | MARK                                 | nan                                   | Rothes Bio-Plant CHP             | E_MARK-1, E_MARK-2                                |                             -3.60352  |                              57.4804 | biomass                               |                                     nan |
|                                 10001 | DIDC                                 | nan                                   | Didcot A (G)                     | T_DIDC1, T_DIDC2, T_DIDC4, T_DIDC3                |                             -1.26757  |                              51.6236 | coal                                  |                                     nan |
|                                 10002 | ABTH                                 | GBR1000374                            | Aberthaw B                       | T_ABTH7, T_ABTH8, T_ABTH9                         |                             -3.40487  |                              51.3873 | coal                                  |                                    1586 |
|                                 10003 | COTPS                                | GBR1000142                            | Cottam                           | T_COTPS-1, T_COTPS-2, T_COTPS-3, T_COTPS-4        |                             -0.648193 |                              53.2455 | coal                                  |                                    2008 |
|                                 10004 | DRAXX                                | GBR0000174                            | Drax                             | T_DRAXX-1, T_DRAXX-2, T_DRAXX-3, T_DRAXX-4, T_... |                             -0.626221 |                              53.7487 | coal, biomass                         |                                    1980 |</div>



<br>

### Cleaning Data

```python
def check_nan(val):
    try:
        is_nan = np.isnan(val)
    except:
        is_nan = False
    
    return is_nan

remove_dict_nan_val = lambda dict_: {k: v for k, v in dict_.items() if check_nan(v)==False}
sett_bmu_ids_to_list = lambda dict_: {k: v.split(', ') if k=='sett_bmu_id' else v for k, v in dict_.items()}

df_wind = df_power_dict.query('fuel_type=="wind"')

wfs = [sett_bmu_ids_to_list(remove_dict_nan_val(wf)) for wf in df_wind.to_dict(orient='records')]
osuked_id_to_wf = dict(zip(df_wind.index, wfs))

JSON([osuked_id_to_wf])
```




    <IPython.core.display.JSON object>



<br>

### Saving Data

```python
for osuked_id, wf in osuked_id_to_wf.items():
    with open(f'{wind_farms_dir}/{osuked_id}.json', 'w') as fp:
        json.dump(wf, fp)
```
