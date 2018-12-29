library(plotly)

shinyUI(fluidPage(
  plotlyOutput("plot", height = "700px", width = "100%")
))
