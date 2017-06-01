#  Load in the data
library(jsonlite)
library(httr)
library(dplyr)
library(plotly)
library(RColorBrewer)
source('./ApiTools.R')

# Tu
# setwd('C:/Users/Tu/Desktop/Sophomore Year/Spring/INFO 201/PokeData/assets/scripts')

# Read in Data
data.gen1 <- read.csv(file = '../data/gen1data.csv', stringsAsFactors = FALSE)
data.gen2 <- read.csv(file = '../data/gen2data.csv', stringsAsFactors = FALSE)
data.gen3 <- read.csv(file = '../data/gen3data.csv', stringsAsFactors = FALSE)
data.gen4 <- read.csv(file = '../data/gen4data.csv', stringsAsFactors = FALSE)
data.gen5 <- read.csv(file = '../data/gen5data.csv', stringsAsFactors = FALSE)
data.gen6 <- read.csv(file = '../data/gen6data.csv', stringsAsFactors = FALSE)
data.stats <- read.csv(file = '../data/type_averages.csv', stringsAsFactors = FALSE)

# making a margin for graphs
m <- list(
  l = 200,
  r = 50,
  b = 200,
  t = 100,
  pad = 4
)

color.pokemons <- NULL
### BAR GRAPHS OF POKEMON TYPES ### 

# color for graphs for gen 1
color.pokemons.without.dark <- c('#208000', '#ffff99', '#ffff1a', '#ff66ff', '#660000', '#e60000', '#d9d9d9', '#290066', 
                                 '#40ff00', '#cc9900', '#b3fff0', '#ffe6cc', '#8000ff', '#db4dff', '#996633', '#ccccff',
                                 '#0099ff')

# color for graphs for gen 2 and forward (with the introduction of dark type)
color.pokemons.with.dark <- c('#208000', 'black', '#ffff99', '#ffff1a', '#ff66ff', '#660000', '#e60000', '#d9d9d9', '#290066', 
                              '#40ff00', '#cc9900', '#b3fff0', '#ffe6cc', '#8000ff', '#db4dff', '#996633', '#ccccff',
                              '#0099ff')

# take in input generation and return the number of pokemons per type of that generation
makePopularData <- function(gen) {
  
  # setting up some variables
  id.first <- 0
  gen.number <- 0
  data.gen <- NULL
  
  # changing the data depends on the generation
  if (gen == 1) {
    id.first <- 1
    gen.number <- c(2:151)
    data.gen <- data.gen1
  } else if (gen == 2) {
    id.first <- 152
    gen.number <- c(153:251)
    data.gen <- data.gen2
  } else if (gen == 3) {
    id.first <- 252
    gen.number <- c(253:386)
    data.gen <- data.gen3
  } else if (gen == 4) {
    id.first <- 387
    gen.number <- c(388:493)
    data.gen <- data.gen4
  } else if (gen == 5) {
    id.first <- 494
    gen.number <- c(495:649)
    data.gen <- data.gen5
  } else {
    id.first <- 650
    gen.number <- c(651:721)
    data.gen <- data.gen6
  }
  
  # setting the data starting with the first pokemon
  pokemon.df.gen <- data.gen %>% 
    filter(id == id.first) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # getting the count for each type for the rest of the pokemon of that generation
  getTypes <- function(number) {
    
    # getting the type of the pokemon with the current id
    new.pokemon.df <- data.gen %>%
      filter(id == number) %>%
      group_by(Primary.Type) %>%
      summarise(count = n()) 
    
    # bind the old data with new data 
    total <- rbind(pokemon.df.gen, new.pokemon.df)
    # updating the count number 
    total <- total %>% 
      group_by(Primary.Type) %>%
      summarise(count = sum(count))
    
    pokemon.df.gen <<- total # the << to break the scope and to access value in lapply
  }
  
  # getting the complete dataset by applying each pokemon to the function 
  lapply(gen.number, getTypes)
  
  
  return(pokemon.df.gen)
}

# take in the data of the number of pokemon per type and return a bar chart
makeBarPopular <- function(pokemon.df.gen) {
  
  # changing the color depends on whether the generation has dark type
  if (nrow(pokemon.df.gen) == 17) {
    color.pokemons <- color.pokemons.without.dark
  } else {
    color.pokemons <- color.pokemons.with.dark
  }
  
  # making a plotly bar chart
  popular.bar.gen <- plot_ly(pokemon.df.gen,
                             x = ~Primary.Type,
                             y = ~count,
                             type = 'bar',
                             color = ~Primary.Type,
                             colors = color.pokemons,
                             opacity = 0.8,
                             hoverinfo = 'text',
                             text = ~paste0(Primary.Type, ': ' , count, ' pokemon')
  ) %>% layout(title = 'Pokemon Type Distribution',
               xaxis = list(title = 'Types'),
               yaxis = list(title = 'Number of Pokemon'),
               margin = m) 
  return(popular.bar.gen)
}

