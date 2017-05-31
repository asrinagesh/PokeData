
# -- server.R ----------------------------------------------#
#                                                           #
# Script that is the backbone of the shiny application,     #
# It links to index.html in order to render UI components   #
# and return information to be displayed on the website     #
#                                                           #
# ----------------------------------------------------------#

library(shiny)
suppressPackageStartupMessages(library(dplyr))
library(scales)
library(RCurl)
library(audio) 
library(seewave)
library(Rtts)
library(splitstackshape)
source("./assets/scripts/ggradar.R")
source("./assets/scripts/ApiTools.R")
source("./assets/scripts/GenerationAverages.R")

# -- Working Directories -------------------------------------------------#
#                                                                         #
# Charlie                                                                 #
# setwd("~/Documents/School/INFO201/PokeData/")                           #
#                                                                         #
# Akash                                                                   #
# setwd("~/Work/School/INFO201/PokeData/")                                #
#                                                                         #
# Tu                                                                      #
# setwd('C:/Users/Tu/Desktop/Sophomore Year/Spring/INFO 201/PokeData/')   #
#                                                                         #
# ------------------------------------------------------------------------#

# Define server logic that recieves input and modifies an output
shinyServer(function(input, output) {
  
  # -- DATA HANDLING -------------------------------------------------------------------------------------
  
  # Querys the api for the pokemon's data,
  # reactively wrapped in its own function to avoid 
  # querying the API multiple times for each 
  # component that needs it
  pokemon.query <- reactive({
    if(input$pokemon == "") {
      pokemon.query <- NULL
    } else {
      pokemon.query <- QueryApi(paste0("pokemon/", tolower(input$pokemon)))
    }
  })
  
  # Creates the drop down dynamically from the
  # saved csv file of all pokemon names
  output$pokenames_div <- renderUI({
    pokenames <- read.csv(file = "./assets/data/pokenames.csv", stringsAsFactors = FALSE)
    tags$datalist(id = "pokenames", lapply(1:nrow(pokenames), function(i) {
      tags$option(pokenames$name[i])}))
  })
  
  # -- OUTPUT RENDERING ----------------------------------------------------------------------------------
  
  output$stacked_bar <- renderPlotly({
    return(makeStacked())
  })
  
  # Renders the Sprite of the desired pokemon, or an error image
  # if the given pokemon is not found
  output$image <- renderImage({
    pokemon.query <- pokemon.query()
    
    # if valid pokemon, show sprite, else show error
    if(is.null(pokemon.query$id)){
      image <- "error"
    } else {
      image <- pokemon.query$id
    }
    
    # grab and return file
    filename <- normalizePath(file.path('./www/assets/imgs/sprites/', paste0(image, '.png')))
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", pokemon.query$id))
    
  }, deleteFile = FALSE)
  
  # Prints out basic information about this pokemon, such as
  # its numerial ID, name, base XP, height, weight, and types
  output$pokedata <- renderPrint({
    pokemon.query <- pokemon.query()
    
    # if valid pokemon, show info about it, else show error
    if(is.null(pokemon.query$id)) {
      cat("Pokemon not found. Please try again")
    } else {
      cat(paste0("ID: ", pokemon.query$id,"\n"))
      cat(paste0("Name: ", capitalize(pokemon.query$name),"\n"))
      cat(paste0("Generation: ", GetGenOfPokemon(pokemon.query$id), "\n"))
      cat(paste0("Base XP: ", pokemon.query$base_experience,"\n"))
      cat(paste0("Height: ", round(ConvHeight(pokemon.query$height), digits = 1), " ft", "\n"))
      cat(paste0("Weight: ", round(ConvWeight(pokemon.query$weight), digits = 1), " lbs", "\n"))
      cat(paste0("Type(s): \n"))

      # text to speech
      pokeinfo.text <- paste0("This is ",capitalize(pokemon.query$name), ". The ", (pokemon.query$types$type$name), 
                              " type poki-mon. It is from generation ", GetGenOfPokemon(pokemon.query$id), ". It is ",
                              ConvHeight(pokemon.query$height), " feet tall and weighs ",
                              ConvWeight(pokemon.query$weight), " pounds.")
      text <- URLencode(pokeinfo.text)
      voices <- watson.TTS.listvoices()
      voice <- voices[2,] #
      filename <- "temp.wav"
      #watson.TTS.execute(text,voice,filename)
    }
  })
  
  # Dynamically renders the type images
  output$types <- renderUI({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)){
      # grab types
      types <- pokemon.query$types$type$name
      types <- sort(types)
      
      # make div tags
      output.list <- lapply(1:length(types), function(i) {
        imageOutput(types[i], height = 16, width = 48, inline = TRUE)
      })
      
      # make img tags
      lapply(1:length(types), function(i) {
        output[[types[i]]] <- renderImage({
          list(src = paste0("./www/assets/imgs/types/", types[i], ".png"),
               alt = paste(types[i], "type"))
        }, deleteFile = FALSE)
      })
      
      # update UI
      do.call(tagList, output.list)
    }
  })
  
  # Renders the radar chart for a pokemon's stats, or nothing
  # at all if the given pokemon is not found
  output$radar <- renderPlot({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)) {
      
      # get the data we want from the data frame
      stat.df <- data.frame(pokemon.query$stats$stat$name, pokemon.query$stats$base_stat)
      stat.df <- stat.df %>% rename("Stat" = pokemon.query.stats.stat.name, "Value" = pokemon.query.stats.base_stat)
      
      # organize the stats in a way that works for ggplot (essentially 
      # flipping the way the api returns them )
      speed <- stat.df %>% filter(Stat == "speed")
      spd <- stat.df %>% filter(Stat == "special-defense")
      hp <- stat.df %>% filter(Stat == "hp")
      defense <- stat.df %>% filter(Stat == "defense")
      attack <- stat.df %>% filter(Stat == "attack")
      spa <- stat.df %>% filter(Stat == "special-attack")
      Pokemon <- capitalize(pokemon.query$name)
      stat.radar.df <- data.frame(Pokemon, "Special Defense" = spd$Value,"Speed" = speed$Value, "Health" = hp$Value,
                                  "Special Attack" = spa$Value, "Attack" = attack$Value, "Defense" = defense$Value, 
                                  check.names = FALSE, stringsAsFactors = FALSE)
      
      # find the data for averages for each type that are relevant to this pokemon
      averages <- read.csv(file = "./assets/data/type_averages.csv", stringsAsFactors = FALSE)
      averages <- averages %>% select("Pokemon" = Primary.Type, "Special Defense" = avg.spd, "Speed" = avg.speed, "Health" = avg.health,
                                      "Special Attack" = avg.spa, "Attack" = avg.attack, "Defense" = avg.defense) %>% 
                                      filter(Pokemon %in% pokemon.query$types$type$name) %>% arrange(Pokemon)
      
      # append "avg" to each type
      averages$Pokemon <- paste(capitalize(averages$Pokemon), "avg")
      
      # bind this pokemons data with the average data
      binded.df <- rbind(stat.radar.df, averages)
      
      # find the pokemon's highest stat for construction of the plot
      pokemon.highest.stat <- max(stat.radar.df$`Special Defense`, stat.radar.df$Speed, stat.radar.df$Health, 
                                  stat.radar.df$`Special Attack`, stat.radar.df$Attack, stat.radar.df$Defense)
      
      # max stat to display on the radar plot
      max.stat <- 120
      if(pokemon.highest.stat > max.stat) {
        max.stat <- pokemon.highest.stat
      }
      
      # scale each column to be a percent of the max stat (ggradar requires this)
      binded.df <- binded.df %>% mutate_each(funs(. / max.stat), -Pokemon)
      
      # find correct colors to use
      colors.df <- read.csv(file = "./assets/data/typecolors.csv", stringsAsFactors = FALSE)
      colors.df <- colors.df %>% filter(type.name %in% pokemon.query$types$type$name) %>% arrange(type.name)
      colors <- c("#000000", colors.df$color.hex)
      names(colors) <- binded.df$Pokemon # necessary to preserve order of colors
      
      # use external script to plot the data
      # I modified the ggradar script a lot to make it work with this project
      # so thats why it is saved as a separate script as opposed to just
      # importing the library 
      ggradar(binded.df, font.radar = "PokemonGB", 
              values.radar = c(0, max.stat/2, max.stat), color.vector = colors,
              legend.text.size=10, grid.label.size=6, axis.label.size=4)
    }
  })
  
  # Renders an animated gif of a random route this pokemon is found on,
  # or an error pokemon invalid or not caught through conventional means
  output$location_map <- renderImage({
    pokemon.query <- pokemon.query()
    
    # find image name, or display an error if pokemon invalid
    image.name <- 'error.png'
    if(!is.null(pokemon.query$id)){
      image.name <- capitalize(pokemon.query$name)
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
         alt = paste("Location", pokemon.query$id))
  }, deleteFile = FALSE)
  
  # Renders the text for the evolution chain title
  output$evo_text <- renderPrint({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)){
      cat(paste0("Evolution chain for ", capitalize(pokemon.query$name), ":"))
    }
  })
  
  # Renders text for location pokemon can be found in
  output$location_name <- renderPrint({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)) {
      location.names <- read.csv(file = "./assets/data/pokemon_to_route_name.csv", stringsAsFactors = FALSE)
      location.names <- location.names[!(duplicated(location.names$poke_id)), ]
      pokemon.name <- capitalize(pokemon.query$name)
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
  
  # Dynamically renders evolution chain images and text
  output$evo_chain <- renderUI({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)) {
      evolution.df <- read.csv(file = "./assets/data/evolution.csv", stringsAsFactors = FALSE)
      chain.str <- (evolution.df %>% filter(id == pokemon.query$id))$chain
      chain <- unlist(strsplit(chain.str, split=" "))
      
      # make divs for images
      output.list <- lapply(1:length(chain), function(i) {
        imageOutput(chain[i], height = 96, width = 96, inline = TRUE)
      })

      # render the images
      lapply(1:length(chain), function(i) {
        output[[chain[i]]] <- renderImage({
          list(src = paste0("./www/assets/imgs/sprites/", getPokemonID(chain[i]), ".png"),
               alt = chain[i])
        }, deleteFile = FALSE)
      })
      
      # add the names of the evolution chain
      output.list[[length(output.list) + 1]] <- div(paste(capitalize(chain), collapse = ", "))

      # update UI
      do.call(tagList, output.list)
    }
  })
})