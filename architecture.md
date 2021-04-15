# Power Station Dictionary

This document outlines the motivation behind, and high-level structure of, a linked collection of power plant metadata that is both human- and machine-readable.

<br>

> N.b. this is a living document and the motivations, use-cases, and data structures are subject to change.

<br>
<br>

### Motivation & Solution Summary

To extract new insights from datasets usually several of them must be linked together - such as power plant output and emissions to determine carbon intensity. However, even if it is known that two public datasets describe common assets, the ids used to describe them are often inconsistent. A data dictionary would provide a single source of information on which assets are included in different datasets as well as how they can be joined. The dictionary would be programmatically generated from separate JSON descriptors of the assets, each with its own URL. Crucially, to add new information about an asset (or link it to a new dataset) the user would need only to edit a couple of lines in a publicly available and version controlled JSON file.

<br>
<br>

### Dictionary Generation Steps

1. The ground-truth for the dictionary will be a collection of highly human-readable JSON files, reducing friction for users to edit and add new information.
2. A mapping will then describe how these JSON files can be transformed into OWL/RDF, enabling standardised integration of the dictionary components to external systems.
3. A summary of the dictionary will then be generated using SPARQL queries to create csv files of the power plant attributes and id pairings, as well as aggregated JSON objects for the data-links and object-links.
4. The dictionary summary will be packaged using the OKF data standard and a further RDF object will be used to describe it.
5. The RDF dictionary summary will use DCAT descriptors that enable automated integration into a CKAN repository.
6. The RDF instances of each power plant will be used to generate human-focused HTML summaries, containing json-ld within the header (enabling easier integration into Google's Knowledge Graph).

Each time a pull-request is made to change one of the ground-truth JSON files a series of checks will be made. First it will be confirmed that all of the attributes in the file can be mapped to RDF elements, then after the RDF instantiations of each plant have been generated the validity of the graph will be checked using standard OWL tools (e.g. with `owlready2`). Only once these checks have passed will the new dictionary be published and a new version assigned (to ensure backwards compatability of the RDF graph).

<br>
<br>

### Data Structures

#### Ground-Truth JSON Files

Each individual power plant will have a url which returns a highly human-readable JSON description of that asset.

Included are:

- attributes - key:value pairs that describe the assets characteristics
- data-links - mappings from ids of the asset to the datasets that use them
- object-links - mappings to other objects that relate to the asset

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
    "longitude": -4.042969
  },
  "data_links": {
    "gppd": {
      "id": "GBR0003489",
      "datasets": [
        {
          "name": "Global Power Plant Database",
          "url": "https://github.com/wri/global-power-plant-database",
          "id_field": "gppd_idnr"
        }
      ]
    },
    "bmu": {
      "id": "T_WHILW-1",
      "datasets": [
        {
          "name": "Detailed System Prices",
          "url": "https://www.bmreports.com/bmrs/?q=balancing/detailprices",
          "id_field": "Id"
        },
        {
          "name": "Actual Generation Output Per Generation Unit",
          "url": "https://www.bmreports.com/bmrs/?q=actgenration/actualgeneration",
          "id_field": "BM Unit ID"
        }
      ]
    },
    "beis": {
      "id": 3489,
      "datasets": [
        {
          "name": "Renewable Power Plants UK",
          "url": "https://data.open-power-system-data.org/renewable_power_plants/",
          "id_field": "uk_beis_id"
        }
      ]
    }
  },
  "object_links": [
    {
      "url": "https://osuked.github.io/Wind-Farms/sites/10253.json",
      "relationship": "extension"
    }
  ]
}
```

<br>

#### OWL/RDF

N.b. All objects with OEO exist within the open-energy-ontology namespaces

Existing Classes/Properties:

- Types of power plant [offshore_wind: OEO_00000308, onshore_wind: OEO_00000311, solar_plant: OEO_00000386, solar_park: OEO_00000165]
- Plant components [turbine: OEO_00000448, pv_panel: OEO_00000348]
- Plant component attributes [turbine_hub_height: OEO_00140000]
- Fuel types [wind: OEO_00000446, solar: OEO_00000384]
- Longitude and latitude [xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"]

Required Additional Classes/Properties:

- IdType (e.g. "BMU_id"), links to instances of IdField, should have a string or integer value
- IdField (e.g. "BM Unit ID"), link to instances of IdType and KeyDataset, should have a string or integer value
- KeyDataset (e.g. "Detailed System Prices"), has the requirement of containing at least 1 IdField

Useful Additional Classes/Properties:

- OWL relationship to represent 'an extension of' (e.g. to describe the connection between Walney and Walney Extension)

<br>

#### Dictionary

Using a list of urls linked to assets using the metadata structure described above we would then programmatically generate a dictionary that summarises the data linkages and attributes for a given type of asset. A generalised version of the outputted data package can be seen below.

<img src="https://github.com/OSUKED/Wind-Farms/raw/main/img/diagram.png" width="75%"/>

<br>

Using our previous example we'll explore what each of these four dictionary components would look like for a single asset.

##### Attributes

| asset_url                                            | name               | fuel_type | capacity_mw | latitude | longitude |
| :--------------------------------------------------- | :----------------- | :-------- | ----------: | -------: | --------: |
| https://osuked.github.io/Wind-Farms/sites/10252.json | Whitelee Wind Farm | wind      |         322 |  55.7024 |  -4.04297 |

<br>

##### Synonyms

| asset_url                                            | gppd       | bmu       | beis |
| :--------------------------------------------------- | :--------- | :-------- | ---: |
| https://osuked.github.io/Wind-Farms/sites/10252.json | GBR0003489 | T_WHILW-1 | 3489 |

<br>

##### Data-Links

This could also be represented as a multi-index table

```json
{
  "gppd": {
    "id": "GBR0003489",
    "datasets": [
      {
        "name": "Global Power Plant Database",
        "url": "https://github.com/wri/global-power-plant-database",
        "id_field": "gppd_idnr"
      }
    ]
  },
  "bmu": {
    "id": "T_WHILW-1",
    "datasets": [
      {
        "name": "Detailed System Prices",
        "url": "https://www.bmreports.com/bmrs/?q=balancing/detailprices",
        "id_field": "Id"
      },
      {
        "name": "Actual Generation Output Per Generation Unit",
        "url": "https://www.bmreports.com/bmrs/?q=actgenration/actualgeneration",
        "id_field": "BM Unit ID"
      }
    ]
  },
  "beis": {
    "id": 3489,
    "datasets": [
      {
        "name": "Renewable Power Plants UK",
        "url": "https://data.open-power-system-data.org/renewable_power_plants/",
        "id_field": "uk_beis_id"
      }
    ]
  }
}
```

<br>

##### Object-Links

This could also be represented as a table of triplets with the columns `subject`, `object`, and `predicate`

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

- [us-cities.survey](http://us-cities.survey.okfn.org/) - Very similar to the general dictionary idea, provides additional information about the quality of the datasets it links to.
- [open-power-system-data](https://open-power-system-data.org/) - Provides information on the attributes of power plants across the EU. They use the OKF Data Package standard for their outputs which can enable automated integration into external systems. The datasets are generated programmatically with the full workflow made publicly available on GitHub.
- [wikidata](https://www.wikidata.org/wiki/Wikidata:Main_Page) - Already has machine-readable representations of very specific power plants, [e.g. Horns Rev 2](https://www.wikidata.org/wiki/Special:EntityData/Q5904482.json). In a few instances wikidata includes information on the Google Knowledge Graph id, [e.g](https://www.google.com/search?kgmid=/g/121_jr0r).
- [open-energy-ontology](https://openenergy-platform.org/ontology/oeo) - Provides an energy specific ontology for both the objects and relationships being described by the dictionary. Similarly there's also the CIM - as the relationships within this single dictionary are relatively simple it should be possible to map to both ontologies. Lots of ways this could benefit [automatic discovery](https://developers.google.com/search/docs/data-types/dataset#example) on google dataset search.
