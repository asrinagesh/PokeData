library(shiny)
library(httr)
library(jsonlite)
library(plotly)
suppressPackageStartupMessages(library(dplyr))
library(ggplot2)
library(scales)
library(RCurl) # install.packages("RCurl") # if the package is not already installed
library(httr)
library(audio) 
library(seewave)
library(Rtts)
library(splitstackshape)
source("./assets/scripts/ggradar.R")
source("./assets/scripts/ApiTools.R")
source("./assets/scripts/GenerationAverages.R")

# Charlie
# setwd("~/Documents/School/INFO201/PokeData/")

# Akash
# setwd("~/Work/School/INFO201/PokeData/")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
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
    if(is.null(pokemon.df$id)) {
      cat("Pokemon not found. Please try again")
    } else {
      cat(paste0("ID: ", pokemon.df$id,"\n"))
      cat(paste0("Name: ", capitalize(pokemon.df$name),"\n"))
      cat(paste0("Generation: ", GetGenOfPokemon(pokemon.df$id), "\n"))
      cat(paste0("Base XP: ", pokemon.df$base_experience,"\n"))
      cat(paste0("Height: ", ConvHeight(pokemon.df$height), " ft", "\n"))
      cat(paste0("Weight: ", ConvWeight(pokemon.df$weight), " lbs", "\n"))
      cat(paste0("Type(s): "))
      cat(capitalize(pokemon.df$types$type$name))
      pokeinfo.text <- paste0("This is ",capitalize(pokemon.df$name), ". The ", (pokemon.df$types$type$name), " type poki-mon. It is from generation ",
                              GetGenOfPokemon(pokemon.df$id), ". It is ", ConvHeight(pokemon.df$height), " feet tall and weighs ",
                              ConvWeight(pokemon.df$weight), " pounds.")
      text <- URLencode(pokeinfo.text)
      voices <- watson.TTS.listvoices()
      voice <- voices[2,] #
      filename <- "temp.wav"
      watson.TTS.execute(text,voice,filename)
    }
  })
  
  # Renders text for location pokemon can be found in
  output$location_name <- renderPrint({
    pokemon.df <- pokemon.df()
    location.names <- read.csv(file = "./assets/data/pokemon_to_route_name.csv", stringsAsFactors = FALSE)
    location.names <- location.names[!(duplicated(location.names$poke_id)), ]
    if(!is.null(pokemon.df$id)) {
      pokemon.name <- capitalize(pokemon.df$name)
      location.title <- location.names %>% filter(poke_id == pokemon.name) %>% select(location_name)
      cat(pokemon.name)
      # Checks num rows for greater than one to indicate that Pokemon has a location
      if (nrow(location.title) == 1) {
        cat(paste(" can be found in: ", location.title))
      } else {
        cat(paste(" cannot be found naturally."))
      }
    }
  })
  
  # Renders the radar chart for a pokemon's stats, or nothing
  # at all if the given pokemon is not found
  output$radar <- renderPlot({
    pokemon.df <- pokemon.df()
    if(!is.null(pokemon.df$id)) {
      
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
                                  "Special Attack" = spa$Value, "Attack" = attack$Value, "Defense" = defense$Value, 
                                  check.names = FALSE, stringsAsFactors = FALSE)
      
      averages <- read.csv(file = "./assets/data/type_averages.csv", stringsAsFactors = FALSE)
      averages <- averages %>% select("Pokemon" = Primary.Type, "Special Defense" = avg.spd,"Speed" = avg.speed, "Health" = avg.health,
                                      "Special Attack" = avg.spa, "Attack" = avg.attack, "Defense" = avg.defense) %>% 
                                      filter(Pokemon %in% pokemon.df$types$type$name)
      
      averages$Pokemon <- paste(capitalize(averages$Pokemon), "avg")
      
      binded.df <- rbind(stat.radar.df, averages)
      
      pokemon.highest.stat <- max(stat.radar.df$`Special Defense`, stat.radar.df$Speed, stat.radar.df$Health, 
                                  stat.radar.df$`Special Attack`, stat.radar.df$Attack, stat.radar.df$Defense)
      
      max.stat <- 120
      if(pokemon.highest.stat > max.stat) {
        max.stat <- pokemon.highest.stat
      }
      
      # use external script to plot the data
      binded.df <- binded.df %>%
        mutate_each(funs(. / max.stat), -Pokemon)
      ggradar(binded.df, values.radar = c(0, max.stat/2, max.stat))
    }
  })
  
  # Renders the Sprite of the desired pokemon, or an error image
  # if the given pokemon is not found
  output$image <- renderImage({
    pokemon.df <- pokemon.df()
    if(is.null(pokemon.df$id)){
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
  
  # Renders an animated gif of a random route this pokemon is found on,
  # or an error pokemon invalid or not caught through conventional means
  output$location_map <- renderImage({
    pokemon.df <- pokemon.df()
    
    # find image name, or display an error if pokemon invalid
    image.name <- 'error.png'
    if(!is.null(pokemon.df$id)){
      image.name <- capitalize(pokemon.df$name)
    }
    file <- file.path('./www/assets/imgs/locations', paste0(image.name, '.gif'))
    
    # if file doesnt exist, pokemon not available through conventional means
    if(file.exists(file)){ # pokemon found on a route
      filename <- normalizePath(file)
    } else { # pokemon is not found on routes
      file <- file.path('./www/assets/imgs/locations', 'error.png')
    }
    filename <- normalizePath(file)
    
    # return img tag
    list(src = filename,
         alt = paste("Location", pokemon.df$id))
  }, deleteFile = FALSE)
  
})