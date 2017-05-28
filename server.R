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

# Charlie
# setwd("~/Documents/School/INFO201/PokeData/")

# Akash
# setwd("~/Work/School/INFO201/PokeData/")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Querys the api for the pokemon's data
  pokemon.query <- reactive({
    if(input$pokemon == "") {
      pokemon.query <- NULL
    } else {
      pokemon.query <- QueryApi(paste0("pokemon/", tolower(input$pokemon)))
    }
  })
  
  # Prints out basic information about this pokemon, such as
  # its numerial ID, name, base XP, height, weight, and types
  output$pokedata <- renderPrint({
    pokemon.query <- pokemon.query()
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
      pokeinfo.text <- paste0("This is ",capitalize(pokemon.query$name), ". The ", (pokemon.query$types$type$name), " type poki-mon. It is from generation ",
                              GetGenOfPokemon(pokemon.query$id), ". It is ", ConvHeight(pokemon.query$height), " feet tall and weighs ",
                              ConvWeight(pokemon.query$weight), " pounds.")
      text <- URLencode(pokeinfo.text)
      voices <- watson.TTS.listvoices()
      voice <- voices[2,] #
      filename <- "temp.wav"
      #watson.TTS.execute(text,voice,filename)
    }
  })
  
  # Renders text for location pokemon can be found in
  output$location_name <- renderPrint({
    pokemon.query <- pokemon.query()
    location.names <- read.csv(file = "./assets/data/pokemon_to_route_name.csv", stringsAsFactors = FALSE)
    location.names <- location.names[!(duplicated(location.names$poke_id)), ]
    if(!is.null(pokemon.query$id)) {
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
  
  # Renders the radar chart for a pokemon's stats, or nothing
  # at all if the given pokemon is not found
  output$radar <- renderPlot({
    pokemon.query <- pokemon.query()
    if(!is.null(pokemon.query$id)) {
      
      # get the data we want from the data frame
      stat.df <- data.frame(pokemon.query$stats$stat$name, pokemon.query$stats$base_stat)
      stat.df <- stat.df %>% rename("Stat" = pokemon.query.stats.stat.name, "Value" = pokemon.query.stats.base_stat)
      
      # organize the stats in a way that works for ggplot (flipping the way
      # the api returns them essentially)
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
      averages <- averages %>% select("Pokemon" = Primary.Type, "Special Defense" = avg.spd,"Speed" = avg.speed, "Health" = avg.health,
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
      ggradar(binded.df, values.radar = c(0, max.stat/2, max.stat), color.vector = colors)
    }
  })
  
  # Renders the Sprite of the desired pokemon, or an error image
  # if the given pokemon is not found
  output$image <- renderImage({
    pokemon.query <- pokemon.query()
    if(is.null(pokemon.query$id)){
      image <- "error"
    } else {
      image <- pokemon.query$id
    }
    
    filename <- normalizePath(file.path('./www/assets/imgs/sprites/', paste0(image, '.png')))
    
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", pokemon.query$id))
    
  }, deleteFile = FALSE)
  
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
  
  # reactively update the type images
  observe({
    output$types <- renderUI({
      pokemon.query <- pokemon.query()
      if(!is.null(pokemon.query$id)){
        # grab types
        types <- pokemon.query$types$type$name
        types <- sort(types)
        
        # make div tags
        output.list <- makeTypes(types)
        
        # make img tags
        setTypeImages(types)
        
        # update UI
        do.call(tagList, output.list)
      }
    })
  })
  
  # creates div tags dynamically for types
  makeTypes <- function(types) {
    output.list <- lapply(1:length(types), function(i) {
      my_i <- i
      id <- paste0("type", my_i)
      imageOutput(id, height = 16, width = 48, inline = TRUE)
    })
    
    return(output.list)
  }
  
  # creates img tags dynamically for types
  setTypeImages <- function(types) {
    lapply(1:length(types), function(i) {
      my_i <- i
      id <- paste0("type", my_i)
      output[[id]] <- renderImage({
        list(src = paste0("./www/assets/imgs/types/", types[my_i], ".png"),
             alt = paste(types[i], "type"))
      }, deleteFile = FALSE)
    })
  }
  
})