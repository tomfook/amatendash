##run docker before start RSelenium
#docker run -d -p 4444:4444 selenium/standalone-chrome

#parameter
average_per_day <- 3

library(RSelenium)
library(rvest)
library(dplyr)
library(magrittr)

while(TRUE){
  remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4444, browserName = "chrome")
  remDr$open()
  remDr$navigate("https://amaten.com/exhibitions/amazon")
  Sys.sleep(1)
  src <- remDr$getPageSource()[[1]]
  
  tbl <- read_html(src) %>%
    html_nodes(xpath = "/html/body/div[1]/div/div[2]/div/div[2]/div/div[3]/table") %>%
    html_table 
  tbl <- tbl[[1]][,2:3]
  
  price <- tbl %>%
    mutate_all(readr::parse_number) %>%
    set_names(c("face_price", "selling_price")) %>%
    mutate(timestamp = lubridate::now()) %>%
    select(timestamp, everything()) %>%
    write.table(
      "~/Documents/shiny-apps/amaten/history2.csv",
      sep = ",",
      append = TRUE, col.names=FALSE,
      row.names = FALSE
    )

  remDr$close()

  wait <- rexp(n=1, rate = 1/(24*60*60/average_per_day))
  Sys.sleep(wait)
}

  







