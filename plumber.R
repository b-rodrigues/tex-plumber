#* Knit Rmarkdown document
#* @param data:file The Rmd file
#* @param string The output format
#* @post /knit
# We use serializer contentType, the pdf serializer is the plot output from grDevices
# Since the content is already in the right format from render, we just need to set
# the content-type
#* @serializer contentType list(type = "application/gzip")
function(data, output_format) { #data is my Rmd file
  # save the binary blob to a temp location
  rmd_doc <- file.path(tempdir(), names(data))
  writeBin(data[[1]], rmd_doc)
  # render document to pdf (file will be saved side by side with source but with pdf extension)
  output <- rmarkdown::render(rmd_doc, output_format)
  tar("output.tar.gz", normalizePath(output), compression = "gzip", tar = "tar")
  # remove files on exit
  on.exit({file.remove(rmd_doc, output, "output.tar.gz")}, add = TRUE)
  # Include file in response as attachment
  value <- readBin("output.tar.gz", "raw", file.info("output.tar.gz")$size)
  plumber::as_attachment(value, basename("output.tar.gz"))
}

