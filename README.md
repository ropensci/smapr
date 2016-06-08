# smapr

[![Build Status](https://travis-ci.com/mbjoseph/smapr.svg?token=cyseeEQGyeK9iSxrdQsF&branch=master)](https://travis-ci.com/mbjoseph/smapr) [![codecov](https://codecov.io/gh/mbjoseph/smapr/branch/master/graph/badge.svg?token=UfxG4DDJ5H)](https://codecov.io/gh/mbjoseph/smapr)


An R package for acquisition and processing of NASA (Soil Moisture Active-Passive) SMAP data

## Installation

Development version:

```r
devtools::install_github("mbjoseph/smapr")
library("smapr")
```

### Finding data

Data are hosted on an FTP server by the National Snow and Ice Data Center. 
The `find_smap` function searches for specific data products and returns a data frame of available data.

```r
files <- find_smap(id = "SPL3SMP", date = "2015.03.31", version = 3)
```

### Downloading data

Once found, data can be downloaded with `download_smap`.

```r
downloads <- download_smap(files)
```

### Inspecting data

The SMAP data are provided in HDF5 format, and in any one file there are actually multiple data sets, including metadata. The `list_smap` function allows users to inspect the contents of downloaded data. 

```r
list_smap(downloads, all = TRUE)
```

### Extracting data

The `extract_smap` function extracts gridded data products (e.g., global soil moisture) and returns Raster* objects with the proper spatial projections etc.

```r
r <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/soil_moisture')
```

### Plotting the data

Plotting is best done with the `raster` or `rasterVis` packages. 

```r
raster::plot(r)
```

### Saving as a GeoTIFF

For various reasons, users may wish to save the rasters as GeoTIFFs. This is also easily done with the `raster` package. 

```r
raster::writeRaster(r, filename = "smap.tif")
```
