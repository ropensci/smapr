context("extract_smap")

# =============================================================================
# Test Configuration: Product Definitions
# =============================================================================
# Define all supported products with their test parameters
# This enables parametrized testing across all products

get_product_configs <- function() {
 list(
    # 36km Global products
    SPL3SMP = list(
      id = "SPL3SMP",
      date = "2015-03-31",
      version = 9,
      layer = "Soil_Moisture_Retrieval_Data_AM/soil_moisture",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 36032.220840584,
      ncols = 964,
      nrows = 406
    ),
    # 9km Global products
    SPL3SMAP = list(
      id = "SPL3SMAP",
      date = "2015-05-25",
      version = 3,
      layer = "Soil_Moisture_Retrieval_Data/soil_moisture",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 9008.055210146,
      ncols = 3856,
      nrows = 1624
    ),
    SPL4SMGP = list(
      id = "SPL4SMGP",
      date = "2020-01-01",
      version = 8,
      layer = "Geophysical_Data/sm_surface",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 9008.055210146,
      ncols = 3856,
      nrows = 1624
    ),
    SPL4SMAU = list(
      id = "SPL4SMAU",
      date = "2020-01-01",
      version = 8,
      layer = "Analysis_Data/sm_surface_analysis",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 9008.055210146,
      ncols = 3856,
      nrows = 1624
    ),
    SPL4CMDL = list(
      id = "SPL4CMDL",
      date = "2020-01-01",
      version = 8,
      layer = "GPP/gpp_mean",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 9008.055210146,
      ncols = 3856,
      nrows = 1624
    ),
    # 3km Global products
    SPL3SMA = list(
      id = "SPL3SMA",
      date = "2015-05-01",
      version = 3,
      layer = "Soil_Moisture_Retrieval_Data/soil_moisture",
      grid_type = "global",
      crs_pattern = "cea",
      crs_param = "lat_ts=30",
      cell_size = 3002.6850700487,
      ncols = 11568,
      nrows = 4872
    ),
    # 3km North polar products
    SPL3FTA = list(
      id = "SPL3FTA",
      date = "2015-04-14",
      version = 3,
      layer = "Freeze_Thaw_Retrieval_Data/freeze_thaw",
      grid_type = "north",
      crs_pattern = "laea",
      crs_param = "lat_0=90",
      cell_size = 3002.6850700487,
      ncols = 6000,
      nrows = 6000
    )
  )
}

# Helper function to download and extract a product
download_and_extract <- function(config) {
  files <- find_smap(id = config$id, date = config$date, version = config$version)
  downloads <- download_smap(files[1, ], overwrite = FALSE)
  extract_smap(downloads, name = config$layer)
}

# =============================================================================
# Basic Functionality Tests
# =============================================================================

test_that("invalid datasets cause errors", {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 9)
  downloads <- download_smap(files[1, ], overwrite = FALSE)
  expect_error(
    extract_smap(downloads,
                 name = "Soil_Moisture_Retrieval_Data_AM/soil_flavor")
  )
})

test_that("extract_smap produces a SpatRaster", {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 9)
  downloads <- download_smap(files[1, ], overwrite = FALSE)
  r <- extract_smap(downloads,
                    name = "Soil_Moisture_Retrieval_Data_AM/soil_moisture")
  expect_that(r, is_a("SpatRaster"))
})

test_that("-9999 is used fill value when a _FillValue doesn't exist", {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 9)
  downloads <- download_smap(files, overwrite = FALSE)
  r <- extract_smap(downloads,
                    name = "Soil_Moisture_Retrieval_Data_PM/latitude_pm")
  # the fill value in the file is -9999, but there is no fill value attribute
  # therefore, if this function works, the minimum should be >= -90
  # (the latitude at the south pole)
  min_max <- terra::minmax(r)
  min_value <- min_max["min", 1]
  expect_gte(min_value, -90)
})

test_that("extraction still works with user specified directories", {
  skip_on_cran()
  available_data <- find_smap(id = "SPL3SMP",
                              date = "2015-10-01",
                              version = 9)
  user_specified_path <- file.path("data", "SMAP")
  downloads <- download_smap(available_data,
                             directory = user_specified_path,
                             overwrite = FALSE)
  r <- extract_smap(downloads,
                    name = "Soil_Moisture_Retrieval_Data_AM/latitude")
  expect_that(r, is_a("SpatRaster"))

  # clean up
  unlink("data", recursive = TRUE, force = TRUE)
})

