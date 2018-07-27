context("zzz")

test_that("Incorrect credentials cause a 401 error", {
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

test_that("Correct credentials do not raise a 401 error", {
  tmp_handle <- httr::handle("https://n5eil01u.ecs.nsidc.org/SMAP/")
  resp <- httr::GET(handle = tmp_handle, 
                    config = auth())
  expect_equal(resp$status_code, 200)
  expect_null(check_for_401(resp))
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
