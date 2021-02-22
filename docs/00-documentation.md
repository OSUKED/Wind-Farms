# Documentation Generation



```python
#exports
import json
import junix
import pandas as pd
from html.parser import HTMLParser
from nbdev.export2html import convert_md

import os
import codecs
from ipypb import track
from warnings import warn
from distutils.dir_util import copy_tree
```

<br>

### User Inputs

```python
dev_nbs_dir = '.'
docs_dir = '../docs'
docs_nb_img_dir = f'{docs_dir}/img/nbs'
nb_img_dir = '../img/nbs'
wind_farms_dir = '../data/endpoints/sites'
coverage_dir = '../data/endpoints/coverage'
```

<br>

### Converting Notebooks to Markdown

```python
#exports
def encode_file_as_utf8(fp):
    with codecs.open(fp, 'r') as file:
        contents = file.read(1048576)
        file.close()

        if not contents:
            pass
        else:
            with codecs.open(fp, 'w', 'utf-8') as file:
                file.write(contents)
            
def convert_nbs_to_md(nbs_dir, docs_nb_img_dir, docs_dir):
    nb_files = [f for f in os.listdir(nbs_dir) if f[-6:]=='.ipynb']

    for nb_file in track(nb_files):
        nb_fp = f'{nbs_dir}/{nb_file}'
        
        try:
            junix.export_images(nb_fp, docs_nb_img_dir)
        except:
            warn(f'images were failed to be exported for {nb_fp}')
            
        convert_md(nb_fp, docs_dir, img_path=f'{docs_nb_img_dir}/', jekyll=False)

        md_fp =  docs_dir + '/'+ nb_file.replace('.ipynb', '') + '.md'
        encode_file_as_utf8(md_fp)
```

```python
for nbs_dir in [dev_nbs_dir]:
    convert_nbs_to_md(nbs_dir, docs_nb_img_dir, docs_dir)
```


<div><span class="Text-label" style="display:inline-block; overflow:hidden; white-space:nowrap; text-overflow:ellipsis; min-width:0; max-width:15ex; vertical-align:middle; text-align:right"></span>
<progress style="width:60ex" max="4" value="4" class="Progress-main"/></progress>
<span class="Progress-label"><strong>100%</strong></span>
<span class="Iteration-label">4/4</span>
<span class="Time-label">[00:02<00:01, 0.52s/it]</span></div>


<br>

### Cleaning Markdown Tables

```python
#exports
class MyHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tags = []
    
    def handle_starttag(self, tag, attrs):
        self.tags.append(self.get_starttag_text())

    def handle_endtag(self, tag):
        self.tags.append(f"</{tag}>")
        
get_substring_idxs = lambda string, substring: [num for num in range(len(string)-len(substring)+1) if string[num:num+len(substring)]==substring]

def convert_df_to_md(df):
    idx_col = df.columns[0]
    df = df.set_index(idx_col)
    
    if idx_col == 'Unnamed: 0':
        df.index.name = ''
    
    table_md = df.to_markdown()
    
    return table_md

def extract_div_to_md_table(start_idx, end_idx, table_and_div_tags, file_txt):
    n_start_divs_before = table_and_div_tags[:start_idx].count('<div>')
    n_end_divs_before = table_and_div_tags[:end_idx].count('</div>')
    
    div_start_idx = get_substring_idxs(file_txt, '<div>')[n_start_divs_before-1]
    div_end_idx = get_substring_idxs(file_txt, '</div>')[n_end_divs_before]

    div_txt = file_txt[div_start_idx:div_end_idx]
    potential_dfs = pd.read_html(div_txt)
    
    assert len(potential_dfs) == 1, 'Multiple tables were found when there can be only one'
    df = potential_dfs[0]
    md_table = convert_df_to_md(df)

    return div_txt, md_table

def extract_div_to_md_tables(md_fp):
    with open(md_fp, 'r') as f:
        file_txt = f.read()
        
    parser = MyHTMLParser()
    parser.feed(file_txt)

    table_and_div_tags = [tag for tag in parser.tags if tag in ['<div>', '</div>', '<table border="1" class="dataframe">', '</table>']]
    
    table_start_tag_idxs = [i for i, tag in enumerate(table_and_div_tags) if tag=='<table border="1" class="dataframe">']
    table_end_tag_idxs = [table_start_tag_idx+table_and_div_tags[table_start_tag_idx:].index('</table>') for table_start_tag_idx in table_start_tag_idxs]

    div_to_md_tables = []

    for start_idx, end_idx in zip(table_start_tag_idxs, table_end_tag_idxs):
        div_txt, md_table = extract_div_to_md_table(start_idx, end_idx, table_and_div_tags, file_txt)
        div_to_md_tables += [(div_txt, md_table)]
        
    return div_to_md_tables

def clean_md_file_tables(md_fp):
    div_to_md_tables = extract_div_to_md_tables(md_fp)
    
    with open(md_fp, 'r') as f:
        md_file_text = f.read()

    for div_txt, md_txt in div_to_md_tables:
        md_file_text = md_file_text.replace(div_txt, md_txt)

    with open(md_fp, 'w') as f:
        f.write(md_file_text)
        
    return
```

