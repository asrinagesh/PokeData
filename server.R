library(shiny)
library(httr)
library(jsonlite)
library(plotly)
suppressPackageStartupMessages(library(dplyr))
library(ggplot2)
library(scales)
library(shinyjs)
source("./assets/scripts/ggradar.R")

max.stat <- 150
base.uri <- "http://pokeapi.co/api/v2/"

# querys the pokeAPI using the base uri plus a query, such as "pokemon/pikachu"
QueryApi <- function(query) {
  full.uri <- paste0(base.uri, query)
  response <- GET(full.uri)
  pokemon.df <- fromJSON(content(response, "text", encoding = "UTF-8"))
  return(pokemon.df)
}

# Function to make first letter upper case for axis labels
capitalize <- function(word) {
  substr(word, 1, 1) <- toupper(substr(word, 1, 1))
  return (word)
}
  
# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  useShinyjs(html = TRUE)
  
  # Querys the api for the pokemon's data
  pokemon.df <- reactive({
    if(input$pokemon == "") {
      pokemon <- "not found"
    } else {
      pokemon <- input$pokemon
    }
    pokemon.df <- QueryApi(paste0("pokemon/", tolower(pokemon)))    
  })
  
  # Prints out basic information about this pokemon, such as
  # its numerial ID, name, base XP, height, weight, and types
  output$pokedata <- renderPrint({
    pokemon.df <- pokemon.df()
    if("Not found." %in% pokemon.df) {
      cat("Pokemon not found. Please try again")
    } else {
      cat(paste0("ID: ", pokemon.df$id,"\n"))
      cat(paste0("Name: ", capitalize(pokemon.df$name),"\n"))
      cat(paste0("Base XP: ", pokemon.df$base_experience,"\n"))
      cat(paste0("Height: ", pokemon.df$height,"\n"))
      cat(paste0("Weight: ", pokemon.df$weight,"\n"))
      cat(paste0("Type(s): "))
      cat(capitalize(pokemon.df$types$type$name))
    }
  })
  
  # Renders the radar chart for a pokemon's stats, or nothing
  # at all if the given pokemon is not found
  output$radar <- renderPlot({
    pokemon.df <- pokemon.df()
    if(!("Not found." %in% pokemon.df)) {
      
      # get the data we want from the data frame
      stat.df <- data.frame(pokemon.df$stats$stat$name, pokemon.df$stats$base_stat)
      stat.df <- stat.df %>% rename("Stat" = pokemon.df.stats.stat.name, "Value" = pokemon.df.stats.base_stat)
      
      # organize the stats in a way that works for ggplot
      speed <- stat.df %>% filter(Stat == "speed")
      spd <- stat.df %>% filter(Stat == "special-defense")
      hp <- stat.df %>% filter(Stat == "hp")
      defense <- stat.df %>% filter(Stat == "defense")
      attack <- stat.df %>% filter(Stat == "attack")
      spa <- stat.df %>% filter(Stat == "special-attack")
      Pokemon <- capitalize(pokemon.df$name)
      stat.radar.df <- data.frame(Pokemon, "Special Defense" = spd$Value,"Speed" = speed$Value, "Health" = hp$Value,
                                  "Special Attack" = spa$Value, "Attack" = attack$Value, "Defense" = defense$Value, check.names = FALSE)
      
      # use external script to plot the data
      stat.radar.df <- stat.radar.df %>%
        mutate_each(funs(. / max.stat), -Pokemon)
      ggradar(stat.radar.df)
    }
  })
  
  # Renders the Sprite of the desired pokemon, or an error image
  # if the given pokemon is not found
  output$image <- renderImage({
    pokemon.df <- pokemon.df()
    if("Not found." %in% pokemon.df){
      image <- "error"
    } else {
      image <- pokemon.df$id
    }
    
    filename <- normalizePath(file.path('./www/assets/imgs/sprites/', paste0(image, '.png')))
    
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", pokemon.df$id))
    
  }, deleteFile = FALSE)
  
})