#' @title are_same
#' @description
#' Check if two functions are identical, useful when developing a function to highlight differences. 
#'
#' @param f1 function 1
#' @param f2 function 2
are_same <- function(f1, f2) {
  f_new_text <- gsub("^#.*\n", "", deparse(f1))
  f_old_text <- gsub("^#.*\n", "", deparse(f2))
  
  if (identical(gsub("\\s", "", f_new_text), gsub("\\s", "", f_old_text))) {
    return(TRUE)
  } else {
    cat("The functions are not identical:\n")
    cat("=============================\n\n")
    diff <- diffobj::diffPrint(f_new_text, f_old_text)
    print(diff)
    return(FALSE)
  }
}

#' @title list_funs
#' @description
#' returns a list of all functions from a package 
#' in the format `fun1\(|fun2\(|` etc. Useful to search a 
#' project for use of these functions when not specified with `package::function()`..
#'
#' @param package the package you check
list_funs <- function(package = NULL) {
  
  funs <- getNamespaceExports(package)
  funs <- funs[order(funs)]
  
  # Add "\\" before characters that should be escaped (written by ChatGPT)
  escape_chars <- function(string) {
    chars_to_escape <- c("(", ")", "[", "]", "$", ".", "|")
    escaped_chars <- c("\\(", "\\)", "\\[", "\\]", "\\$", "\\.", "\\|")
    for (i in seq_along(chars_to_escape)) {
      string <- gsub(chars_to_escape[i], escaped_chars[i], string, fixed = TRUE)
    }
    return(string)
  }
  
  funs <- escape_chars(funs)
  
  regex_str <- paste0(funs, collapse = "\\(|")
  
  cat(paste0(regex_str, "\\("))
}
