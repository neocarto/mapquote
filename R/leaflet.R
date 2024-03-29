# --------------------------------------
# MAP QUOTE PROJET (N. LAMBERT, 2019)
# https://neocarto.github.io/mapquote/
# --------------------------------------

library(leaflet)
library(bibtex)
library(RefManageR)
library(htmltools)
library(htmlwidgets)
library(filesstrings)

# SORT AND RESAVE DATA FILE ------------------------------------------------------------



quotes <- read.csv("data/quotes.csv", stringsAsFactors = FALSE)
quotes <- quotes[order(quotes$book), ]
write.csv(quotes, "data/quotes.csv", row.names = FALSE)

authors <- read.csv("data/authors.csv", stringsAsFactors = FALSE)
authors <- authors[order(authors$author), ]
write.csv(authors, "data/authors.csv", row.names = FALSE)

words <- read.csv("data/words.csv", stringsAsFactors = FALSE)
words <- as.data.frame(words[order(words$words), ])
colnames(words) <- "words"
write.csv(words, "data/words.csv", row.names = FALSE)

books <- ReadBib(file = "data/biblio.bib")
books <- sort(books, sorting = "nyt")
WriteBib(books, file = "data/biblio.bib", append = FALSE, verbose = F, Encoding = "utf8")


# DATA IMPORT  ------------------------------------------------------------

bib <- ReadBib(file = "data/biblio.bib")
bib <- as.data.frame(bib)
bib$id <- row.names(bib)
bib$author <- sub("\\}", "", bib$author)
bib$author <- sub("\\{", "", bib$author)

q <- read.csv("data/quotes.csv", stringsAsFactors = FALSE)
loc <- read.csv("data/authors.csv", stringsAsFactors = FALSE)
quotes <- merge(x = q, y = bib, by.x = "book", by.y = "id", all.y = T)
quotes <- merge(x = quotes, y = loc, by.x = "author", by.y = "author", all.y = T)

words <- read.csv("data/words.csv", stringsAsFactors = FALSE)
words <- words$words

# POPUP FORMATING -----------------------------------------------------------


quotes$publisher[is.na(quotes$publisher)] <- "(éditeur inconnu)"

col <- "#fce303"
for (i in 1:length(words)) {
  quotes$quote <- sub(paste0(" ", words[i], " "), paste0(" <span style='background:", col, "'>", words[i], "</span> </u>"), quotes$quote)
  quotes$quote <- sub(paste0(" ", words[i], "\\,"), paste0(" <span style='background:", col, "'>", words[i], "</span>,</u>"), quotes$quote)
  quotes$quote <- sub(paste0(" ", words[i], "\\."), paste0(" <span style='background:", col, "'>", words[i], "</span>.</u>"), quotes$quote)
}

quotes$labelhtml <- paste0(
  "<div width='300px' align='center'>",
  "<h2>",
  "« ", quotes$quote, " »",
  "</h2>",
  "<b>", quotes$author, "</b> ", quotes$location, ".<br/>",
  "<i>", quotes$title, "</i>. ", quotes$publisher, ", ", quotes$year, ".",
  "</div>"
)

# TITLE -----------------------------------------------------------

title <- tags$div(includeCSS("css/maptitle.css"), HTML("<i>MapQuote</i>"))
source <- tags$div(includeCSS("css/mapnote.css"), HTML(paste0("Source : <b>N. Lambert</b>, <b>F. Bahoken</b> et contributeurs.trices [<a href = 'contributors.html'>voir</a>]. Mise à jour : ", Sys.Date(), " (", dim(authors)[1], " auteurs, ", dim(bib)[1], " livres et ", dim(quotes)[1], " citations)")))
contrib <- tags$div(includeCSS("css/contrib.css"), HTML("<a href='form.html'><img src='img/contribuez.svg'></img></a>"))

# PIN -----------------------------------------------------------

pins <- makeIcon(
  iconUrl = "img/pin.svg",
  iconWidth = 30, iconHeight = 30,
  iconAnchorX = 15, iconAnchorY = 15
)

m <- leaflet(quotes) %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  setView(lng = 4, lat = 46, zoom = 06) %>%
  addMarkers(~lng, ~lat, popup = ~labelhtml, clusterOptions = markerClusterOptions(), icon = pins) %>%
  addScaleBar(position = "bottomleft") %>%
  addControl(title, className = "map-title") %>%
  addControl(source, className = "map-note") %>%
  addControl(contrib, className = "map-contrib")

saveWidget(m, file = "index.html", title = "MapQuote", selfcontained = TRUE)
# file.move("index.html", "../", overwrite = TRUE)

# BUILDING CONTRIB PAGE -----------------------------------------------------------

x1 <- "<!DOCTYPE html>\n
<html>\n<head>\n
<link rel='stylesheet' type='text/css' href='css/form.css'/>\n
</head>\n
<body>\n
<div class='container'>\n
<form action='https://formspree.io/nicolas.lambert@cnrs.fr' method='POST' id='contact'/>\n
<h3>Ils et elles ont contribué au projet <b>MapQuote</b>.</h3><br/><hr/><h4>\n"

x2 <- read.csv("data/contributors.csv", stringsAsFactors = FALSE)
x2$alph <- paste(x2$nom, x2$prenom, sep = "")
x2 <- x2[order(x2$alph), ]
x2 <- paste(x2$prenom, x2$nom, sep = " ")
x2 <- paste(x2, collapse = ", ")

x3 <- "</h4><hr/><p class='copyright'><br/>\n
Retournez à la carte<br/>\n
<a href='https://neocarto.github.io/mapquote/' target='_blank' title='mapqoute'>neocarto.github.io/mapquote</a>\n
</p></div>\n
</body>\n
</html>"

x <- paste0(x1, x2, x3)

write(x,
  file = "contributors.html",
  ncolumns = if (is.character(x)) 1 else 5,
  append = FALSE, sep = " "
)
