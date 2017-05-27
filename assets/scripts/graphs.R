#  Load in the data
library(jsonlite)
library(httr)
library(dplyr)
library(plotly)
library(RColorBrewer)

setwd('C:/Users/Tu/Desktop/Sophomore Year/Spring/INFO 201/PokeData/assets/scripts')

# Read in Data
data.gen1 <- read.csv(file = '../data/gen1data.csv', stringsAsFactors = FALSE)
data.gen2 <- read.csv(file = '../data/gen2data.csv', stringsAsFactors = FALSE)
data.gen3 <- read.csv(file = '../data/gen3data.csv', stringsAsFactors = FALSE)
data.gen4 <- read.csv(file = '../data/gen4data.csv', stringsAsFactors = FALSE)
data.gen5 <- read.csv(file = '../data/gen5data.csv', stringsAsFactors = FALSE)
data.gen6 <- read.csv(file = '../data/gen6data.csv', stringsAsFactors = FALSE)
data.stats <- read.csv(file = '../data/type_averages.csv', stringsAsFactors = FALSE)

### Popular Types Bar ### 

# For all Pokemons
all.pokemons <- rbind(data.gen1, data.gen2, data.gen3, data.gen4, data.gen5, data.gen6)


## 1st Gen ## 
pokemon.df.gen1 <- data.gen1 %>% 
  filter(id == 1) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 

gen1.number <- c(2:151)
lapply(gen1.number, getTypes)

getTypes <- function(number) {
  new.pokemon.df <- data.gen1 %>%
    filter(id == number) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen1, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  pokemon.df.gen1 <<- total # the << to break the scope and to access value in lapply
}

m <- list(
  l = 200,
  r = 50,
  b = 200,
  t = 100,
  pad = 4
)

color.pokemons <- c('#208000', '#ffff99', '#ffff1a', '#ff66ff', '#660000', '#e60000', '#d9d9d9', '#290066', 
                    '#40ff00', '#cc9900', '#b3fff0', '#ffe6cc', '#8000ff', '#db4dff', '#996633', '#ccccff',
                    '#0099ff')

# chart for popular types (input filter allows for different generation)
popular.bar.gen1 <- plot_ly(pokemon.df.gen1,
  x = ~Primary.Type,
  y = ~count,
  type = 'bar',
  color = ~Primary.Type,
  colors = color.pokemons
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons'),
             margin = m) 


## 2nd Gen ##

pokemon.df.gen2 <- data.gen2 %>% 
  filter(id == 152) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 
for (i in 153:251) {
  
  # new column with the most recent data
  new.pokemon.df <- data.gen2 %>%
    filter(id == i) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen2, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  
  pokemon.df.gen2 <- total
}

# chart for popular types (input filter allows for different generation)
popular.bar.gen2 <- plot_ly(pokemon.df.gen2,
                            x = ~Primary.Type,
                            y = ~count,
                            type = 'bar',
                            color = ~Primary.Type
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons'),
             margin = m)

## 3rd Gen ##

pokemon.df.gen3 <- data.gen3 %>% 
  filter(id == 252) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 
for (i in 253:386) {
  
  # new column with the most recent data
  new.pokemon.df <- data.gen3 %>%
    filter(id == i) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen3, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  
  pokemon.df.gen3 <- total
}

