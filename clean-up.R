# Clean up large fils

extra_dir <- fs::dir_ls(path = here::here("rt-estimates-out"), 
												#regexp = "\\d{4}-\\d{2}\\d{2}", 
												recurse = TRUE,type = "directory")
to_remove <- extra_dir[grepl("\\d+$", extra_dir)]

fs::dir_delete(to_remove)

