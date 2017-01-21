# R script to download from the Roger Waters official site with 2017 concerts into a 
# dataframe, and then used Google map API to retrieve the latitud/longitud coordinates for each venue.
#
# The resulting dataframe is then saved into "data/concerts.csv" file

library("rvest")
library(RCurl)
library(RJSONIO)
library(plyr)

# source data from rogerwaters.com site
roger_waters_url <- "http://www.roger-waters.com/"
cat(paste0('downloading concerts from ', roger_waters_url))
concerts <- (roger_waters_url %>%
  read_html() %>%
  html_nodes(xpath='//*[@id="page-wrap"]/table[2]') %>%
  html_table(header=TRUE)) [[1]]

# get lat and lon using with google geocode api
cat('downloading latutud and longitud values for concerts')

# portions of the following code are from: https://gist.github.com/josecarlosgonz/6417633

url <- function(address, return.call = "json", sensor = "false") {
  root <- "http://maps.google.com/maps/api/geocode/"
  u <- paste(root, return.call, "?address=", address, "&sensor=", sensor, sep = "")
  return(URLencode(u))
}

geoCode <- function(address,verbose=FALSE) {
  if(verbose) cat(address,"\n")
  u <- url(address)
  doc <- getURL(u)
  x <- fromJSON(doc,simplify = FALSE)
  if(x$status=="OK") {
    lat <- x$results[[1]]$geometry$location$lat
    lng <- x$results[[1]]$geometry$location$lng
    location_type  <- x$results[[1]]$geometry$location_type
    formatted_address  <- x$results[[1]]$formatted_address
    Sys.sleep(0.2)
    return (c(lat, lng, location_type, formatted_address))
  } else {
    return(c(NA,NA,NA, NA))
  }
}

concerts$address <- paste0(concerts$VENUE, ", ", concerts$CITY)
locations  <- ldply(concerts$address, function(x) geoCode(x))
names(locations)  <- c("lat","lon","location_type", "formatted")
# head(locations)

concerts$lat <- locations$lat
concerts$lng <- locations$lon
# View(concerts)

# write result file
cat('saving results into data/concerts.csvs')
write.csv(concerts, file = "data/concerts.csv")
