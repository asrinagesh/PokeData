gen.1 <- 1:151
gen.2 <- 152:251
gen.3 <- 252:386
gen.4 <- 387:493
gen.5 <- 494:649
gen.6 <- 650:721
all.pokes <- 1:721

# Gets the generation, as a number from 1 to 6, or -1 if 
# it is a number such that <= 0 or > 721
GetGenOfPokemon <- function(id) {
  if(id < 1 | id > 721) {
    return(-1)
  } else if(id <= tail(gen.1, 1)) {
    return(1)
  } else if(id <= tail(gen.2, 1)) {
    return(2)
  } else if(id <= tail(gen.3, 1)) {
    return(3)
  } else if(id <= tail(gen.4, 1)) {
    return(4)
  } else if(id <= tail(gen.5, 1)) {
    return(5)
  } else {
    return(6)
  }
}

GetDataForPokemon <- function(id) {
  pokemon.df <- QueryApi(paste0("pokemon/", id))
  
  # basics
  id <- pokemon.df$id
  name <- pokemon.df$name
  type <- pokemon.df$types$type$name
  gen <- GetGenOfPokemon(id)
  
  #stats
  stat.df <- data.frame(pokemon.df$stats$stat$name, pokemon.df$stats$base_stat)
  stat.df <- stat.df %>% rename("Stat" = pokemon.df.stats.stat.name, "Value" = pokemon.df.stats.base_stat)
  speed <- stat.df %>% filter(Stat == "speed")
  spd <- stat.df %>% filter(Stat == "special-defense")
  hp <- stat.df %>% filter(Stat == "hp")
  defense <- stat.df %>% filter(Stat == "defense")
  attack <- stat.df %>% filter(Stat == "attack")
  spa <- stat.df %>% filter(Stat == "special-attack")
  
  print(paste(id, name))
  
  return(data.frame(id, name, gen, "Primary Type" = type, "Special Defense" = spd$Value,"Speed" = speed$Value, "Health" = hp$Value,
                    "Special Attack" = spa$Value, "Attack" = attack$Value, "Defense" = defense$Value, check.names = TRUE))
}

GetWeightAndHeight <- function(id) {
  pokemon.df <- QueryApi(paste0("pokemon/", id))
  id <- pokemon.df$id
  name <- pokemon.df$name
  type <- pokemon.df$types$type$name
  gen <- GetGenOfPokemon(id)
  weight <- pokemon.df$weight
  height <- pokemon.df$height
  df <- data.frame(id, name, gen, "Primary Type" = type, weight, height)
  return(df)
}

writeWHData <- function() {
  data.list <- lapply(all.pokes, GetWeightAndHeight)
  data.df <- do.call(rbind, data.list)
  write.csv(data.df, file = "../data/weight_and_height.csv", row.names = FALSE)
}


GetDataForColor <- function(id) {
  pokemon.df <- QueryApi(paste0("pokemon-species/", id))
  color <- pokemon.df$color$name
  return(color)
}

writeColorData <- function() {
  color.list <- lapply(all.pokes, GetDataForColor)
  color.df <- do.call(rbind, color.list)
  colnames(color.df) <- "color"
  color.df <- data.frame(color.df)
  color.df <- color.df %>% 
    group_by(color) %>%
    summarise(count = n())
  write.csv(color.df, file = "../data/color.csv", row.names = FALSE)
}

writeGenData <- function() {
  gen.1.list <- lapply(gen.1, GetDataForPokemon)
  gen.1.df <- do.call(rbind, gen.1.list)
  write.csv(gen.1.df, file = "~/Documents/School/INFO201/PokeData/gen1data.csv", row.names = FALSE)
  
  gen.2.list <- lapply(gen.2, GetDataForPokemon)
  gen.2.df <- do.call(rbind, gen.2.list)
  write.csv(gen.2.df, file = "~/Documents/School/INFO201/PokeData/gen2data.csv", row.names = FALSE)
  
  gen.3.list <- lapply(gen.3, GetDataForPokemon)
  gen.3.df <- do.call(rbind, gen.3.list)
  write.csv(gen.3.df, file = "~/Documents/School/INFO201/PokeData/gen3data.csv", row.names = FALSE)
  
  gen.4.list <- lapply(gen.4, GetDataForPokemon)
  gen.4.df <- do.call(rbind, gen.4.list)
  write.csv(gen.4.df, file = "~/Documents/School/INFO201/PokeData/gen4data.csv", row.names = FALSE)
  
  gen.5.list <- lapply(gen.5, GetDataForPokemon)
  gen.5.df <- do.call(rbind, gen.5.list)
  write.csv(gen.5.df, file = "~/Documents/School/INFO201/PokeData/gen5data.csv", row.names = FALSE)
  
  gen.6.list <- lapply(gen.6, GetDataForPokemon)
  gen.6.df <- do.call(rbind, gen.6.list)
  write.csv(gen.6.df, file = "~/Documents/School/INFO201/PokeData/gen6data.csv", row.names = FALSE)
  
  total <- rbind(gen.1.df, gen.2.df, gen.3.df, gen.4.df, gen.5.df, gen.6.df)
  
  averages <- gen.1.df %>% group_by(Primary.Type) %>% summarise(avg.spd = mean(Special.Defense), avg.speed = mean(Speed),
                                                                avg.health = mean(Health), avg.spa = mean(Special.Attack),
                                                                avg.attack = mean(Attack), avg.defense = mean(Defense),
                                                                avg.all = (avg.spd + avg.speed + avg.health + 
                                                                             avg.spa + avg.attack + avg.defense)/6)
  write.csv(averages, file = "~/Documents/School/INFO201/PokeData/type_averages.csv", row.names = FALSE)
  
}
