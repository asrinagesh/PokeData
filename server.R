library(shiny)
library(httr)
library(jsonlite)
library(plotly)

base.uri <- "http://pokeapi.co/api/v2/"

  QueryApi <- function(query) {
    full.uri <- paste0(base.uri, query)
    response <- GET(full.uri)
    data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    return(data)
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
    
    plot_ly(type = "bar", data = stat.df, x = ~Stat, y = ~Value) %>% layout(yaxis = list(range = c(0, 150)))
  })
  
  output$image <- renderImage({
    data <- QueryApi(paste0("pokemon/", input$pokemon))
    
    filename <- normalizePath(file.path('./www/imgs/sprites/', paste0(data$id, '.png')))
    
    # Return a list containing the filename and alt text
    list(src = filename,
         width = 187,
         height = 187,
         alt = paste("Sprite", data$id))
    
  }, deleteFile = FALSE)
  
})
