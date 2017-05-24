gen.1 <- 1:151
gen.2 <- 152:251
gen.3 <- 252:386
gen.4 <- 387:493
gen.5 <- 494:649
gen.6 <- 650:721

# Gets the generation, as a number from 1 to 6, or -1 if 
# it is a number such that <= 0 or > 721
GetGenOfPokemon <- function(id){
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