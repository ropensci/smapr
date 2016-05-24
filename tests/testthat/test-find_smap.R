context("find_smap")

test_that("non-existent directories cause errors", {
    expect_error(find_smap(id = "SPL4SMGP", date = "2010.03.31", version = 1))
})
