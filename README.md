smapr
================

[![Build Status](https://travis-ci.com/mbjoseph/smapr.svg?token=cyseeEQGyeK9iSxrdQsF&branch=master)](https://travis-ci.com/mbjoseph/smapr) [![codecov](https://codecov.io/gh/mbjoseph/smapr/branch/master/graph/badge.svg?token=UfxG4DDJ5H)](https://codecov.io/gh/mbjoseph/smapr)

An R package for acquisition and processing of NASA (Soil Moisture Active-Passive) SMAP data

Installation
------------

Development version:

``` r
devtools::install_github("mbjoseph/smapr")
```

### Finding data

Data are hosted on an FTP server by the National Snow and Ice Data Center. The `find_smap` function searches for specific data products and returns a data frame of available data.

``` r
library("smapr")

files <- find_smap(id = "SPL3SMP", date = "2015.05.01", version = 3)
files
#>                               name       date                 ftp_dir
#> 1 SMAP_L3_SM_P_20150501_R13080_001 2015-05-01 SPL3SMP.003/2015.05.01/
```

### Downloading data

Once found, data can be downloaded with `download_smap`.

``` r
downloads <- download_smap(files)
downloads
#>                               name       date                 ftp_dir
#> 1 SMAP_L3_SM_P_20150501_R13080_001 2015-05-01 SPL3SMP.003/2015.05.01/
#>                             local_dir
#> 1 /Users/majo3748/Library/Caches/smap
```

### Extracting data

The `extract_smap` function extracts gridded data products (e.g., global soil moisture) and returns Raster\* objects with the proper spatial projections etc.

``` r
r <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/soil_moisture')
r
#> class       : RasterLayer 
#> dimensions  : 406, 964, 391384  (nrow, ncol, ncell)
#> resolution  : 36032.22, 36032.22  (x, y)
#> extent      : -17367530, 17367530, -7314540, 7314540  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 
#> data source : /Users/majo3748/Library/Caches/smap/tmp.tif 
#> names       : SMAP_L3_SM_P_20150501_R13080_001 
#> values      : 0.02, 0.9390723  (min, max)
```

### Plotting the data

Plotting is best done with the `raster` or `rasterVis` packages.

``` r
raster::plot(r, main = "Soil Moisture: May 01, 2015")
```

![](inst/img/unnamed-chunk-6-1.png)

### Inspecting data

The SMAP data are provided in HDF5 format, and in any one file there are actually multiple data sets, including metadata. The `list_smap` function allows users to inspect the contents of downloaded data.

``` r
list_smap(downloads, all = TRUE)
#> $SMAP_L3_SM_P_20150501_R13080_001
#>                                  group                         name
#> 0                                    /                     Metadata
#> 1                            /Metadata       AcquisitionInformation
#> 2     /Metadata/AcquisitionInformation                     platform
#> 3     /Metadata/AcquisitionInformation             platformDocument
#> 4     /Metadata/AcquisitionInformation                        radar
#> 5     /Metadata/AcquisitionInformation                radarDocument
#> 6     /Metadata/AcquisitionInformation                   radiometer
#> 7     /Metadata/AcquisitionInformation           radiometerDocument
#> 8                            /Metadata                  DataQuality
#> 9                /Metadata/DataQuality         CompletenessOmission
#> 10               /Metadata/DataQuality            DomainConsistency
#> 11                           /Metadata        DatasetIdentification
#> 12                           /Metadata                       Extent
#> 13                           /Metadata    GridSpatialRepresentation
#> 14 /Metadata/GridSpatialRepresentation                       Column
#> 15 /Metadata/GridSpatialRepresentation               GridDefinition
#> 16 /Metadata/GridSpatialRepresentation       GridDefinitionDocument
#> 17 /Metadata/GridSpatialRepresentation                          Row
#> 18                           /Metadata                      Lineage
#> 19                   /Metadata/Lineage               EASEGRID_LON_M
#> 20                   /Metadata/Lineage           InputConfiguration
#> 21                   /Metadata/Lineage                      L2_SM_P
#> 22                   /Metadata/Lineage        MetadataConfiguration
#> 23                   /Metadata/Lineage          OutputConfiguration
#> 24                   /Metadata/Lineage             RunConfiguration
#> 25                           /Metadata        OrbitMeasuredLocation
#> 26                           /Metadata                  ProcessStep
#> 27                           /Metadata ProductSpecificationDocument
#> 28                           /Metadata      QADatasetIdentification
#> 29                           /Metadata         SeriesIdentification
#> 30                                   / Soil_Moisture_Retrieval_Data
#> 31       /Soil_Moisture_Retrieval_Data            EASE_column_index
#> 32       /Soil_Moisture_Retrieval_Data               EASE_row_index
#> 33       /Soil_Moisture_Retrieval_Data                       albedo
#> 34       /Soil_Moisture_Retrieval_Data          boresight_incidence
#> 35       /Soil_Moisture_Retrieval_Data         freeze_thaw_fraction
#> 36       /Soil_Moisture_Retrieval_Data              landcover_class
#> 37       /Soil_Moisture_Retrieval_Data     landcover_class_fraction
#> 38       /Soil_Moisture_Retrieval_Data                     latitude
#> 39       /Soil_Moisture_Retrieval_Data            latitude_centroid
#> 40       /Soil_Moisture_Retrieval_Data                    longitude
#> 41       /Soil_Moisture_Retrieval_Data           longitude_centroid
#> 42       /Soil_Moisture_Retrieval_Data    radar_water_body_fraction
#> 43       /Soil_Moisture_Retrieval_Data          retrieval_qual_flag
#> 44       /Soil_Moisture_Retrieval_Data        roughness_coefficient
#> 45       /Soil_Moisture_Retrieval_Data                soil_moisture
#> 46       /Soil_Moisture_Retrieval_Data          soil_moisture_error
#> 47       /Soil_Moisture_Retrieval_Data   static_water_body_fraction
#> 48       /Soil_Moisture_Retrieval_Data                 surface_flag
#> 49       /Soil_Moisture_Retrieval_Data          surface_temperature
#> 50       /Soil_Moisture_Retrieval_Data               tb_3_corrected
#> 51       /Soil_Moisture_Retrieval_Data               tb_4_corrected
#> 52       /Soil_Moisture_Retrieval_Data               tb_h_corrected
#> 53       /Soil_Moisture_Retrieval_Data               tb_qual_flag_3
#> 54       /Soil_Moisture_Retrieval_Data               tb_qual_flag_4
#> 55       /Soil_Moisture_Retrieval_Data               tb_qual_flag_h
#> 56       /Soil_Moisture_Retrieval_Data               tb_qual_flag_v
#> 57       /Soil_Moisture_Retrieval_Data              tb_time_seconds
#> 58       /Soil_Moisture_Retrieval_Data                  tb_time_utc
#> 59       /Soil_Moisture_Retrieval_Data               tb_v_corrected
#> 60       /Soil_Moisture_Retrieval_Data           vegetation_opacity
#> 61       /Soil_Moisture_Retrieval_Data     vegetation_water_content
#>          otype  dclass           dim
#> 0    H5I_GROUP                      
#> 1    H5I_GROUP                      
#> 2    H5I_GROUP                      
#> 3    H5I_GROUP                      
#> 4    H5I_GROUP                      
#> 5    H5I_GROUP                      
#> 6    H5I_GROUP                      
#> 7    H5I_GROUP                      
#> 8    H5I_GROUP                      
#> 9    H5I_GROUP                      
#> 10   H5I_GROUP                      
#> 11   H5I_GROUP                      
#> 12   H5I_GROUP                      
#> 13   H5I_GROUP                      
#> 14   H5I_GROUP                      
#> 15   H5I_GROUP                      
#> 16   H5I_GROUP                      
#> 17   H5I_GROUP                      
#> 18   H5I_GROUP                      
#> 19   H5I_GROUP                      
#> 20   H5I_GROUP                      
#> 21   H5I_GROUP                      
#> 22   H5I_GROUP                      
#> 23   H5I_GROUP                      
#> 24   H5I_GROUP                      
#> 25   H5I_GROUP                      
#> 26   H5I_GROUP                      
#> 27   H5I_GROUP                      
#> 28   H5I_GROUP                      
#> 29   H5I_GROUP                      
#> 30   H5I_GROUP                      
#> 31 H5I_DATASET INTEGER     964 x 406
#> 32 H5I_DATASET INTEGER     964 x 406
#> 33 H5I_DATASET   FLOAT     964 x 406
#> 34 H5I_DATASET   FLOAT     964 x 406
#> 35 H5I_DATASET   FLOAT     964 x 406
#> 36 H5I_DATASET INTEGER 3 x 964 x 406
#> 37 H5I_DATASET   FLOAT 3 x 964 x 406
#> 38 H5I_DATASET   FLOAT     964 x 406
#> 39 H5I_DATASET   FLOAT     964 x 406
#> 40 H5I_DATASET   FLOAT     964 x 406
#> 41 H5I_DATASET   FLOAT     964 x 406
#> 42 H5I_DATASET   FLOAT     964 x 406
#> 43 H5I_DATASET INTEGER     964 x 406
#> 44 H5I_DATASET   FLOAT     964 x 406
#> 45 H5I_DATASET   FLOAT     964 x 406
#> 46 H5I_DATASET   FLOAT     964 x 406
#> 47 H5I_DATASET   FLOAT     964 x 406
#> 48 H5I_DATASET INTEGER     964 x 406
#> 49 H5I_DATASET   FLOAT     964 x 406
#> 50 H5I_DATASET   FLOAT     964 x 406
#> 51 H5I_DATASET   FLOAT     964 x 406
#> 52 H5I_DATASET   FLOAT     964 x 406
#> 53 H5I_DATASET INTEGER     964 x 406
#> 54 H5I_DATASET INTEGER     964 x 406
#> 55 H5I_DATASET INTEGER     964 x 406
#> 56 H5I_DATASET INTEGER     964 x 406
#> 57 H5I_DATASET   FLOAT     964 x 406
#> 58 H5I_DATASET  STRING     964 x 406
#> 59 H5I_DATASET   FLOAT     964 x 406
#> 60 H5I_DATASET   FLOAT     964 x 406
#> 61 H5I_DATASET   FLOAT     964 x 406
```

### Saving as a GeoTIFF

Users can save the rasters as GeoTIFFs with the `raster` package.

``` r
raster::writeRaster(r, filename = "smap.tif")
```
