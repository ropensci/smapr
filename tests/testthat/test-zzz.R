context("zzz")

test_that("get_creds() returns a vector with username and passwd", {
  skip_on_cran()
  creds <- get_creds(file.path(Sys.getenv("HOME"), ".Renviron"))
  expect_length(creds, 2)
  expect_named(creds, c("username", "passwd"))
})

test_that("Correct credentials do not raise a 401 error", {
  skip_on_cran()
  resp <- httr::GET(https_prefix(), 
                    config = auth())
  expect_equal(resp$status_code, 200)
  expect_null(check_for_401(resp))
})

test_that("Incorrect credentials cause a 401 error", {
  skip_on_cran()
  # temporary handle is necessary here, otherwise previous 
  # authentication (with correct credentials) is used
  # solution from: https://github.com/r-lib/httr/issues/122
  tmp_handle <- httr::handle("https://n5eil01u.ecs.nsidc.org/SMAP/")
  resp <- httr::GET(handle = tmp_handle, 
                    config = httr::authenticate('fakeuser', 'fakepass'))
  expect_equal(resp$status_code, 401)
  expect_error(check_for_401(resp), "401 unauthorized")
  rm(tmp_handle)
})

test_that("Missing credentials cause an error", {
    username <- Sys.getenv('ed_un')
    password <- Sys.getenv('ed_pw')
    
    Sys.setenv(ed_un = "", ed_pw = "")
    expect_error(check_creds(), 
                 "smapr expected ed_un and ed_pw to be environment variables!")
    
    Sys.setenv(ed_un = username, ed_pw = password)
})
