library(httr)
library(magrittr)

my_file <- "testmark"

res <- 
  POST(
 "http://your_remote_server_url:8000/knit?output_format=html_document",
    body = list(
      data = upload_file(paste0(my_file, ".Rmd"), "text/plain")
    )
  ) %>%
  content()

names(res)

output_filename <- file(paste0(my_file, ".tar.gz"), "wb")
writeBin(object = res, con = output_filename)
close(output_filename)
