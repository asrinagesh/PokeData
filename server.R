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

# Builds a dataframe representing a pokemons stats for use with ggplot
# Takes in a dataset from a pokemon query to the API
BuildStatRadar <- function(pokemon.df) {
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
  return(stat.radar.df)
}

# Function to make first letter upper case for axis labels
capitalize <- function(word) {
  substr(word, 1, 1) <- toupper(substr(word, 1, 1))
  return (word)
}
  
# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  useShinyjs(html = TRUE)
  
  pokemon.df <- reactive({
    pokemon.df <- QueryApi(paste0("pokemon/", input$pokemon))    
  })
  
  output$pokedata <- renderPrint({
    pokemon.df <- pokemon.df()
    cat(paste0("ID: ", pokemon.df$id,"\n"))
    cat(paste0("Name: ", capitalize(pokemon.df$name),"\n"))
    cat(paste0("Base XP: ", pokemon.df$base_experience,"\n"))
    cat(paste0("Height: ", pokemon.df$height,"\n"))
    cat(paste0("Weight: ", pokemon.df$weight,"\n"))
    cat(paste0("Type(s): "))
    cat(capitalize(pokemon.df$types$type$name))
  })

  output$plot <- renderPlotly({
    pokemon.df <- pokemon.df()
    stat.df <- data.frame(pokemon.df$stats$stat$name, pokemon.df$stats$base_stat)
    stat.df <- stat.df %>% rename("Stat" = pokemon.df.stats.stat.name, "Value" = pokemon.df.stats.base_stat)
    
    plot_ly(type = "bar", data = stat.df, x = ~Stat, y = ~Value) %>% layout(yaxis = list(range = c(0, max.stat)))
  })
  
  output$radar <- renderPlot({
    pokemon.df <- pokemon.df()
    stat.radar.df <- BuildStatRadar(pokemon.df)
    ggradar(stat.radar.df)
  })
  
  output$image <- renderImage({
    pokemon.df <- pokemon.df()
    filename <- normalizePath(file.path('./www/assets/imgs/sprites/', paste0(pokemon.df$id, '.png')))
    
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", pokemon.df$id))
    
  }, deleteFile = FALSE)
  
})