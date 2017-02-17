context("zzz")

test_that("missing credentials raises an error", {
    Sys.setenv(ed_un = "", ed_pw = "")
    expect_error(check_creds())
})

test_that("non-missing credentials does not raise an error", {
    Sys.setenv(ed_un = "aaa", ed_pw = "bbb")
    expect_null(check_creds())
})
