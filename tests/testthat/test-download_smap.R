context("download_smap")

test_that("invalid output directories cause errors", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    expect_error(download_smap(files[1, ], dir = 1234))
})

test_that("non-existent directories are created", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    dir_name <- "silly_nonexistent_directory"
    downloads <- download_smap(files, directory = dir_name)
    expect_true(dir.exists(dir_name))
    # cleanup by removing directory
    unlink(dir_name, recursive = TRUE)
})

test_that("valid user-specified directories contain downloads", {
    skip_on_cran()
    available_data <- find_smap(id = "SPL3SMP",
                                date = "2015-10-01",
                                version = 7)
    user_specified_path <- file.path('data', 'SMAP')
    downloads <- download_smap(available_data,
                               directory = user_specified_path)
    files_in_path <- list.files(user_specified_path)
    extensions <- sort(unique(tools::file_ext(files_in_path)))
    expect_identical(c("h5", "qa", "xml"), extensions)

    # clean up
    unlink('data', recursive = TRUE, force = TRUE)
})

test_that("the downloaded data is of the data frame class", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
    downloads <- download_smap(files[1, ])
    expect_that(downloads, is_a("data.frame"))
})

test_that("Two SPL4CMDL data files are downloaded (h5 and xml)", {
    skip_on_cran()
    files <- find_smap(id = "SPL4CMDL", dates = "2015-05-01", version = 5)
    downloads <- download_smap(files[1, ])
    file_prefix <- downloads$name
    downloaded_files <- list.files(downloads$local_dir)
    relevant_files <- grepl(file_prefix, downloaded_files)

    number_of_downloaded_files <- sum(relevant_files)
    expect_equal(2, number_of_downloaded_files)

    relevant_filenames <- downloaded_files[relevant_files]
    extensions <- gsub(".*\\.", "", relevant_filenames)
    expect_equal(extensions, c('h5', 'xml'))
})

test_that("setting overwrite = FALSE prevents data from being overwritten", {
    skip_on_cran()
    get_last_modified <- function(downloads) {
        path <- file.path(downloads$local_dir, paste0(downloads$name, '.h5'))
        time <- file.info(path)$mtime
        as.numeric(time)
    }

    files <- find_smap(id = "SPL3SMP", date = "2015-03-31", version = 7)

    downloads <- download_smap(files)
    modified1 <- get_last_modified(downloads)

    # wait one second then download again
    Sys.sleep(1)
    downloads <- download_smap(files, overwrite = FALSE)
    modified2 <- get_last_modified(downloads)

    expect_equal(modified1, modified2)
})


test_that("setting overwrite = TRUE ensures data overwrite", {
    skip_on_cran()
    get_last_modified <- function(downloads) {
        path <- file.path(downloads$local_dir, paste0(downloads$name, '.h5'))
        time <- file.info(path)$mtime
        as.numeric(time)
    }

    files <- find_smap(id = "SPL3SMP", date = "2015-03-31", version = 7)

    downloads <- download_smap(files, overwrite = TRUE)
    modified1 <- get_last_modified(downloads)

    # wait one second then download again
    Sys.sleep(1)
    downloads <- download_smap(files, overwrite = TRUE)
    modified2 <- get_last_modified(downloads)

    expect_gt(modified2[1], modified1[1])
})


test_that('input data.frames with NA values raise errors', {
    skip_on_cran()
    expect_warning(df_w_na <- find_smap(id = "SPL2SMP_E",
                                        dates = '2015-05-13',
                                        version = 4))
    expect_error(download_smap(df_w_na))
})

test_that('verbose = TRUE prints output', {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
  downloads <- expect_message(download_smap(files[1, ], verbose = TRUE))
})

test_that('verbose = FALSE suppresses output', {
  skip_on_cran()
  files <- find_smap(id = "SPL3SMP", dates = "2015-03-31", version = 7)
  downloads <- expect_silent(download_smap(files[1, ], verbose = FALSE))
})
