library(measurements)
library(httr)
library(jsonlite)

# 
# Utility script with some functions to assist 
# in querying the PokeApi
# 
# --------------------------------------------

# base uri for api querys
base.uri <- "http://pokeapi.co/api/v2/"

# Text to speech - authentication and credentials 
url_TTS <- "https://stream.watsonplatform.net/text-to-speech/api"
username_TTS <-"dc9068ce-7600-4e59-bf70-03a4679d3f8c" # you need your own - STT service credentials from bluemix
password_TTS <- "qou3eLqrL4zT"  # you need your own - STT service credentials from bluemix
username_password_TTS = paste(username_TTS,":",password_TTS,sep="")

# Text to speech function - TODO document
watson.TTS.execute <- function(text1,voice1,filename1) {
  api.link=url <- "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize"
  the_audio = CFILE(filename1, mode="wb") 
  curlPerform(url = paste(api.link,"?text=",text1,"&voice=",voice1,sep=""),
              userpwd = username_password_TTS,
              httpheader=c(accept="audio/wav"),
              writedata = the_audio@ref)
  close(the_audio)
  system(paste("open",filename1,"-a vlc"))
}

# Text to speech function - TODO document
watson.TTS.listvoices <- function() {
  voices <- GET(url=paste("https://stream.watsonplatform.net/text-to-speech/api/v1/voices"),authenticate(username_TTS,password_TTS))
  data <- content(voices,"text")
  data <- as.data.frame(strsplit(as.character(data),"name"))
  data <- data[-c(1:2), ] # remove dud first row
  data <- strsplit(as.character(data),",")
  data <- data.frame(matrix(data))
  colnames(data) <- "V1"
  data <- cSplit(data, 'V1', sep="\"", type.convert=FALSE)
  data <- data.frame(data$V1_04)
  data[,1]  <- gsub("\\\\","",data[,1] )
  return(data)
}

# querys the pokeAPI using the base uri plus a query, such as "pokemon/pikachu"
QueryApi <- function(query) {
  full.uri <- paste0(base.uri, query)
  response <- GET(full.uri)
  pokemon.df <- fromJSON(content(response, "text", encoding = "UTF-8"))
  return(pokemon.df)
}

# makes the first letter upper case of a given word
capitalize <- function(word) {
  substr(word, 1, 1) <- toupper(substr(word, 1, 1))
  return (word)
}

# converts a height from decimeters to ft
ConvHeight <- function(height) {
  # need to divide by 10 first since conv_unit doesn't
  # support decimeters
  ft <- conv_unit(height/10, 'm', 'ft')
  return(round(ft, digits = 1))
}

# converts a weight from hectograms to lbs
ConvWeight <- function(weight) {
  # need to divide by 10 first since conv_unit doesn't
  # support hectograms
  lbs <- conv_unit(weight/10, 'kg', 'lbs')
  return(round(lbs, digits = 1))
}

# gets the name of a pokemon from its id
GetPokemonName <- function(id) {
  data <- QueryApi(paste0("pokemon/", id))
  cat(paste(id, data$name, "\n"))
  return(capitalize(data$name))
}

# writes the name of every pokemon (1-721) to a csv
writeNameData <- function() {
  ids <- 1:721
  names <- sapply(ids, GetPokemonName)
  write.csv(names, file = "pokenames.csv", row.names = FALSE)
}