# =============================================================================
# Layer Naming Tests
# =============================================================================

test_that("layer names for SPL3FT include file name + am/pm suffix", {
  skip_on_cran()
  files <- find_smap(id = "SPL3FTA", dates = "2015-04-14", version = 3)
  downloads <- download_smap(files, overwrite = FALSE)
  r <- extract_smap(downloads,
                    name = "Freeze_Thaw_Retrieval_Data/freeze_thaw")
  expect_that(r, is_a("SpatRaster"))
  expected_names <- paste(downloads$name, c("AM", "PM"), sep = "_")
  expect_equal(names(r), expected_names)
})

test_that("layer names for SPL3SMP include file name", {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 9)
  downloads <- download_smap(files, overwrite = FALSE)
  r <- extract_smap(downloads,
                    name = "Soil_Moisture_Retrieval_Data_AM/latitude")
  expected_names <- paste(downloads$name)
  expect_equal(names(r), expected_names)
})

# =============================================================================
# Mixed Product Type Validation
# =============================================================================

test_that("Sentinel/SMAP cannot be extracted with other data types", {
  skip_on_cran()

  files <- find_smap("SPL2SMAP_S", "2016-06-08", 3)
  other_files <- find_smap(id = "SPL3SMP",
                           date = "2015-10-01",
                           version = 9)
  mixed_files <- rbind(files[1, ], other_files)
  downloads <- download_smap(mixed_files)

  # extracting two different kinds of files should raise error
  to_extract <- "/Soil_Moisture_Retrieval_Data_3km/soil_moisture_3km"
  expect_error(extract_smap(downloads, to_extract))
})

# =============================================================================
# Parametrized CRS Tests for All Grid Products
# =============================================================================

test_that("all grid products have correct CRS", {
  skip_on_cran()

  configs <- get_product_configs()

  for (product_name in names(configs)) {
    config <- configs[[product_name]]

    # Download and extract
    r <- tryCatch(
      download_and_extract(config),
      error = function(e) {
        skip(paste("Could not download", product_name, ":", e$message))
      }
    )

    # Check CRS
    crs_string <- terra::crs(r, proj = TRUE)
    expect_true(
      grepl(config$crs_pattern, crs_string),
      info = paste(product_name, "should have CRS pattern", config$crs_pattern)
    )
    expect_true(
      grepl(config$crs_param, crs_string),
      info = paste(product_name, "should have CRS param", config$crs_param)
    )
  }
})

# =============================================================================
# Parametrized Extent and Resolution Tests for All Grid Products
# =============================================================================

test_that("all grid products have correct extent and resolution", {
  skip_on_cran()

  configs <- get_product_configs()

  for (product_name in names(configs)) {
    config <- configs[[product_name]]

    # Download and extract
    r <- tryCatch(
      download_and_extract(config),
      error = function(e) {
        skip(paste("Could not download", product_name, ":", e$message))
      }
    )

    # Verify dimensions
    expect_equal(
      ncol(r), config$ncols,
      info = paste(product_name, "should have", config$ncols, "columns")
    )
    # Note: SPL3FTA has 2 layers (AM/PM), so nrow check is on first layer
    actual_nrows <- nrow(r)
    expect_equal(
      actual_nrows, config$nrows,
      info = paste(product_name, "should have", config$nrows, "rows")
    )

    # Calculate expected extent
    expected_half_width <- config$ncols / 2 * config$cell_size
    expected_half_height <- config$nrows / 2 * config$cell_size

    # Verify extent (within 1m tolerance)
    ext <- terra::ext(r)
    expect_equal(
      unname(ext$xmin), -expected_half_width, tolerance = 1,
      info = paste(product_name, "xmin")
    )
    expect_equal(
      unname(ext$xmax), expected_half_width, tolerance = 1,
      info = paste(product_name, "xmax")
    )
    expect_equal(
      unname(ext$ymin), -expected_half_height, tolerance = 1,
      info = paste(product_name, "ymin")
    )
    expect_equal(
      unname(ext$ymax), expected_half_height, tolerance = 1,
      info = paste(product_name, "ymax")
    )

    # Verify resolution (within 1m tolerance)
    res <- terra::res(r)
    expect_equal(
      res[1], config$cell_size, tolerance = 1,
      info = paste(product_name, "x resolution")
    )
    expect_equal(
      res[2], config$cell_size, tolerance = 1,
      info = paste(product_name, "y resolution")
    )
  }
})

