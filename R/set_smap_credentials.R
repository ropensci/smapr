#' Set credentials for NASA's Earthdata portal
#'
#' To use smapr, users need to provide NASA Earthdata portal credentials. 
#' This function allows users to interactively set these credentials via the 
#' user's Earthdata username and password.
#'
#' If you do not yet have a username and password, register for one here:
#' https://urs.earthdata.nasa.gov/
#' 
#' A warning: do not commit your username and password to a public repository!
#' This function is meant to be used interactively, and not embedded within a 
#' script that you would share. 
#' 
#' @param username A character string of your Earthdata portal username
#' @param password A character string of your Earthdata portal password
#' @param save Logical: whether to save your credentials to your 
#' .Renviron file (e.g., ~/.Renviron). Previous Earthdata credentials will not 
#' be overwritten unless \code{overwrite = TRUE}.
#' @param overwrite Logical: whether to overwrite previous Earthdata credentials
#' in your .Renviron file (only applies when \code{save = TRUE})
#' @return A data.frame with the names of the data files, the remote directory, and
#'   the date.
#'
#' @examples
#' \dontrun{
#' set_smap_credentials('myusername', 'mypassword')
#' }
#'
#' @export
set_smap_credentials <- function(username, password, 
                                 save = TRUE, overwrite = FALSE) {
  Sys.setenv(ed_un = username, ed_pw = password)
  
  if (save) {
    renvironment_path <- file.path(Sys.getenv("HOME"), ".Renviron")
    if (!file.exists(renvironment_path)) {
      file.create(renvironment_path)
    }
    renvironment_contents <- readLines(renvironment_path)
    
    username_in_renv <- grepl("^ed_un[[:space:]]*=.*", renvironment_contents)
    password_in_renv <- grepl("^ed_pw[[:space:]]*=.*", renvironment_contents)
    credentials_already_exist <- any(username_in_renv | password_in_renv)
    
    if (credentials_already_exist) {
      if (overwrite) {
        to_remove <- username_in_renv | password_in_renv
        renvironment_contents <- renvironment_contents[!to_remove]
        blank_spaces <- renvironment_contents == ""
        stripped_contents <- renvironment_contents[!blank_spaces]
        contents_w_newline <- c(stripped_contents, "")
        writeLines(contents_w_newline, renvironment_path)
      } else {
        stop(
          paste0(
            strwrap(
              c("Earthdata credentials already exist in your .Renviron file:", 
                renvironment_path, 
                "",
                "To resolve this issue, you can do one of the following: ",
                "",
                "1) Use the 'overwrite = TRUE' argument in", 
                "set_smap_credentials() to overwrite the existing Earthdata", 
                "credentials in your .Renviron file",
                "",
                "2) Manually edit the .Renviron file to update your Earthdata", 
                "username and password.")
            ), 
            collapse = "\n"
          )
        )
      }
    }
    
    set_env_cmd <- paste0("ed_un=", username, "\n",
                          "ed_pw=", password, "\n")
    write(set_env_cmd, renvironment_path, append = TRUE)
    
    message(
      paste(
        strwrap(
          c("Your credentials have been updated.", 
            "To avoid exposing your username and password, do not commit",  
            "your call to set_smap_credentials(), your .Renviron, or your", 
            ".Rhistory file to a public repository.")
          ), 
        collapse = "\n"
        )
      )
  }
}
