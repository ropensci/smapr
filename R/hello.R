#' Prints "Hello...<some name>.
#'
#' This function has one input \code{name}, and prints a character string that
#' is "Hello...<your name>".
#'
#' There aren't many details to include.
#'
#' @param name A character string that defines a name, for instance of a person
#'   or animal.
#' @return A character string that is "Hello...<your name>".
#' @examples
#' hello(name = 'Clarice')
hello <- function(name) {
  print(paste0("Hello...", name))
}
