library(shiny)
library(httr)
library(jsonlite)
library(plotly)
suppressPackageStartupMessages(library(dplyr))
library(ggplot2)
library(scales)
source("./assets/scripts/ggradar.R")

max.stat <- 150
base.uri <- "http://pokeapi.co/api/v2/"

# querys the pokeAPI using the base uri plus a query, such as "pokemon/pikachu"
QueryApi <- function(query) {
  full.uri <- paste0(base.uri, query)
  response <- GET(full.uri)
  data <- fromJSON(content(response, "text", encoding = "UTF-8"))
  return(data)
}

GetPokemonName <- function(id) {
  data <- QueryApi(paste0("pokemon/", id))
  cat(paste(id, data$name, "\n"))
  return(capitalize(data$name))
}

ids <- 501:721
names <- sapply(ids, GetPokemonName)
write.csv(names, file = "pokenames4.csv", row.names = FALSE)

# Builds a dataframe representing a pokemons stats for use with ggplot
# Takes in a dataset from a pokemon query to the API
BuildStatRadar <- function(data) {
  # get the data we want from the data frame
  stat.df <- data.frame(data$stats$stat$name, data$stats$base_stat)
  stat.df <- stat.df %>% rename("Stat" = data.stats.stat.name, "Value" = data.stats.base_stat)
  
  # organize the stats in a way that works for ggplot
  speed <- stat.df %>% filter(Stat == "speed")
  spd <- stat.df %>% filter(Stat == "special-defense")
  hp <- stat.df %>% filter(Stat == "hp")
  defense <- stat.df %>% filter(Stat == "defense")
  attack <- stat.df %>% filter(Stat == "attack")
  spa <- stat.df %>% filter(Stat == "special-attack")
  Pokemon <- capitalize(data$name)
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
  output$pokedata <- renderPrint({
    data <- QueryApi(paste0("pokemon/", input$pokemon))
    cat(paste0("ID: ", data$id,"\n"))
    cat(paste0("Name: ", data$name,"\n"))
    cat(paste0("Base Experience: ", data$base_experience,"\n"))
    cat(paste0("Height: ", data$height,"\n"))
    cat(paste0("Weight: ", data$weight,"\n"))
    cat(paste0("Type(s): "))
    cat(data$types$type$name)
  })
  
  output$plot <- renderPlotly({
    data <- QueryApi(paste0("pokemon/", input$pokemon))
    stat.df <- data.frame(data$stats$stat$name, data$stats$base_stat)
    stat.df <- stat.df %>% rename("Stat" = data.stats.stat.name, "Value" = data.stats.base_stat)
    
    plot_ly(type = "bar", data = stat.df, x = ~Stat, y = ~Value) %>% layout(yaxis = list(range = c(0, max.stat)))
  })
  
  output$radar <- renderPlot({
    data <- QueryApi(paste0("pokemon/", input$pokemon))
    stat.radar.df <- BuildStatRadar(data)
    ggradar(stat.radar.df)
  })
  
  output$image <- renderImage({
    data <- QueryApi(paste0("pokemon/", input$pokemon))
    
    filename <- normalizePath(file.path('./www/imgs/sprites/', paste0(data$id, '.png')))
    
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", data$id))
    
  }, deleteFile = FALSE)
  
})