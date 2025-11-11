data <- readRDS('C:/Users/DELL/AppData/Local/Temp/RtmpK89SR0/marinesabres_autosave/latest_autosave.rds')

cat('=== AUTO-SAVE FILE CONTENTS ===\n\n')
cat(sprintf('Project ID: %s\n', data$project_id))
cat(sprintf('Last modified: %s\n', data$last_modified))

if (!is.null(data$data) && !is.null(data$data$isa_data)) {
  isa <- data$data$isa_data
  cat(sprintf('\nISA Data: %d element types\n', length(isa)))

  if (length(isa) > 0) {
    cat('\nElement Details:\n')
    for (name in names(isa)) {
      if (is.data.frame(isa[[name]])) {
        cat(sprintf('  %s: %d rows\n', name, nrow(isa[[name]])))
        if (nrow(isa[[name]]) > 0) {
          cat(sprintf('    Sample: %s\n', paste(head(isa[[name]]$Name, 2), collapse=', ')))
        }
      }
    }
    cat('\n✅ SUCCESS: ISA data is present and complete!\n')
  } else {
    cat('\n❌ PROBLEM: isa_data is empty list\n')
  }
} else {
  cat('\n❌ PROBLEM: isa_data is NULL\n')
}
