context("find_smap")

test_that("searching for invalid ids causes an error", {
    expect_error(find_smap(id = "invalid", date = "2015.03.31", version = 1))
})

test_that("searching for invalid versions causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 999))
})

test_that("searching for invalid dates causes an error", {
    expect_error(find_smap(id = "SPL4SMGP", date = "3015.03.31", version = 1))
})

test_that("searching for valid data does not cause an error", {
    expect_error(find_smap(id = "SPL4SMGP", date = "2015.03.31", version = 1), NA)
})