```python
md_fps = [f'{docs_dir}/{f}' for f in os.listdir(docs_dir) if f[-3:]=='.md' if f!='00-documentation.md']

for md_fp in md_fps:
    div_to_md_tables = clean_md_file_tables(md_fp)
```

<br>

### Cleaning Image Paths

```python
#exports
def clean_md_file_img_fps(md_fp):
    with open(md_fp, 'r') as f:
        md_file_text = f.read()

    md_file_text = md_file_text.replace('../docs/img/nbs', 'img/nbs')

    with open(md_fp, 'w') as f:
        f.write(md_file_text)
        
    return
```

```python
for md_fp in md_fps:
    clean_md_file_img_fps(md_fp)
```

<br>

### GIS Data Coverage

```python
dict_has_keys = lambda dict_, keys: len(set(keys) - set(dict_.keys())) == 0

wf_GIS_coverage = dict()
wf_ids = [f.replace('.json', '') for f in os.listdir(wind_farms_dir) if '.json' in f]

for wf_id in wf_ids:
    with open(f'{wind_farms_dir}/{wf_id}.json', 'r') as fp:
        wf = json.load(fp)
    
    wf_GIS_coverage[wf_id] = dict()
    
    if 'name' in wf.keys():
        wf_GIS_coverage[wf_id]['name'] = wf['name']
    
    wf_GIS_coverage[wf_id]['lon/lat'] = dict_has_keys(wf, ['longitude', 'latitude'])
    wf_GIS_coverage[wf_id]['turbines'] = dict_has_keys(wf, ['turbine_coords'])
    wf_GIS_coverage[wf_id]['substations'] = dict_has_keys(wf, ['substation_coords'])
    
df_GIS_coverage = pd.DataFrame(wf_GIS_coverage).T
df_GIS_coverage.index.name = 'osuked_id'

df_GIS_coverage.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>name</th>
      <th>lon/lat</th>
      <th>turbines</th>
      <th>substations</th>
    </tr>
    <tr>
      <th>osuked_id</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>10147</th>
      <td>AChruach Wind Farm</td>
      <td>True</td>
      <td>False</td>
      <td>False</td>
    </tr>
    <tr>
      <th>10148</th>
      <td>Aikengall 2 Wind Farm Generation</td>
      <td>True</td>
      <td>False</td>
      <td>False</td>
    </tr>
    <tr>
      <th>10149</th>
      <td>Airies Windfarm</td>
      <td>True</td>
      <td>False</td>
      <td>False</td>
    </tr>
    <tr>
      <th>10150</th>
      <td>Andershaw Wind Farm</td>
      <td>True</td>
      <td>False</td>
      <td>False</td>
    </tr>
    <tr>
      <th>10151</th>
      <td>An Suidhe Windfarm</td>
      <td>True</td>
      <td>False</td>
      <td>False</td>
    </tr>
  </tbody>
</table>
</div>



```python
df_GIS_coverage.to_csv(f'{coverage_dir}/GIS.csv')
```
