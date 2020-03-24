## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(heddlr)

## ----include=FALSE------------------------------------------------------------
setup_pattern <- "---\ntitle: \"My cool report!\"\nauthor: \"Captain heddlr\"\noutput: html_document\n---\n\n```{r setup}\nlibrary(dplyr)\nlibrary(ggplot2)\n```\n\n# Let's talk about irises!\n\n"
species_pattern <- "## Iris SPECIES_NAME\n\nThis species of flower is great! It has a mean sepal length of \n`r mean(iris[iris$Species == \"SPECIES_NAME\", \"Sepal.Length\"])`, and \nmean sepal width of `r mean(iris[iris$Species == \"SPECIES_NAME\", \"Sepal.Width\"])`. \nThat looks like this on a graph!\n\n```{r}\niris %>%\n  filter(Species == \"SPECIES_NAME\") %>%\n  ggplot(aes(Sepal.Length, Sepal.Width)) + \n  geom_point()\n```\n"

## ----eval=FALSE---------------------------------------------------------------
#  # These can be any sort of plaintext file -- I tend to save them as .Rmd,
#  # so that I can see code highlighting in R Studio with them, but any extension
#  # should work fine
#  setup_pattern <- import_pattern("setup_pattern.Rmd")
#  species_pattern <- import_pattern("species_pattern.Rmd")

## -----------------------------------------------------------------------------
setup_pattern

## ----eval=FALSE---------------------------------------------------------------
#  iris_draft <- import_draft(
#    "setup_pattern" = "setup_pattern.Rmd",
#    "species_pattern" = "species_pattern.Rmd"
#  )

## ----include=FALSE------------------------------------------------------------
iris_draft <- list(
  "setup_pattern" = setup_pattern,
  "species_pattern" = species_pattern
)

## -----------------------------------------------------------------------------
iris_draft

## -----------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(purrr)

## -----------------------------------------------------------------------------
# heddle takes three arguments: data, pattern, placeholder to replace
heddle(unique(iris$Species), "This is a pattern - CODE ", "CODE")

## -----------------------------------------------------------------------------
heddle(unique(iris$Species), iris_draft$species_pattern, "SPECIES_NAME")[[1]]

## -----------------------------------------------------------------------------
iris %>%
  distinct(Species) %>%
  # exact same pattern of arguments: data, pattern, placeholder to replace
  mutate(component = heddle(Species, iris_draft$species_pattern, "SPECIES_NAME"))

## -----------------------------------------------------------------------------
iris %>%
  distinct(Species) %>%
  # the data argument is provided by %>%
  # so we just provide the pattern and placeholder
  # (format "PLACEHOLDER" = Variable)
  heddle("This is a pattern - CODE ", "CODE" = Species)

## -----------------------------------------------------------------------------
iris %>%
  distinct(Species) %>%
  heddle("This is a pattern - CODE ", "CODE" = Species, "This" = Species)

## -----------------------------------------------------------------------------
iris %>%
  nest(nested = Species) %>%
  mutate(component = map(nested,
    heddle,
    "This is a pattern - CODE ",
    "CODE" = Species
  )) %>%
  head(2)

## ----eval=FALSE---------------------------------------------------------------
#  iris %>%
#    nest(nested = Species) %>%
#    mutate(component = map_chr(nested, heddle,
#      "This is a pattern - CODE ",
#      "CODE" = Species
#    ))
#  # > Error: Result 102 must be a single string, not a character vector of length 2

## -----------------------------------------------------------------------------
iris %>%
  nest(nested = Species) %>%
  mutate(
    component = map(nested, heddle, "This is a pattern - CODE ", "CODE" = Species),
    component = map_chr(component, make_template)
  ) %>%
  head(2)

## -----------------------------------------------------------------------------
iris %>%
  nest(nested = Species) %>%
  mutate(
    component = map(nested, heddle,
      "This is a pattern - CODE ",
      "CODE" = Species
    ),
    component = map_chr(component, make_template)
  ) %>%
  head(2) %>%
  make_template(component)

## -----------------------------------------------------------------------------
make_template("Part one, ", "part two")

## -----------------------------------------------------------------------------
species_template <- iris %>%
  distinct(Species) %>%
  mutate(component = heddle(
    Species,
    iris_draft$species_pattern,
    "SPECIES_NAME"
  )) %>%
  make_template(component)

report_template <- make_template(iris_draft$setup_pattern, species_template)

## -----------------------------------------------------------------------------
suppressWarnings(export_template(report_template, stdout()))