# chart for popular types (input filter allows for different generation)
popular.bar.gen3 <- plot_ly(pokemon.df.gen3,
                            x = ~Primary.Type,
                            y = ~count,
                            type = 'bar',
                            color = ~Primary.Type
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons') ) 

## 4th Gen ##

pokemon.df.gen4 <- data.gen4 %>% 
  filter(id == 387) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 
for (i in 388:493) {
  
  # new column with the most recent data
  new.pokemon.df <- data.gen4 %>%
    filter(id == i) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen4, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  
  pokemon.df.gen4 <- total
}

# chart for popular types (input filter allows for different generation)
popular.bar.gen4 <- plot_ly(pokemon.df.gen4,
                            x = ~Primary.Type,
                            y = ~count,
                            type = 'bar',
                            color = ~Primary.Type
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons') ) 


## 5th Gen ##

pokemon.df.gen5 <- data.gen5 %>% 
  filter(id == 494) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 
for (i in 495:649) {
  
  # new column with the mot recent data
  new.pokemon.df <- data.gen5 %>%
    filter(id == i) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen5, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  
  pokemon.df.gen5 <- total
}

# chart for popular types (input filter allows for different generation)
popular.bar.gen5 <- plot_ly(pokemon.df.gen5,
                            x = ~Primary.Type,
                            y = ~count,
                            type = 'bar',
                            color = ~Primary.Type
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons') ) 


## 6th Gen ##

pokemon.df.gen6 <- data.gen6 %>% 
  filter(id == 650) %>%
  group_by(Primary.Type) %>%
  summarise(count = n()) 
for (i in 651:721) {
  
  # new column with the mot recent data
  new.pokemon.df <- data.gen6 %>%
    filter(id == i) %>%
    group_by(Primary.Type) %>%
    summarise(count = n()) 
  
  # bind the old data with new data 
  total <- rbind(pokemon.df.gen6, new.pokemon.df)
  # updating the count number 
  total <- total %>% 
    group_by(Primary.Type) %>%
    summarise(count = sum(count))
  
  
  pokemon.df.gen6 <- total
}

# chart for popular types (input filter allows for different generation)
popular.bar.gen6 <- plot_ly(pokemon.df.gen6,
                            x = ~Primary.Type,
                            y = ~count,
                            type = 'bar',
                            color = ~Primary.Type
) %>% layout(title = 'Pokemon Type Distribution',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Number of Pokemons') ) 

## STACKED BAR CHART ##
# Making a stacked bar chart
stacked.bar <- plot_ly(pokemon.df.gen1, x = ~Primary.Type, y = ~count, type = 'bar', name = 'Gen 1') %>%
  add_trace(pokemon.df.gen2, x = ~Primary.Type, y = ~count, name = 'Gen 2') %>% 
  add_trace(pokemon.df.gen3, x = ~Primary.Type, y = ~count, name = 'Gen 3') %>% 
  add_trace(pokemon.df.gen4, x = ~Primary.Type, y = ~count, name = 'Gen 4') %>% 
  add_trace(pokemon.df.gen5, x = ~Primary.Type, y = ~count, name = 'Gen 5') %>% 
  add_trace(pokemon.df.gen6, x = ~Primary.Type, y = ~count, name = 'Gen 6') %>% 
  layout(title = 'Pokemon Type Distribution',
         xaxis = list(title = 'Types'),
         yaxis = list(title = 'Number of Pokemons'), barmode = 'stack' , margin = m) 

####################################################################

### STATS BAR ##

# with widget input can select what stats they want to show (avg.speed, overall, etc.)
stats.bar <- plot_ly(data.stats,
                     x = ~Primary.Type,
                     y = ~avg.all,
                     type = 'bar',
                     color = ~Primary.Type,
                     colors = ~color.pokemons
) %>% layout(title = 'Highest Overall Stats',
             xaxis = list(title = 'Types'),
             yaxis = list(title = 'Highest Stats'),
             margin = m) 

####################################################################

# We can teach kids about strength and con of different graph 
### Line Graph ### depend on input to change the data
data.gen1 <- data.gen1 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen1 <- data.gen1 %>% 
  summarise(mean = mean(avg.stats)) 

data.gen2 <- data.gen2 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen2 <- data.gen2 %>% 
  summarise(mean = mean(avg.stats)) 

data.gen3 <- data.gen3 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen3 <- data.gen3 %>% 
  summarise(mean = mean(avg.stats)) 

data.gen4 <- data.gen4 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen4 <- data.gen4 %>% 
  summarise(mean = mean(avg.stats)) 

data.gen5 <- data.gen5 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen5 <- data.gen5 %>% 
  summarise(mean = mean(avg.stats)) 

data.gen6 <- data.gen6 %>% mutate(avg.stats = (Special.Defense + Speed + Health + Special.Attack + Attack + Defense) / 6)
avg.stats.gen6 <- data.gen6 %>% 
  summarise(mean = mean(avg.stats)) 

avg.stats <- rbind(avg.stats.gen1, avg.stats.gen2, avg.stats.gen3, avg.stats.gen4, avg.stats.gen5, avg.stats.gen6)
generations <- c("1st Gen", "2nd Gen", "3rd Gen", "4th Gen", "5th Gen", "6th Gen")
avg.stats$generations <- generations

line.graph <- plot_ly(avg.stats, x = ~generations, y = ~mean, type = 'scatter', mode = 'lines+markers') %>%
  layout(title = 'Overall stats change over each generation',
             xaxis = list(title = 'Generation'),
             yaxis = list(title = 'Overall Stats')) 

########################################################################

### PIE CHART ###
colors.df <- read.csv(file = '../data/color.csv', stringsAsFactors = FALSE)
colors <- c('black', 'blue', 'brown', 'gray', 'green', 'pink', 'purple', 'red', 'white', 'yellow')
colors.text <- c('white', 'white', 'white', 'white', 'white', 'black', 'white', 'white', 'black', 'black')

pie <- plot_ly(colors.df, labels = ~color, values = ~count, type = 'pie',
             textposition = 'inside',
             textinfo = 'label+percent',
             insidetextfont = list(color = colors.text),
             hoverinfo = 'text',
             text = ~paste(count, 'pokemons'),
             marker = list(colors = colors,
                           line = list(color = 'black', width = 1)),
             #The 'pull' attribute can also be used to create space between the sectors
             showlegend = FALSE) %>%
  layout(title = 'Colors of all Pokemons',
         xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
         yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))

wh.df <- read.csv(file = '../data/weight_and_height.csv', stringsAsFactors = FALSE)

# Merged data between stats and weight/height
merged.data <- left_join(wh.df, all.pokemons)

scatter <- plot_ly(merged.data, x = ~weight, y = ~Health, color = ~weight,
                   size = ~weight) %>%
  layout(title = 'Correlation between the weight of the pokemon and its health')