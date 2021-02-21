# Documentation Generation



```
#exports
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

```
dev_nbs_dir = '.'
docs_dir = '../docs'
docs_nb_img_dir = f'{docs_dir}/img/nbs'
nb_img_dir = '../img/nbs'
```

<br>

### Converting Notebooks to Markdown

```
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

```
for nbs_dir in [dev_nbs_dir]:
    convert_nbs_to_md(nbs_dir, docs_nb_img_dir, docs_dir)
```


<div><span class="Text-label" style="display:inline-block; overflow:hidden; white-space:nowrap; text-overflow:ellipsis; min-width:0; max-width:15ex; vertical-align:middle; text-align:right"></span>
<progress style="width:60ex" max="7" value="7" class="Progress-main"/></progress>
<span class="Progress-label"><strong>100%</strong></span>
<span class="Iteration-label">7/7</span>
<span class="Time-label">[00:03<00:00, 0.36s/it]</span></div>


    <ipython-input-22-65cebc093f56>:22: UserWarning: images were failed to be exported for ./01-inputs.ipynb
      warn(f'images were failed to be exported for {nb_fp}')
    <ipython-input-22-65cebc093f56>:22: UserWarning: images were failed to be exported for ./02a-cmst.ipynb
      warn(f'images were failed to be exported for {nb_fp}')
    <ipython-input-22-65cebc093f56>:22: UserWarning: images were failed to be exported for ./03-costs.ipynb
      warn(f'images were failed to be exported for {nb_fp}')
    

<br>

### Cleaning Markdown Tables

```
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

```
md_fps = [f'{docs_dir}/{f}' for f in os.listdir(docs_dir) if f[-3:]=='.md' if f!='00-documentation.md']

for md_fp in md_fps:
    div_to_md_tables = clean_md_file_tables(md_fp)
```

<br>

### Cleaning Image Paths

```
#exports
def clean_md_file_img_fps(md_fp):
    with open(md_fp, 'r') as f:
        md_file_text = f.read()

    md_file_text = md_file_text.replace('../docs/img/nbs', 'img/nbs')

    with open(md_fp, 'w') as f:
        f.write(md_file_text)
        
    return
```

```
for md_fp in md_fps:
    clean_md_file_img_fps(md_fp)
```