# MAIN FUNCTION TAKES IN INPUT AND RETURN THE BAR CHART
makeBar <- function(gen) {
  pokemon.df.gen <- makePopularData(gen)
  return(makeBarPopular(pokemon.df.gen))
}

########################################################################################################

## STACKED BAR CHART ##

makeStacked <- function() {
  
  # Getting the data popular types for each generation
  pokemon.df.gen1 <- makePopularData(1) 
  pokemon.df.gen2 <- makePopularData(2)
  pokemon.df.gen3 <- makePopularData(3)
  pokemon.df.gen4 <- makePopularData(4)
  pokemon.df.gen5 <- makePopularData(5)
  pokemon.df.gen6 <- makePopularData(6)
  
  colnames(pokemon.df.gen1) <- c('Main.Type', 'count.1')
  colnames(pokemon.df.gen2) <- c('Main.Type', 'count.2')
  colnames(pokemon.df.gen3) <- c('Main.Type', 'count.3')
  colnames(pokemon.df.gen4) <- c('Main.Type', 'count.4')
  colnames(pokemon.df.gen5) <- c('Main.Type', 'count.5')
  colnames(pokemon.df.gen6) <- c('Main.Type', 'count.6')
  
  pokemon.all.2 <- left_join(pokemon.df.gen1, pokemon.df.gen2)
  pokemon.all.3 <- left_join(pokemon.all.2, pokemon.df.gen3)
  pokemon.all.4 <- left_join(pokemon.all.3, pokemon.df.gen4)
  pokemon.all.5 <- left_join(pokemon.all.4, pokemon.df.gen5)
  pokemon.all <- left_join(pokemon.all.5, pokemon.df.gen6)
  
  # Making a stacked bar chart of number of pokemon per type of each generation stacks on one another
  stacked.bar <- plot_ly(pokemon.all, x = ~Main.Type, y = ~count.1, type = 'bar', name = 'Gen 1', opacity = 0.8) %>%
    add_trace(y = ~count.2, name = 'Gen 2', opacity = 0.8) %>% 
    add_trace(y = ~count.3, name = 'Gen 3', opacity = 0.8) %>% 
    add_trace(y = ~count.4, name = 'Gen 4', opacity = 0.8) %>% 
    add_trace(y = ~count.5, name = 'Gen 5', opacity = 0.8) %>% 
    add_trace(y = ~count.6, name = 'Gen 6', opacity = 0.8) %>% 
    layout(title = 'Pokemon Type Distribution',
           xaxis = list(title = 'Types'),
           yaxis = list(title = 'Number of Pokemon'), barmode = 'stack' , margin = m) 
  
  return(stacked.bar)
}

########################################################################################################

### STATS BAR ##

# with widget input can select what stats they want to show (avg.speed, overall, etc.)
# a bar graph showing the type with the highest stats 
colnames(data.stats) <- c('Primary.Type', 'Special.Defense', 'Speed', 'Health','Special.Attack', 'Attack', 'Defense', 'Overall.Stats')

# taking in name of the stats column and return a bar stats 
makeStats <- function(stats) {
  stats <- paste0('~', stats)
  
  name <- gsub("[[:punct:]]", " ", stats)
  
  stats.bar <- plot_ly(data.stats,
                       x = ~Primary.Type,
                       y = eval(parse(text = stats)),
                       type = 'bar',
                       color = ~Primary.Type,
                       colors = ~color.pokemons.with.dark,
                       opacity = 0.7 
  ) %>% layout(title = paste0('Type with the highest', name), 
               xaxis = list(title = 'Types'),
               yaxis = list(title = paste0('Base', name)),
               margin = m) 
  return(stats.bar)
}

#################################################################################################################

### LINE GRAPH ### 

# Finding the mean stats data for each generation

# Average overall stats
data.gen1 <- data.gen1 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
data.gen2 <- data.gen2 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
data.gen3 <- data.gen3 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
data.gen4 <- data.gen4 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
data.gen5 <- data.gen5 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
data.gen6 <- data.gen6 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)

