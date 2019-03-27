context("list_smap")

test_that("vector input causes errors", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-05-01", version = 5)
    downloads <- download_smap(files[1, ])
    expect_error(list_smap(downloads$local_file))
})

test_that("list_smap returns a list of data frames", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-05-01", version = 5)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    expect_that(contents, is_a("list"))
    expect_that(contents[[1]], is_a("data.frame"))
})

test_that("list_smap returns a data frame with the proper column names", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-05-01", version = 5)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    df_names <- names(contents[[1]])
    expected_names <- c('group', 'name', 'otype', 'dclass', 'dim')
    expect_equal(df_names, expected_names)
})
