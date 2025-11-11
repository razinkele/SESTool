data <- readRDS('C:/Users/DELL/AppData/Local/Temp/RtmpeAgTbd/marinesabres_autosave/latest_autosave.rds')

cat('Project structure:\n')
cat(sprintf('  project_id: %s\n', data$project_id))
cat(sprintf('  last_modified: %s\n', data$last_modified))

cat('\nData section:\n')
if (is.null(data$data)) {
  cat('  data is NULL\n')
} else {
  cat(sprintf('  data is a %s with %d elements\n', class(data$data)[1], length(data$data)))
  cat(sprintf('  data names: %s\n', paste(names(data$data), collapse=', ')))
}

cat('\nISA Data section:\n')
if (is.null(data$data) || is.null(data$data$isa_data)) {
  cat('  isa_data is NULL\n')
} else {
  isa <- data$data$isa_data
  cat(sprintf('  isa_data is a %s with %d elements\n', class(isa)[1], length(isa)))

  if (length(isa) > 0) {
    cat('\n  Element counts:\n')
    for (name in names(isa)) {
      if (is.data.frame(isa[[name]])) {
        cat(sprintf('    %s: %d rows x %d cols\n', name, nrow(isa[[name]]), ncol(isa[[name]])))
        if (nrow(isa[[name]]) > 0) {
          cat(sprintf('      Column names: %s\n', paste(names(isa[[name]]), collapse=', ')))
        }
      } else {
        cat(sprintf('    %s: %s (not a dataframe)\n', name, class(isa[[name]])[1]))
      }
    }
  } else {
    cat('  isa_data is empty list\n')
  }
}
