libs <- c(
    "tidyverse", "terra",
    "giscoR", "tidyterra"
)

installed_libs <- libs %in% rownames(
    installed.packages()
)

if (any(installed_libs == F)) {
    install.packages(
        libs[!installed_libs]
    )
}

invisible(
    lapply(
        libs, library,
        character.only = TRUE
    )
)
urls <- c(
    "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E1990_GLOBE_R2023A_4326_30ss/V1-0/GHS_POP_E1990_GLOBE_R2023A_4326_30ss_V1_0.zip",
    "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_4326_30ss/V1-0/GHS_POP_E2020_GLOBE_R2023A_4326_30ss_V1_0.zip"
)

options(timeout = 300)

for (url in urls) {
    download.file(
        url = url,
        path = getwd(),
        destfile = basename(url)
    )
}

lapply(
    basename(urls),
    unzip
)
file_names <- list.files(
    path = getwd(),
    pattern = "tif$",
    full.names = T
)

pop_rasters <- lapply(
    file_names,
    terra::rast
)
lapply(
    pop_rasters,
    terra::describe
)
get_country_borders <- function() {
    country <- giscoR::gisco_get_countries(
        country = "KZ",
        resolution = "1"
    )

    return(country)
}

country <- get_country_borders()

country_pop_rasters <- lapply(
    pop_rasters,
    function(x) {
        terra::crop(
            x,
            terra::vect(country),
            snap = "in",
            mask = T
        )
    }
)
terra::plot(pop_change)
get_categories <- function(x){
    terra::ifel(
        pop_change == 0, 0,
        terra::ifel(
            pop_change > 0, 1,
            terra::ifel(
                pop_change < 0, -1, pop_change
            )
        )
    )
}

pop_change_cats <- get_categories(pop_change) |>
    as.factor()

cols <- c(
    "#eb389f",
    "grey80",
    "#018f1d"
)

p <- ggplot() +
    tidyterra::geom_spatraster(
        data = pop_change_cats
    ) +
    geom_sf(
        data = country,
        fill = "transparent",
        color = "grey40",
        size = .5
    ) +
    scale_fill_manual(
        name = "Growth or decline?",
        values = cols,
        labels = c(
            "Decline",
            "Uninhabited",
            "Growth"
        ),
        na.translate = FALSE
    ) +
    guides(
        fill = guide_legend(
            direction = "horizontal",
            keyheight = unit(5, "mm"), 
            keywidth = unit(40, "mm"),
            label.position = "bottom",
            label.hjust = .5,
            nrow = 1,
            byrow = T,
            drop = T
        )
    ) +
    coord_sf(crs = crs_lambert) +
    theme_void() +
    theme(
        legend.position = c(.5, .95),
        legend.title = element_text(
            size = 30, color = "grey20",
        ),
        legend.text = element_text(
            size = 25, color = "grey20",
        ),
        plot.caption = element_text(
            size = 20, color = "grey40",
            hjust = .5, vjust = 10
        ),
        plot.margin = unit(
            c(
                t = .5, b = -3,
                l = -3, r = -3
            ), "lines"
        )
    ) +
    labs(
        caption = "Global Human Settlement Layer at 30 arcsecs"
    )

w <- ncol(pop_change_cats)
h <- nrow(pop_change_cats)

ggsave(
    "romania-population-change.png",
    p,
    width = w * 5,
    height = h * 5,
    units = "px",
    bg = "white"
)
