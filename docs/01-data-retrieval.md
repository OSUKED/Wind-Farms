# Data Retrieval



```python
#exports
import json
import numpy as np
import pandas as pd

import io
import requests
```

```python
from IPython.display import JSON
```

<br>

### User Inputs

```python
raw_data_dir = '../data/raw'
```

<br>

### Retrieving Wind Turbine Coordinates

We'll start by retrieving the wind farm data available from the crown estate wind resource map. We could use sources such as OpenStreetMap but the Crown Estate is a better primary source for this work.

```python
crown_estate_data_url = 'https://raw.githubusercontent.com/OSUKED/Crown-Estate-Watch/master/data/wind_farm_data.json'

crown_estate_data = requests.get(crown_estate_data_url).json()

JSON(crown_estate_data)
```




    <IPython.core.display.JSON object>



```python
with open(f'{raw_data_dir}/crown_estate.json', 'w') as fp:
    json.dump(crown_estate_data, fp)
```

<br>

### Power Station Dictionary

```python
power_dict_url = 'https://raw.githubusercontent.com/OSUKED/Power-Station-Dictionary/main/data/output/power_stations.csv'

power_dict_str = requests.get(power_dict_url).content
df_power_dict = pd.read_csv(io.StringIO(power_dict_str.decode('utf-8')), index_col='osuked_id')

df_power_dict.head()
```




|   ('Unnamed: 0_level_0', 'osuked_id') | ('esail_id', 'Unnamed: 1_level_1')   | ('gppd_idnr', 'Unnamed: 2_level_1')   | ('name', 'Unnamed: 3_level_1')   | ('sett_bmu_id', 'Unnamed: 4_level_1')             |   ('longitude', 'Unnamed: 5_level_1') |   ('latitude', 'Unnamed: 6_level_1') | ('fuel_type', 'Unnamed: 7_level_1')   |   ('capacity_mw', 'Unnamed: 8_level_1') |
|--------------------------------------:|:-------------------------------------|:--------------------------------------|:---------------------------------|:--------------------------------------------------|--------------------------------------:|-------------------------------------:|:--------------------------------------|----------------------------------------:|
|                                 10000 | MARK                                 | nan                                   | Rothes Bio-Plant CHP             | E_MARK-1, E_MARK-2                                |                             -3.60352  |                              57.4804 | biomass                               |                                     nan |
|                                 10001 | DIDC                                 | nan                                   | Didcot A (G)                     | T_DIDC1, T_DIDC2, T_DIDC4, T_DIDC3                |                             -1.26757  |                              51.6236 | coal                                  |                                     nan |
|                                 10002 | ABTH                                 | GBR1000374                            | Aberthaw B                       | T_ABTH7, T_ABTH8, T_ABTH9                         |                             -3.40487  |                              51.3873 | coal                                  |                                    1586 |
|                                 10003 | COTPS                                | GBR1000142                            | Cottam                           | T_COTPS-1, T_COTPS-2, T_COTPS-3, T_COTPS-4        |                             -0.648193 |                              53.2455 | coal                                  |                                    2008 |
|                                 10004 | DRAXX                                | GBR0000174                            | Drax                             | T_DRAXX-1, T_DRAXX-2, T_DRAXX-3, T_DRAXX-4, T_... |                             -0.626221 |                              53.7487 | coal, biomass                         |                                    1980 |</div>



```python
df_power_dict.to_csv(f'{raw_data_dir}/power_dict.csv')
```
