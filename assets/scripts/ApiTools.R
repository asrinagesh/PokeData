
# -- ApiTools.R --------------------------------#
#                                               #
# Utility script with some functions to assist  #
# in querying the PokeApi                       #
#                                               #
# ----------------------------------------------#

library(measurements)
library(httr)
library(jsonlite)

# base uri for api querys
base.uri <- "http://pokeapi.co/api/v2/"

# Text to speech - authentication and credentials 
url_TTS <- "https://stream.watsonplatform.net/text-to-speech/api"
username_TTS <-"dc9068ce-7600-4e59-bf70-03a4679d3f8c" # you need your own - STT service credentials from bluemix
password_TTS <- "qou3eLqrL4zT"  # you need your own - STT service credentials from bluemix
username_password_TTS = paste(username_TTS,":",password_TTS,sep="")

# Text to speech function
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

# Text to speech function
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
  return(conv_unit(height/10, 'm', 'ft'))
}

# converts a weight from hectograms to lbs
ConvWeight <- function(weight) {
  # need to divide by 10 first since conv_unit doesn't
  # support hectograms
  return(conv_unit(weight/10, 'kg', 'lbs'))
}

# writes the name of every pokemon (1-721) to a csv
writeNameData <- function() {
  ids <- 1:721
  names <- sapply(ids, GetPokemonName)
  write.csv(names, file = "pokenames.csv", row.names = FALSE)
}

# writes the colors for all types
writeTypeColors <- function() {
  type.name <- c("bug", "dark", "dragon", "electric", "fairy", "fighting", 
                 "fire", "flying", "ghost", "grass", "ground", "ice",
                 "normal", "poison", "psychic", "rock", "steel", "water")
  
  color.hex <- c("#90BF75", "#7D7575", "#5B0FF6", "#D9DD09", "#FC45CB", "#F3585D",
                 "#F47C25", "#4ABCEC", "#9652F6", "#81E76D", "#F4C242", "#2ED1C5",
                 "#AAAA98", "#D675F6", "#F31398", "#BB9038", "#A9A8C5", "#5682F6")
  
  type.color.df <- data.frame(type.name, color.hex, stringsAsFactors = FALSE)
  write.csv(type.color.df, file = "typecolors.csv", row.names = FALSE)
}

# evolution information
getEvolutionChain <- function(pokemon.query) {
  species <- fromJSON(content(GET(pokemon.query$species$url), "text", encoding = "UTF-8"))
  evo.chain <- fromJSON(content(GET(species$evolution_chain$url), "text", encoding = "UTF-8"))
  chain <- c(evo.chain$chain$species$name)
  if(!is.null(evo.chain$chain$evolves_to$species$name)) {
    chain <- c(chain, evo.chain$chain$evolves_to$species$name)
  }
  if(!is.null(evo.chain$chain$evolves_to$evolves_to[[1]]$species$name)) {
    chain <- c(chain, evo.chain$chain$evolves_to$evolves_to[[1]]$species$name)
  }
  return(chain)
}

# converts a chain of pokemon to a chain of IDs
convertChainToIDs <- function(chain) {
  return(sapply(chain, getPokemonID))
}

# gets a data frame with a single row with evo chain data
getEvolutionChainDF <- function(id) {
  pokemon.query <- QueryApi(paste0("pokemon/", id))
  
  cat(paste(pokemon.query$id, pokemon.query$name, "\n"))
  
  id <- pokemon.query$id
  name <- pokemon.query$name
  chain.vector <- getEvolutionChain(pokemon.query)
  chain <- unlist(paste(chain.vector, collapse = " "))
  
  return(data.frame(id, name, chain, stringsAsFactors = FALSE))
}

# saves evolution chain dataframes
writeChainDF <- function() {
  one <- lapply(1:100, getEvolutionChainDF)
  one.df <- do.call(rbind, one)
  write.csv(one.df, file="./assets/data/one.csv")
  
  two <- lapply(101:200, getEvolutionChainDF)
  two.df <- do.call(rbind, two)
  write.csv(two.df, file="./assets/data/two.csv")
  
  three <- lapply(201:300, getEvolutionChainDF)
  three.df <- do.call(rbind, three)
  write.csv(three.df, file="./assets/data/three.csv")
  
  four <- lapply(301:400, getEvolutionChainDF)
  four.df <- do.call(rbind, four)
  write.csv(four.df, file="./assets/data/four.csv")
  
  five <- lapply(401:500, getEvolutionChainDF)
  five.df <- do.call(rbind, five)
  write.csv(five.df, file="./assets/data/five.csv")
  
  six <- lapply(501:600, getEvolutionChainDF)
  six.df <- do.call(rbind, six)
  write.csv(six.df, file="./assets/data/six.csv")
  
  seven <- lapply(601:721, getEvolutionChainDF)
  seven.df <- do.call(rbind, seven)
  write.csv(seven.df, file="./assets/data/seven.csv")
  
  total <- rbind(one.df, two.df, three.df, four.df, five.df, six.df, seven.df)
  write.csv(total, file = "./assets/data/evolution.csv", row.names = FALSE)
}

# gets the id of a pokemon from its name
getPokemonID <- function(name.to.search) {
  pokenames <- read.csv(file = "./assets/data/pokenames.csv", stringsAsFactors = FALSE)
  pokenames <- pokenames %>% filter(name == capitalize(name.to.search))
  return(pokenames$id)
}

# gets the name of a pokemon from its id
getPokemonName <- function(id.to.search) {
  pokenames <- read.csv(file = "./assets/data/pokenames.csv", stringsAsFactors = FALSE)
  pokenames <- pokenames %>% filter(id == capitalize(id.to.search))
  return(pokenames$name)
}