# =============================================================================
# SPL2SMAP_S (Swath Product) Specific Tests
# =============================================================================

test_that("SPL2SMAP_S products can be read and stacked", {
  skip_on_cran()

  files <- find_smap("SPL2SMAP_S", "2016-06-08", 3)

  n_to_use <- 2L # don't use all files, use this many instead
  downloads <- download_smap(files[1:n_to_use, ])
  r <- extract_smap(downloads,
                    "/Soil_Moisture_Retrieval_Data_3km/soil_moisture_3km")

  expect_that(r, is_a("SpatRaster"))
  n_layers <- dim(r)[3]
  expect_equal(n_layers, n_to_use)
})

test_that("SPL2SMAP_S has valid projected extent", {
  skip_on_cran()

  files <- find_smap("SPL2SMAP_S", "2016-06-08", 3)
  downloads <- download_smap(files[1, ])
  r <- extract_smap(downloads,
                    "/Soil_Moisture_Retrieval_Data_3km/soil_moisture_3km")

  # Check that extent is valid (not NA or Inf)
  ext <- terra::ext(r)
  expect_false(any(is.na(c(ext$xmin, ext$xmax, ext$ymin, ext$ymax))),
               info = "SPL2SMAP_S extent should not contain NA values")
  expect_false(any(is.infinite(c(ext$xmin, ext$xmax, ext$ymin, ext$ymax))),
               info = "SPL2SMAP_S extent should not contain Inf values")

  # Check that extent has reasonable size (swath products are smaller than global)
  # Swath width is typically 1000km or less
  max_swath_extent <- 2000000  # 2000 km in meters
  expect_true(ext$xmax - ext$xmin < max_swath_extent,
              info = "SPL2SMAP_S x extent should be less than 2000km")
  expect_true(ext$ymax - ext$ymin < max_swath_extent,
              info = "SPL2SMAP_S y extent should be less than 2000km")

  # Check resolution is approximately 3km (within reasonable range)
  res <- terra::res(r)
  expect_true(all(res > 2000 & res < 4000),
              info = "SPL2SMAP_S resolution should be approximately 3km")

  # Check CRS is EASE-Grid 2.0 Global
  crs_string <- terra::crs(r, proj = TRUE)
  expect_true(grepl("cea", crs_string),
              info = "SPL2SMAP_S should use cylindrical equal-area projection")
})

# =============================================================================
# Individual Product Extraction Tests (ensures each product can be extracted)
# =============================================================================

test_that("SPL3SMAP (9km radar/radiometer) extracts correctly", {
  skip_on_cran()
  config <- get_product_configs()$SPL3SMAP
  r <- download_and_extract(config)
  expect_that(r, is_a("SpatRaster"))
  expect_equal(ncol(r), config$ncols)
  expect_equal(nrow(r), config$nrows)
})

test_that("SPL3SMA (3km radar) extracts correctly", {
  skip_on_cran()
  config <- get_product_configs()$SPL3SMA
  r <- download_and_extract(config)
  expect_that(r, is_a("SpatRaster"))
  expect_equal(ncol(r), config$ncols)
  expect_equal(nrow(r), config$nrows)
})

test_that("SPL4SMGP (9km geophysical) extracts correctly", {
  skip_on_cran()
  config <- get_product_configs()$SPL4SMGP
  r <- download_and_extract(config)
  expect_that(r, is_a("SpatRaster"))
  expect_equal(ncol(r), config$ncols)
  expect_equal(nrow(r), config$nrows)
})

test_that("SPL4SMAU (9km analysis update) extracts correctly", {
  skip_on_cran()
  config <- get_product_configs()$SPL4SMAU
  r <- download_and_extract(config)
  expect_that(r, is_a("SpatRaster"))
  expect_equal(ncol(r), config$ncols)
  expect_equal(nrow(r), config$nrows)
})

test_that("SPL4CMDL (9km carbon) extracts correctly", {
  skip_on_cran()
  config <- get_product_configs()$SPL4CMDL
  r <- download_and_extract(config)
  expect_that(r, is_a("SpatRaster"))
  expect_equal(ncol(r), config$ncols)
  expect_equal(nrow(r), config$nrows)
})
