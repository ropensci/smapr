smapr
================

[![Build Status](https://travis-ci.org/earthlab/smapr.svg?branch=master)](https://travis-ci.org/earthlab/smapr) [![codecov](https://codecov.io/gh/earthlab/smapr/branch/master/graph/badge.svg)](https://codecov.io/gh/earthlab/smapr) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/smapr)](https://cran.r-project.org/package=smapr) [![Licence](https://img.shields.io/badge/licence-GPL--2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) [![Last-changedate](https://img.shields.io/badge/last%20change-2017--02--16-brightgreen.svg)](/commits/master)

An R package for acquisition and processing of [NASA (Soil Moisture Active-Passive) SMAP data](http://smap.jpl.nasa.gov/)

Installation
------------

### Dependencies

To install smapr, you'll need the following R packages:

-   curl
-   httr
-   rappdirs
-   raster
-   rgdal
-   rhdf5
-   utils

Note that rhdf5 is a [Bioconductor](http://bioconductor.org/) package, and will not be installed by default when trying to install smapr via `install.packages`. For rhdf5 installation instructions see <http://bioconductor.org/packages/release/bioc/html/rhdf5.html>

To install from CRAN:

``` r
install.packages("smapr")
```

Development version:

``` r
devtools::install_github("earthlab/smapr")
```

Authentication
--------------

Access to the NASA SMAP data requires authentication through NASA's Earthdata portal. If you do not already have a username and password through Earthdata, you can register for an account here: <https://urs.earthdata.nasa.gov/> You cannot use this package without an Earthdata account.

Once you have an account, you need to pass your Earthdata username (`ed_un`) and password (`ed_pw`) as environmental variables that can be read from within your R session. There are a couple of ways to do this:

1.  Use `Sys.setenv()` interactively in your R session to set your username and password (not including the `<` and `>`):

``` r
Sys.setenv(ed_un = "<your username>", ed_pw = "<your password>")
```

1.  Use `Sys.setenv()` in your `.Rprofile` to set those environmental variables every time you load R.

### Finding data

Data are hosted on an FTP server by the National Snow and Ice Data Center. The `find_smap` function searches for specific data products and returns a data frame of available data.

``` r
library("smapr")

files <- find_smap(id = "SPL3SMP", date = "2015-05-01", version = 4)
files
#>                               name       date                     dir
#> 1 SMAP_L3_SM_P_20150501_R14010_001 2015-05-01 SPL3SMP.004/2015.05.01/
```

### Downloading data

Once found, data can be downloaded with `download_smap`.

``` r
downloads <- download_smap(files)
downloads
#>                               name       date                     dir
#> 1 SMAP_L3_SM_P_20150501_R14010_001 2015-05-01 SPL3SMP.004/2015.05.01/
#>                             local_dir
#> 1 /Users/majo3748/Library/Caches/smap
```

### Extracting data

The `extract_smap` function extracts gridded data products (e.g., global soil moisture) and returns Raster\* objects with the proper spatial projections etc.

``` r
r <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data_AM/soil_moisture')
r
#> class       : RasterLayer 
#> dimensions  : 406, 964, 391384  (nrow, ncol, ncell)
#> resolution  : 36032.22, 36032.22  (x, y)
#> extent      : -17367530, 17367530, -7314540, 7314540  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 
#> data source : /Users/majo3748/Library/Caches/smap/tmp.tif 
#> names       : SMAP_L3_SM_P_20150501_R14010_001 
#> values      : 0.02, 0.9390723  (min, max)
```

### Plotting the data

Plotting is best done with the `raster` or `rasterVis` packages.

``` r
raster::plot(r, main = "AM Soil Moisture: May 01, 2015")
```

![](inst/img/unnamed-chunk-8-1.png)

### Inspecting data

The SMAP data are provided in HDF5 format, and in any one file there are actually multiple data sets, including metadata. The `list_smap` function allows users to inspect the contents of downloaded data.

``` r
list_smap(downloads, all = TRUE)
#> $SMAP_L3_SM_P_20150501_R14010_001
#>                                  group                            name
#> 0                                    /                        Metadata
#> 1                            /Metadata          AcquisitionInformation
#> 2     /Metadata/AcquisitionInformation                        platform
#> 3     /Metadata/AcquisitionInformation                platformDocument
#> 4     /Metadata/AcquisitionInformation                           radar
#> 5     /Metadata/AcquisitionInformation                   radarDocument
#> 6     /Metadata/AcquisitionInformation                      radiometer
#> 7     /Metadata/AcquisitionInformation              radiometerDocument
#> 8                            /Metadata                     DataQuality
#> 9                /Metadata/DataQuality            CompletenessOmission
#> 10               /Metadata/DataQuality               DomainConsistency
#> 11                           /Metadata           DatasetIdentification
#> 12                           /Metadata                          Extent
#> 13                           /Metadata       GridSpatialRepresentation
#> 14 /Metadata/GridSpatialRepresentation                          Column
#> 15 /Metadata/GridSpatialRepresentation                  GridDefinition
#> 16 /Metadata/GridSpatialRepresentation          GridDefinitionDocument
#> 17 /Metadata/GridSpatialRepresentation                             Row
#> 18                           /Metadata                         Lineage
#> 19                   /Metadata/Lineage                  EASEGRID_LON_M
#> 20                   /Metadata/Lineage              InputConfiguration
#> 21                   /Metadata/Lineage                         L2_SM_P
#> 22                   /Metadata/Lineage           MetadataConfiguration
#> 23                   /Metadata/Lineage             OutputConfiguration
#> 24                   /Metadata/Lineage                RunConfiguration
#> 25                           /Metadata           OrbitMeasuredLocation
#> 26                           /Metadata                     ProcessStep
#> 27                           /Metadata    ProductSpecificationDocument
#> 28                           /Metadata         QADatasetIdentification
#> 29                           /Metadata            SeriesIdentification
#> 30                                   / Soil_Moisture_Retrieval_Data_AM
#> 31    /Soil_Moisture_Retrieval_Data_AM               EASE_column_index
#> 32    /Soil_Moisture_Retrieval_Data_AM                  EASE_row_index
#> 33    /Soil_Moisture_Retrieval_Data_AM                          albedo
#> 34    /Soil_Moisture_Retrieval_Data_AM             boresight_incidence
#> 35    /Soil_Moisture_Retrieval_Data_AM            freeze_thaw_fraction
#> 36    /Soil_Moisture_Retrieval_Data_AM                 landcover_class
#> 37    /Soil_Moisture_Retrieval_Data_AM        landcover_class_fraction
#> 38    /Soil_Moisture_Retrieval_Data_AM                        latitude
#> 39    /Soil_Moisture_Retrieval_Data_AM               latitude_centroid
#> 40    /Soil_Moisture_Retrieval_Data_AM                       longitude
#> 41    /Soil_Moisture_Retrieval_Data_AM              longitude_centroid
#> 42    /Soil_Moisture_Retrieval_Data_AM       radar_water_body_fraction
#> 43    /Soil_Moisture_Retrieval_Data_AM             retrieval_qual_flag
#> 44    /Soil_Moisture_Retrieval_Data_AM           roughness_coefficient
#> 45    /Soil_Moisture_Retrieval_Data_AM                   soil_moisture
#> 46    /Soil_Moisture_Retrieval_Data_AM             soil_moisture_error
#> 47    /Soil_Moisture_Retrieval_Data_AM      static_water_body_fraction
#> 48    /Soil_Moisture_Retrieval_Data_AM                    surface_flag
#> 49    /Soil_Moisture_Retrieval_Data_AM             surface_temperature
#> 50    /Soil_Moisture_Retrieval_Data_AM                  tb_3_corrected
#> 51    /Soil_Moisture_Retrieval_Data_AM                  tb_4_corrected
#> 52    /Soil_Moisture_Retrieval_Data_AM                  tb_h_corrected
#> 53    /Soil_Moisture_Retrieval_Data_AM                  tb_qual_flag_3
#> 54    /Soil_Moisture_Retrieval_Data_AM                  tb_qual_flag_4
#> 55    /Soil_Moisture_Retrieval_Data_AM                  tb_qual_flag_h
#> 56    /Soil_Moisture_Retrieval_Data_AM                  tb_qual_flag_v
#> 57    /Soil_Moisture_Retrieval_Data_AM                 tb_time_seconds
#> 58    /Soil_Moisture_Retrieval_Data_AM                     tb_time_utc
#> 59    /Soil_Moisture_Retrieval_Data_AM                  tb_v_corrected
#> 60    /Soil_Moisture_Retrieval_Data_AM              vegetation_opacity
#> 61    /Soil_Moisture_Retrieval_Data_AM        vegetation_water_content
#> 62                                   / Soil_Moisture_Retrieval_Data_PM
#> 63    /Soil_Moisture_Retrieval_Data_PM            EASE_column_index_pm
#> 64    /Soil_Moisture_Retrieval_Data_PM               EASE_row_index_pm
#> 65    /Soil_Moisture_Retrieval_Data_PM                       albedo_pm
#> 66    /Soil_Moisture_Retrieval_Data_PM          boresight_incidence_pm
#> 67    /Soil_Moisture_Retrieval_Data_PM         freeze_thaw_fraction_pm
#> 68    /Soil_Moisture_Retrieval_Data_PM     landcover_class_fraction_pm
#> 69    /Soil_Moisture_Retrieval_Data_PM              landcover_class_pm
#> 70    /Soil_Moisture_Retrieval_Data_PM            latitude_centroid_pm
#> 71    /Soil_Moisture_Retrieval_Data_PM                     latitude_pm
#> 72    /Soil_Moisture_Retrieval_Data_PM           longitude_centroid_pm
#> 73    /Soil_Moisture_Retrieval_Data_PM                    longitude_pm
#> 74    /Soil_Moisture_Retrieval_Data_PM    radar_water_body_fraction_pm
#> 75    /Soil_Moisture_Retrieval_Data_PM          retrieval_qual_flag_pm
#> 76    /Soil_Moisture_Retrieval_Data_PM        roughness_coefficient_pm
#> 77    /Soil_Moisture_Retrieval_Data_PM          soil_moisture_error_pm
#> 78    /Soil_Moisture_Retrieval_Data_PM                soil_moisture_pm
#> 79    /Soil_Moisture_Retrieval_Data_PM   static_water_body_fraction_pm
#> 80    /Soil_Moisture_Retrieval_Data_PM                 surface_flag_pm
#> 81    /Soil_Moisture_Retrieval_Data_PM          surface_temperature_pm
#> 82    /Soil_Moisture_Retrieval_Data_PM               tb_3_corrected_pm
#> 83    /Soil_Moisture_Retrieval_Data_PM               tb_4_corrected_pm
#> 84    /Soil_Moisture_Retrieval_Data_PM               tb_h_corrected_pm
#> 85    /Soil_Moisture_Retrieval_Data_PM               tb_qual_flag_3_pm
#> 86    /Soil_Moisture_Retrieval_Data_PM               tb_qual_flag_4_pm
#> 87    /Soil_Moisture_Retrieval_Data_PM               tb_qual_flag_h_pm
#> 88    /Soil_Moisture_Retrieval_Data_PM               tb_qual_flag_v_pm
#> 89    /Soil_Moisture_Retrieval_Data_PM              tb_time_seconds_pm
#> 90    /Soil_Moisture_Retrieval_Data_PM                  tb_time_utc_pm
#> 91    /Soil_Moisture_Retrieval_Data_PM               tb_v_corrected_pm
#> 92    /Soil_Moisture_Retrieval_Data_PM           vegetation_opacity_pm
#> 93    /Soil_Moisture_Retrieval_Data_PM     vegetation_water_content_pm
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
#> 62   H5I_GROUP                      
#> 63 H5I_DATASET INTEGER     964 x 406
#> 64 H5I_DATASET INTEGER     964 x 406
#> 65 H5I_DATASET   FLOAT     964 x 406
#> 66 H5I_DATASET   FLOAT     964 x 406
#> 67 H5I_DATASET   FLOAT     964 x 406
#> 68 H5I_DATASET   FLOAT 3 x 964 x 406
#> 69 H5I_DATASET INTEGER 3 x 964 x 406
#> 70 H5I_DATASET   FLOAT     964 x 406
#> 71 H5I_DATASET   FLOAT     964 x 406
#> 72 H5I_DATASET   FLOAT     964 x 406
#> 73 H5I_DATASET   FLOAT     964 x 406
#> 74 H5I_DATASET   FLOAT     964 x 406
#> 75 H5I_DATASET INTEGER     964 x 406
#> 76 H5I_DATASET   FLOAT     964 x 406
#> 77 H5I_DATASET   FLOAT     964 x 406
#> 78 H5I_DATASET   FLOAT     964 x 406
#> 79 H5I_DATASET   FLOAT     964 x 406
#> 80 H5I_DATASET INTEGER     964 x 406
#> 81 H5I_DATASET   FLOAT     964 x 406
#> 82 H5I_DATASET   FLOAT     964 x 406
#> 83 H5I_DATASET   FLOAT     964 x 406
#> 84 H5I_DATASET   FLOAT     964 x 406
#> 85 H5I_DATASET INTEGER     964 x 406
#> 86 H5I_DATASET INTEGER     964 x 406
#> 87 H5I_DATASET INTEGER     964 x 406
#> 88 H5I_DATASET INTEGER     964 x 406
#> 89 H5I_DATASET   FLOAT     964 x 406
#> 90 H5I_DATASET  STRING     964 x 406
#> 91 H5I_DATASET   FLOAT     964 x 406
#> 92 H5I_DATASET   FLOAT     964 x 406
#> 93 H5I_DATASET   FLOAT     964 x 406
```

### Saving as a GeoTIFF

Users can save the rasters as GeoTIFFs with the `raster` package.

``` r
raster::writeRaster(r, filename = "smap.tif")
```

### Running in Docker

To avoid dependency heck, we have made a Docker image available with smapr and all dependencies.

``` bash
docker run -it earthlab/smapr bash
```
