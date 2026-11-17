# Shared test helper: stub the global knowledge-base lookup (evidenced polarity)

# local_mocked_bindings() needs a pkgload package, which this suite is not, so
# stub the global lookup by assignment and restore it when the test ends.
stub_kb <- function(value, env = parent.frame()) {
  had <- exists("lookup_knowledge_base", envir = globalenv(), inherits = FALSE)
  orig <- if (had) get("lookup_knowledge_base", envir = globalenv())
  assign("lookup_knowledge_base", function(...) value, envir = globalenv())
  withr::defer({
    if (had) assign("lookup_knowledge_base", orig, envir = globalenv())
    else rm("lookup_knowledge_base", envir = globalenv())
  }, envir = env)
}
