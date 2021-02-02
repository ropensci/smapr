context("list_smap")

test_that("vector input causes errors", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-05-01", version = 7)
    downloads <- download_smap(files[1, ])
    expect_error(list_smap(downloads$local_file))
})

test_that("list_smap returns a list of dfs", {
    skip_on_cran()
    files <- find_smap(id = "SPL3SMP", dates = "2015-05-01", version = 7)
    downloads <- download_smap(files[1, ])
    contents <- list_smap(downloads)
    expect_that(contents, is_a("list"))
    expect_that(contents[[1]], is_a("data.frame"))
})
