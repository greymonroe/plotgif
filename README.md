# plotgif

Turn a list of R plots into an animated GIF, in one call.

```r
# install once
install.packages("remotes")
remotes::install_github("greymonroe/plotgif")

library(plotgif)
```

No install? Source the two files straight from GitHub (needs the `magick` package, and
`scatterplot3d` for the 3D helpers):

```r
source("https://raw.githubusercontent.com/greymonroe/plotgif/main/R/make_gif.R")
source("https://raw.githubusercontent.com/greymonroe/plotgif/main/R/plane3d.R")
```

## make_gif()

Give it a list of plots in order. Each element is a **ggplot object** or a **function with no
arguments that draws with base graphics**. It writes one PNG per frame and stitches them.

```r
library(ggplot2)

frames <- lapply(5:50, function(n) {
  ggplot(mtcars[1:n, ], aes(wt, mpg)) + geom_point() + xlim(1, 6) + ylim(10, 35) +
    labs(title = paste(n, "cars")) + theme_classic()
})
make_gif(frames, file = "mtcars.gif", dir = "gifs", width = 600, height = 450, fps = 8)
```

```r
# base graphics: wrap the drawing code in function()
frames <- lapply(seq(0, 2 * pi, length.out = 40), function(a) function() {
  plot(cos(a), sin(a), xlim = c(-1, 1), ylim = c(-1, 1), pch = 16, cex = 3, xlab = "", ylab = "")
})
make_gif(frames, "circle.gif", width = 400, height = 400, fps = 20)
```

Arguments: `file`, `dir`, `width`, `height` (pixels), `fps` or per-frame `delay` (seconds,
e.g. `delay = c(rep(0.1, 9), 1)` to hold the last frame), `loop` (0 = forever), `res`
(text size), `keep_frames = TRUE` to keep the PNGs.

## Rotating regression plane

The teaching case this was built for: a two-predictor linear model as a plane through a
3D cloud of points, with the residuals drawn, rotating.

```r
wheat <- read.csv("https://greymonroe.github.io/PLS_206/data/wheat_plants.csv")
model2 <- lm(biomass ~ height + nitrogen, data = wheat)

rotate3d_gif(wheat$height, wheat$nitrogen, wheat$biomass, model2,
             file = "plane.gif", dir = "gifs", width = 800, height = 650,
             xlab = "Height (cm)", ylab = "Nitrogen (kg/ha)", zlab = "Biomass (g)")
```

![rotating regression plane](man/figures/plane.gif)

`rotate3d_gif()` is just `make_gif(plane3d_frames(...))`; `plane3d_frame()` draws a single
angle if you want a static figure or your own frame list (for example, a rotation that
pauses: `angles = c(rep(40, 10), seq(40, 400, by = 5))`).

## Why

Built for [PLS 206](https://greymonroe.github.io/PLS_206/) (Applied Multivariate Modeling,
UC Davis): the heavy code lives here so course scripts stay a few lines long.