# Make a line graph based on the value (make sure name input matches the column names)
makeLine <- function(value) {
  value <- paste0('mean(', value, ')')
  # getting the data to plot
  avg.stats.gen1 <- data.gen1 %>% 
    summarise_(mean = value) 
  avg.stats.gen2 <- data.gen2 %>% 
    summarise_(mean = value) 
  avg.stats.gen3 <- data.gen3 %>% 
    summarise_(mean = value) 
  avg.stats.gen4 <- data.gen4 %>% 
    summarise_(mean = value) 
  avg.stats.gen5 <- data.gen5 %>% 
    summarise_(mean = value) 
  avg.stats.gen6 <- data.gen6 %>% 
    summarise_(mean = value) 
  
  avg.stats <- rbind(avg.stats.gen1, avg.stats.gen2, avg.stats.gen3, avg.stats.gen4, avg.stats.gen5, avg.stats.gen6)
  generations <- c("1st Gen", "2nd Gen", "3rd Gen", "4th Gen", "5th Gen", "6th Gen")
  avg.stats$generations <- generations
  
  name <- gsub("[[:punct:]]", " ", value)
  
  line.graph <- plot_ly(avg.stats, x = ~generations, y = ~mean, type = 'scatter', mode = 'lines+markers') %>%
    layout(title = 'Stats change over each generation',
           xaxis = list(title = 'Generation'),
           yaxis = list(title = 'Average Base Stats'))
}

############################################################################################################

### PIE CHART ###

colors.df <- read.csv(file = '../data/color.csv', stringsAsFactors = FALSE)

# setting the colors
colors <- c('black', 'blue', 'brown', 'gray', 'green', 'pink', 'purple', 'red', 'white', 'yellow')
colors.text <- c('white', 'white', 'white', 'white', 'white', 'black', 'white', 'white', 'black', 'black')

# making the pie chart through plotly
makePie <- function() {
  pie <- plot_ly(colors.df, labels = ~color, values = ~count, type = 'pie',
                 textposition = 'inside',
                 textinfo = 'label+percent',
                 insidetextfont = list(color = colors.text),
                 hoverinfo = 'text',
                 text = ~paste(count, 'pokemon'),
                 marker = list(colors = colors,
                               line = list(color = 'black', width = 1)),
                 #The 'pull' attribute can also be used to create space between the sectors
                 showlegend = FALSE,
                 opacity = 0.8) %>%
    layout(title = 'Colors of Pokemon',
           font = list(color = c('black', 'blue', 'white', 'red', 'green', 'orange', 'gray', 'yellow', 'pink', 'purple'),
                       family = 'sans serif',
                       size = 14)
    )
  
  return(pie)
}

#######################################################################################

### SCATTER PLOT ### 

# Data for all Pokemons
all.pokemons <- rbind(data.gen1, data.gen2, data.gen3, data.gen4, data.gen5, data.gen6)

wh.df <- read.csv(file = '../data/weight_and_height.csv', stringsAsFactors = FALSE)
# Merged data between stats and weight/height
merged.data <- left_join(wh.df, all.pokemons)

# convert weight into lbs 
merged.data$weight <- lapply(merged.data$weight, ConvWeight)
merged.data$weight <- as.numeric(merged.data$weight)

# convert height into ft and inches
merged.data$height <- lapply(merged.data$height, ConvHeight)
merged.data$height <- as.numeric(merged.data$height)

# MAIN METHOD RETURNING A SCATTER PLOT DEPENDS ON THE X AND Y VALUE
makeScatter <- function(x.value, y.value) {
  x.value <- paste0('~', x.value)
  y.value <- paste0('~', y.value)
  
  # making scatter plot for plotly
  scatter <- plot_ly(merged.data, x =  eval(parse(text = x.value)), y =  eval(parse(text = y.value)), color =  eval(parse(text = x.value)),
                     size =  eval(parse(text = x.value)),
                     hoverinfo = 'text',
                     text = ~paste(weight, 'lbs, base health:', Health)) %>%
    layout(title = 'Correlation between the weight of the pokemon and its health',
           xaxis = list(title = 'Weight (lbs)'),
           yaxis = list(title = 'Health'))
  
  return(scatter)
}

##################################################################################

### HISTOGRAM ###

# MAIN METHOD MAKING A HISTOGRAM DEPENDS ON THE X VALUE
makeHisto <- function(x.value) {
  x.var <- paste0('~', x.value)
  
  histo.data <- merged.data %>% 
    group_by_(x.value)
  
  if (x.value == 'avg.stats') {
    x.value <- 'Average Base Stats'
  }
  
  name <- gsub("[[:punct:]]", " ", x.value)
  
  # making a histogram using plotly 
  histogram <- plot_ly(histo.data, x = eval(parse(text = x.var)), type = "histogram", color = '#E45051') %>%
    layout(title = 'Height Distribution',
           xaxis = list(title = 'Height (ft)'),
           yaxis = list(title = 'Number of Pokemon')) 
  
  return(histogram)
}