# functions/indicator_snapshot.R
# WS-4 element side: element frames carry ISA_INDICATOR_COLUMNS. Picking a
# registry entry copies values (snapshot) and records Registry_Id/_Version;
# drift = the registry entry's revision moved on since the snapshot.

#' Column of an element frame by name, case-insensitive; "" for absent/NA.
indicator_col <- function(df, name) {
  if (!is.data.frame(df)) return(character(0))
  hit <- which(tolower(names(df)) == tolower(name))
  if (length(hit) == 0) return(rep("", nrow(df)))
  v <- as.character(df[[hit[1]]])
  v[is.na(v)] <- ""
  v
}
