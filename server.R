library(crosstalk)
library(dplyr)
library(ggplot2)
library(httr)
library(plotly)
library(readr)
library(scales)
library(shiny)
library(tidyr)

#-------------------------------------
# LOAD THE DATABASE
#-------------------------------------

# database <- read_excel("www/dataset/Hungarian_first_and_middle_name_db_1954_2016.xlsx",
#                        col_types = "text") %>% 
#   mutate(RANK = as.numeric(RANK))

library(dplyr)

database <- read_csv("www/dataset/Common_Chinese_Names.csv") %>% 
  gather("YEAR", "NAME", -Rank) %>% 
  rename(RANK = Rank)

##### top10 names in last year
top10_name = database %>% 
  filter(YEAR == max(YEAR) & RANK <= 10) %>% 
  pull(NAME)

#-------------------------------------
# SHINY APP
#-------------------------------------

shinyServer(
  function(input, output) {
    
    data <- reactive({
      out = database %>% 
        filter(YEAR >= "2000" & (RANK <= 10 | NAME %in% top10_name)) %>% 
        mutate(
          RANK = if_else(RANK <= 10, RANK, 11),
          RANK_LABEL = if_else(RANK <= 10, as.character(RANK), "10+"),
          YEAR = as.numeric(YEAR)
        )
      
      out
    })
    
    output$plot <- renderPlotly({
      pdf(NULL)
      db = data()
      # db = out
      
      sd <- SharedData$new(db, ~NAME, group = "Choose the first name You want to highlight")
      gg = ggplot(sd, aes(x = YEAR, y = RANK, colour = NAME, text = NAME)) + 
        geom_point(size = 8) + 
        geom_line(size = 1.1, aes(group = NAME)) +
        geom_text(aes(label = paste0("#", RANK_LABEL)), color = "white", size=3.5) +
        scale_y_reverse("", breaks = seq(1, 11, 1), labels = c(seq(1, 10, 1), "10+"),
                        limits = c(11, 1)) +
        scale_x_continuous("", breaks = seq(2000, 2016, 1)) +
        guides(colour = guide_legend(override.aes = list(size=1))) +
        theme(legend.position="none",
              axis.title.y=element_blank(),
              axis.text.y=element_blank(),
              axis.ticks.y=element_blank(),
              panel.background = element_rect(fill = '#34495e'),
              panel.grid.major = element_blank())
      
      gg <- ggplotly(gg, tooltip = c("text")) %>%
        highlight(on = "plotly_click", persistent = FALSE, selectize = TRUE)  
      
      gg
    })
  }
)
