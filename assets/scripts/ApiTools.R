library(measurements)
# 
# Utility script with some functions to assist 
# in querying the PokeApi
# 
# --------------------------------------------

# base uri for api querys
base.uri <- "http://pokeapi.co/api/v2/"

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

writeNameData <- function() {
  ids <- 1:721
  names <- sapply(ids, GetPokemonName)
  write.csv(names, file = "pokenames.csv", row.names = FALSE)
}