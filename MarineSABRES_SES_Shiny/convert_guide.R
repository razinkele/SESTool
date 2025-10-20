# Convert markdown user guide to HTML

library(markdown)

# Read markdown
md_file <- "www/MarineSABRES_Complete_User_Guide.md"
output_file <- "www/user_guide.html"

# Read content
md_content <- paste(readLines(md_file, warn = FALSE), collapse = "\n")

# Convert to HTML fragment
html_body <- markdownToHTML(text = md_content, fragment.only = TRUE)

# Create full HTML with styling
html_template <- '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MarineSABRES User Guide</title>
<style>
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  color: #24292e;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  margin: 0;
  padding: 20px;
}
.container {
  max-width: 1100px;
  margin: 0 auto;
  background: white;
  padding: 50px;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}
h1 {
  font-size: 2.5em;
  color: #667eea;
  border-bottom: 3px solid #667eea;
  padding-bottom: 10px;
  margin-top: 40px;
}
h2 {
  font-size: 2em;
  color: #764ba2;
  border-bottom: 2px solid #ddd;
  padding-bottom: 8px;
  margin-top: 35px;
}
h3 {
  font-size: 1.5em;
  color: #555;
  margin-top: 25px;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin: 25px 0;
}
table th {
  background: #667eea;
  color: white;
  padding: 12px;
  text-align: left;
}
table td {
  padding: 10px;
  border: 1px solid #ddd;
}
table tr:nth-child(even) {
  background: #f9f9f9;
}
code {
  background: #f4f4f4;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: Consolas, monospace;
  font-size: 90%;
}
pre {
  background: #2d2d2d;
  color: #f8f8f2;
  padding: 20px;
  border-radius: 6px;
  overflow-x: auto;
}
pre code {
  background: none;
  color: inherit;
  padding: 0;
}
a {
  color: #667eea;
  text-decoration: none;
}
a:hover {
  text-decoration: underline;
}
ul, ol {
  padding-left: 30px;
}
li {
  margin-bottom: 8px;
}
hr {
  border: none;
  height: 2px;
  background: linear-gradient(to right, #667eea, #764ba2);
  margin: 40px 0;
}
strong {
  color: #667eea;
}
.back-top {
  position: fixed;
  bottom: 30px;
  right: 30px;
  background: #667eea;
  color: white;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  font-size: 24px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  cursor: pointer;
}
.back-top:hover {
  background: #764ba2;
  transform: translateY(-3px);
}
</style>
</head>
<body>
<div class="container">
%s
</div>
<a href="#" class="back-top" onclick="window.scrollTo({top:0,behavior:\'smooth\'});return false;">↑</a>
</body>
</html>'

# Combine (use paste0 to avoid sprintf format issues)
html_full <- paste0(
  '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MarineSABRES User Guide</title>
<style>
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  color: #24292e;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  margin: 0;
  padding: 20px;
}
.container {
  max-width: 1100px;
  margin: 0 auto;
  background: white;
  padding: 50px;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}
h1 {
  font-size: 2.5em;
  color: #667eea;
  border-bottom: 3px solid #667eea;
  padding-bottom: 10px;
  margin-top: 40px;
}
h2 {
  font-size: 2em;
  color: #764ba2;
  border-bottom: 2px solid #ddd;
  padding-bottom: 8px;
  margin-top: 35px;
}
h3 {
  font-size: 1.5em;
  color: #555;
  margin-top: 25px;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin: 25px 0;
}
table th {
  background: #667eea;
  color: white;
  padding: 12px;
  text-align: left;
}
table td {
  padding: 10px;
  border: 1px solid #ddd;
}
table tr:nth-child(even) {
  background: #f9f9f9;
}
code {
  background: #f4f4f4;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: Consolas, monospace;
  font-size: 90%;
}
pre {
  background: #2d2d2d;
  color: #f8f8f2;
  padding: 20px;
  border-radius: 6px;
  overflow-x: auto;
}
pre code {
  background: none;
  color: inherit;
  padding: 0;
}
a {
  color: #667eea;
  text-decoration: none;
}
a:hover {
  text-decoration: underline;
}
ul, ol {
  padding-left: 30px;
}
li {
  margin-bottom: 8px;
}
hr {
  border: none;
  height: 2px;
  background: linear-gradient(to right, #667eea, #764ba2);
  margin: 40px 0;
}
strong {
  color: #667eea;
}
.back-top {
  position: fixed;
  bottom: 30px;
  right: 30px;
  background: #667eea;
  color: white;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  font-size: 24px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  cursor: pointer;
}
.back-top:hover {
  background: #764ba2;
  transform: translateY(-3px);
}
</style>
</head>
<body>
<div class="container">
',
  html_body,
  '
</div>
<a href="#" class="back-top" onclick="window.scrollTo({top:0,behavior:\'smooth\'});return false;">↑</a>
</body>
</html>')

# Write to file
writeLines(html_full, output_file)

cat("User guide HTML created successfully at:", output_file, "\n")
