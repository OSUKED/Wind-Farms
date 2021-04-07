# Power Station Dictionary

This document outlines the motivation behind, and high-level structure of, a linked collection of power plant metadata that is both human- and machine-readable

<br>

> N.b. this is a living document and the motivations, use-cases, and data structures are subject to change.

<br>
<br>

### Motivation & Solution Summary

To extract new insights from datasets usually several of them must be linked together - such as power plant output and emissions to determine carbon intensity. However, even if it is known that two public datasets describe common assets, the ids used to describe them are often inconsistent. A data dictionary would provide a single source of information on which assets are included in different datasets as well as how they can be joined. The dictionary would be programmatically generated from separate JSON descriptors of the assets, each with its own URL. Crucially, to add new information about an asset (or link it to a new dataset) the user would need only to edit a couple of lines in a publicly available and version controlled JSON file.

<br>
<br>

### Data Structures

#### Asset Endpoints

Each individual power plant will have a url which returns a JSON description of that asset. 

Included are:
* attributes - key:value pairs that describe the assets characteristics
* data-links - mappings from ids of the asset to the datasets that use them
* object-links - mappings to other objects that relate to the asset

<br>

We'll use Whitelee wind farm as an example, the endpoint url would be structured something like https://osuked.github.io/Wind-Farms/sites/10252.json (N.b. currently a simpler data structure will be returned if you visit this link).

Note that some id fields change even within the same organisation. Additionally, aspects such as the relationships between objects will require a standardised ontology.

```json
{
	"attributes": {
		"name": "Whitelee Wind Farm",
		"fuel_type": "wind",
		"capacity_mw": 322,
		"latitude": 55.702355,
		"longitude": -4.042969,
	},
	"data_links": {
		"gppd": {
			"id": "GBR0003489",
			"datasets": [{
				"name": "Global Power Plant Database",
				"url": "https://github.com/wri/global-power-plant-database",
				"id_field": "gppd_idnr",
			}],
		},
		"bmu": {
			"id": "T_WHILW-1",
			"datasets": [{
					"name": "Detailed System Prices",
					"url": "https://www.bmreports.com/bmrs/?q=balancing/detailprices",
					"id_field": "Id"
				},
				{
					"name": "Actual Generation Output Per Generation Unit",
					"url": "https://www.bmreports.com/bmrs/?q=actgenration/actualgeneration",
					"id_field": "BM Unit ID"
				}
			],
		},
		"beis": {
			"id": 3489,
			"datasets": [{
				"name": "Renewable Power Plants UK",
				"url": "https://data.open-power-system-data.org/renewable_power_plants/",
				"id_field": "uk_beis_id"
			}]
		}
	},
	"object_links": [{
		"url": "https://osuked.github.io/Wind-Farms/sites/10253.json",
		"relationship": "extension"
	}]
}
```

<br>

#### Dictionary

Using a list of urls linked to assets using the metadata structure described above we would then programmatically generate a dictionary that summarises the data linkages and attributes for a given type of asset. A generalised version of the outputted data package can be seen below.

<img src="https://github.com/OSUKED/Wind-Farms/raw/main/img/diagram.png" width="75%"/>

<br>

Using our previous example we'll explore what each of these four dictionary components would look like for a single asset.

##### Attributes

| asset_url                                            | name               | fuel_type   |   capacity_mw |   latitude |   longitude |
|:-----------------------------------------------------|:-------------------|:------------|--------------:|-----------:|------------:|
| https://osuked.github.io/Wind-Farms/sites/10252.json | Whitelee Wind Farm | wind        |           322 |    55.7024 |    -4.04297 |

<br>

##### Synonyms


| asset_url                                            | gppd       | bmu       |   beis |
|:-----------------------------------------------------|:-----------|:----------|-------:|
| https://osuked.github.io/Wind-Farms/sites/10252.json | GBR0003489 | T_WHILW-1 |   3489 |

<br>

##### Data-Links

```json
{
    "gppd": {
        "id": "GBR0003489",
        "datasets": [{
            "name": "Global Power Plant Database",
            "url": "https://github.com/wri/global-power-plant-database",
            "id_field": "gppd_idnr",
        }],
    },
    "bmu": {
        "id": "T_WHILW-1",
        "datasets": [{
                "name": "Detailed System Prices",
                "url": "https://www.bmreports.com/bmrs/?q=balancing/detailprices",
                "id_field": "Id"
            },
            {
                "name": "Actual Generation Output Per Generation Unit",
                "url": "https://www.bmreports.com/bmrs/?q=actgenration/actualgeneration",
                "id_field": "BM Unit ID"
            }
        ],
    },
    "beis": {
        "id": 3489,
        "datasets": [{
            "name": "Renewable Power Plants UK",
            "url": "https://data.open-power-system-data.org/renewable_power_plants/",
            "id_field": "uk_beis_id"
        }]
    }
}
```

<br>

##### Object-Links

```json
[
    {
        "url": "https://osuked.github.io/Wind-Farms/sites/10253.json",
        "relationship": "extension"
    }
]
```

<br>
<br>

### Related Projects

* [us-cities.survey](http://us-cities.survey.okfn.org/) - Very similar to the general dictionary idea, provides additional information about the quality of the datasets it links to.
* [open-power-system-data](https://open-power-system-data.org/) - Provides information on the attributes of power plants across the EU. They use the OKF Data Package standard for their outputs which can enable automated integration into external systems.  The datasets are generated programmatically with the full workflow made publicly available on GitHub.
* [open-energy-ontology](https://openenergy-platform.org/ontology/oeo) - Provides an energy specific ontology for both the objects and relationships being described by the dictionary. I could ensure that everything I'm expressing in JSON is able to be mapped to their ontology, more long term could look into creating RDF/OWL compatible xml files for each power plant as an output. Similarly there's also the CIM - as the relationships within this single dictionary are relatively simple it should be possible to map to both ontologies.
