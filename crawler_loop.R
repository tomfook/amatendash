##run docker before start RSelenium
#docker run -d -p 4444:4444 selenium/standalone-chrome

library(RSelenium)
library(rvest)
library(dplyr)
library(readr)
library(magrittr)

while(TRUE){
  source("param.R")

  remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4444, browserName = "chrome")
  remDr$open()
  remDr$navigate("https://amaten.com/exhibitions/amazon")
  Sys.sleep(1)
  src <- remDr$getPageSource()[[1]]

  ts <- lubridate::now()
  
  tbl <- read_html(src) %>%
    html_nodes(xpath = "/html/body/div[1]/div/div[2]/div/div[2]/div/div[3]/table") %>%
    html_table 

  if(length(tbl) > 0){
    tbl <- tbl[[1]][,2:3]
    
    tbl %>%
      mutate_all(readr::parse_number) %>%
      set_names(c("face_price", "selling_price")) %>%
      mutate(timestamp = ts) %>%
      select(timestamp, everything()) %>%
      write.table(
        "history2.csv",
        sep = ",",
        append = TRUE, col.names=FALSE,
        row.names = FALSE
      ) 

    qty <- src %>%
      read_html %>%
      html_nodes(css = ".js-all-gift-count") %>%
      html_text %>%
      parse_number 
    write(paste0(ts, ",", qty), "qty.csv", append = TRUE) 
  }else{
    print(paste("Could not read table at", lubridate::now()))
  }

  remDr$close()

  wait <- rexp(n=1, rate = 1/(24*60*60/average_per_day))
  Sys.sleep(wait)
} 
