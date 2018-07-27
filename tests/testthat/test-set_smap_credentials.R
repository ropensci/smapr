context("set_smap_credentials")

test_that(".Renviron file is not modified when save = FALSE", {
  skip_on_cran()
  renvironment_contents <- readLines(renvironment_path)
  creds <- get_creds(renvironment_path)
  
  set_smap_credentials('fakeuser', 'fakepass', save = FALSE)
  
  # verify that the .Renviron file has not been modified
  final_renvironment_contents <- readLines(renvironment_path)
  expect_identical(renvironment_contents, final_renvironment_contents)

  # clean up by restoring original credentials  
  set_smap_credentials(creds['username'], 
                       creds['passwd'], 
                       save = FALSE)
})

test_that("Existing credentials raise an error when overwrite = FALSE", {
  skip_on_cran()
  expect_error(set_smap_credentials("dummy_user", 
                                    "dummy_password", 
                                    save = TRUE, 
                                    overwrite = FALSE), 
               "Earthdata credentials already exist")
})

test_that("Existing credentials are overwritten when overwrite = TRUE", {
  skip_on_cran()
  original_creds <- get_creds(renvironment_path)
  
  set_smap_credentials("user", 
                       "password", 
                       save = TRUE, 
                       overwrite = TRUE)
  
  new_creds <- get_creds(renvironment_path)
  expect_equal(new_creds[['username']], "user")
  expect_equal(new_creds[['passwd']], "password")
  
  # restore old creds
  set_smap_credentials(original_creds['username'], 
                       original_creds['passwd'], 
                       overwrite = TRUE)
})
 