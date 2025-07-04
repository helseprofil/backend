#' ProfileSystems
#' 
#' This function installs all packages and projects needed for FHP/OVP-related work
#' 
#' If path is not provided, C:/Users/name/helseprofil will be the root folder for other
#' projects to be installed into. 
#' 
#' @param path root folder where you want the projects to be stored
#' @param all Default = TRUE, will install/update all objects
#' @param packages default = FALSE, if all = FALSE, set this option to TRUE to install CRAN packages
#' @param norgeo default = FALSE, if all = FALSE, set this option to TRUE to install norgeo
#' @param orgdata default = FALSE, if all = FALSE, set this option to TRUE to install orgdata
#' @param khfunctions default = FALSE, if all = FALSE, set this option to TRUE to install khfunctions
#' @param KHvalitetskontroll default = FALSE, if all = FALSE, set this option to TRUE to install khvalitetskontroll
#' 
#' @examples
#' 
#' source("https://raw.githubusercontent.com/helseprofil/misc/main/ProfileSystems.R")
#' 
#' Install everything with:
#' ProfileSystem(all = T)
#' 
#' Install specific parts with:
#' ProfileSystem(all = F, packages = T, khfunctions = T, KHvalitetskontroll = T)
#' 
#' Install to other path than `C:/Users/name/helseprofil`
#' ProfileSystem(path = "Your/Preferred/Path)
ProfileSystems <- function(path = NULL, all = TRUE, packages = FALSE, norgeo = FALSE, orgdata = FALSE, khfunctions = FALSE, qualcontrol = FALSE, produksjon = FALSE){
  # 
  check_R_version()
  
  if(isTRUE(all)){
    packages <- TRUE
    norgeo <- TRUE
    orgdata <- TRUE
    khfunctions <- TRUE
    qualcontrol <- TRUE
    produksjon <- TRUE
  }
  
  if(isTRUE(packages)){
    packages <- get_kh_packages()
    install_kh_packages(packages)
    check_package_versions(packages)
  }
  
  # Install packages from GitHub
  if(isTRUE(norgeo)){
    message("\nInstalling norgeo...")
    remotes::install_github("helseprofil/norgeo")
  }
  
  if(isTRUE(orgdata)){
    message("\nInstalling orgdata...")
    remotes::install_github("helseprofil/orgdata")
  }
  
  if(isTRUE(khfunctions)){
    message("\nInstalling khfunctions...")
    remotes::install_github("helseprofil/khfunctions@master")
  }
  
  if(isTRUE(qualcontrol)){
    message("\nInstalling qualcontrol...")
    remotes::install_github("helseprofil/qualcontrol")
  }
  
  # Set base folder for installing projects. Always create the helseprofil folder as well.
  helseprofil <- file.path(fs::path_home(), "helseprofil")
  if(!fs::dir_exists(helseprofil)){
    fs::dir_create(helseprofil)
    cat("\n- ", helseprofil)
  } 
  
  if(is.null(path)) path <- helseprofil
    
  if(!fs::dir_exists(path)){
      fs::dir_create(path)
      cat("\n- ", path)
  }

  if(isTRUE(produksjon)){
    message("\nInstalling produksjon (main branch) into ", path)
      repo <- paste0("https://github.com/helseprofil/produksjon.git")
      dir <- file.path(path, "produksjon")
      if(fs::dir_exists(dir)){
        setwd(dir)
        message("\n", dir, " already exists, updating main branch to current GitHub version...")
        invisible(system("git fetch origin main"))
        invisible(system("git reset --hard origin/main"))
        invisible(system("git pull"))
      } else {
        invisible(system(paste("git clone", repo, dir)))
      }
    }  
  message("\nWOHOO, done! \n\nOpen the .Rproj file in the produksjon project to use the systems")
}

#' Clones all projects into a folder
#'
#' @param path path to where the projects will be installed
#' @param getupdates TRUE/FALSE, get updates if project already exists?
DevelopSystems <- function(path = NULL, getupdates = FALSE){
  
  check_R_version()
  packages <- get_kh_packages()
  install_kh_packages(packages)
  check_package_versions(packages)

  projects <- c("produksjon",
                "backend",
                "norgeo", 
                "orgdata", 
                "khfunctions", 
                "qualcontrol",
                "manual")
  
  if(is.null(path)) path <- file.path(fs::path_home(), "helseprofil")
  
  if(!fs::dir_exists(path)) fs::dir_create(path)
  
  for(project in projects){
    dir <- file.path(path, project)
    repo <- paste0("https://github.com/helseprofil/", project, ".git")
    
    if(fs::dir_exists(dir) && isTRUE(getupdates)){
      setwd(dir)
      branch <- ifelse(project %in% c("khfunctions"), "master", "main")
      message("\n", project, " already exists, updating ", branch, " branch to current GitHub version...")
      invisible(system(paste("git fetch origin", branch)))
      invisible(system("git reset --hard origin/main"))
      invisible(system("git pull"))
    } 
    
    if(!fs::dir_exists(dir)){
      invisible(system(paste("git clone", repo, dir)))
      message(project, " cloned into ", dir)
    }
  }
}

check_R_version <- function(){
  if(version$major <= 4 & version$minor < 4) stop("Du bruker en gammel versjon av R, installer versjon 4.4.0 eller nyere")
}

get_kh_packages <- function(){
  c("beepr", "collapse", "conflicted", "data.table", "devtools", "DBI", "dplyr",
    "DT", "epitools", "forcats", "foreign", "fs", "ggforce", "ggh4x", "ggplot2",
    "ggtext", "httr2", "intervals", "pak", "plyr", "purrr", "readxl", "remotes",
    "rlang", "RODBC", "sas7bdat", "sqldf", "stringr", "usethis", "testthat", "XML", "zoo",
    "gitcreds", "glue", "haven", "readr", "rmarkdown", "parallel", "arrow")
}

install_kh_packages <- function(packages = NULL){
  if(is.null(packages)) packages <- get_kh_packages()
  missingpackages <- setdiff(packages, installed.packages()[, "Package"])
  
  if (length(missingpackages) > 0) {
    message(paste("Installing missing packages:", paste(missingpackages, collapse = ", ")))
    for(pkg in missingpackages) try(install.packages(pkg))
  }
  check_package_versions(packages)
}

check_package_versions <- function(packages){
  outdated <- packages[packages %in% as.character(old.packages()[, 1])]
  if(length(outdated) > 0){
    pkglist <- paste0(outdated, collapse = ", ")
    message(paste0("The following packages have newer versions: ", 
                   paste0("\n- ", pkglist), "\n\n",
                   "To update, run:\n 'update.packages(oldPkgs = c(", paste0("\"", pkglist, "\""), "))'"))
  }
}
  