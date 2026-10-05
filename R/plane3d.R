#' One frame of a 3D scatterplot with a fitted plane and residuals
#'
#' Draws `z ~ x + y` as a 3D scatterplot (scatterplot3d package) seen from a given
#' viewing angle, with the least-squares plane of `model` and a vertical residual segment
#' from each point to the plane. Meant to be called inside [make_gif()] via
#' [plane3d_frames()], but works on its own for a static figure.
#'
#' @param x,y,z Numeric vectors: the two predictors and the response.
#' @param model A fitted `lm(z ~ x + y)` (any model with two predictors in the same order).
#' @param angle Viewing angle in degrees (scatterplot3d's `angle`).
#' @param xlab,ylab,zlab Axis labels.
#' @param col_points,col_plane,col_resid Colours for the points, the plane, and the residuals.
#' @param cex_points Point size.
#' @param zlim Optional z range, so the axis does not change between frames.
#' @param main Optional title.
#' @param ... Passed on to [scatterplot3d::scatterplot3d()].
#' @return The scatterplot3d object, invisibly.
#' @export
plane3d_frame <- function(x, y, z, model, angle = 40, xlab = "x", ylab = "y", zlab = "z",
                          col_points = "#619CFF", col_plane = "#FF0000", col_resid = "#7030A0",
                          cex_points = 1.3, zlim = NULL, main = NULL, ...) {
  if (!requireNamespace("scatterplot3d", quietly = TRUE))
    stop("plane3d_frame() needs the 'scatterplot3d' package: install.packages(\"scatterplot3d\")")
  if (is.null(zlim)) zlim <- range(c(z, stats::fitted(model)))
  s3 <- scatterplot3d::scatterplot3d(x, y, z, pch = 16, color = col_points, cex.symbols = cex_points,
                                     xlab = xlab, ylab = ylab, zlab = zlab, angle = angle, zlim = zlim,
                                     grid = TRUE, box = FALSE, main = main, ...)
  s3$plane3d(model, draw_polygon = TRUE, draw_lines = TRUE,
             polygon_args = list(col = grDevices::adjustcolor(col_plane, 0.15), border = col_plane))
  obs <- s3$xyz.convert(x, y, z)
  fit <- s3$xyz.convert(x, y, stats::fitted(model))
  graphics::segments(obs$x, obs$y, fit$x, fit$y, col = col_resid, lwd = 1.5)
  # redraw the points on top of the plane so none are hidden
  graphics::points(obs$x, obs$y, pch = 16, col = col_points, cex = cex_points)
  invisible(s3)
}

#' A list of plane3d frames at a sequence of viewing angles
#'
#' @inheritParams plane3d_frame
#' @param angles Viewing angles in degrees, one per frame (default a full turn in 5-degree steps).
#' @return A list of zero-argument functions, ready for [make_gif()].
#' @export
plane3d_frames <- function(x, y, z, model, angles = seq(0, 355, by = 5), ...) {
  zlim <- range(c(z, stats::fitted(model)))
  lapply(angles, function(a) {
    force(a)
    function() plane3d_frame(x, y, z, model, angle = a, zlim = zlim, ...)
  })
}

#' Rotating 3D plot of a two-predictor regression, as a GIF
#'
#' The one-liner: points, fitted plane, and residuals for `z ~ x + y`, rotated through
#' `angles`, written to a GIF.
#'
#' @inheritParams plane3d_frames
#' @inheritParams make_gif
#' @param ... Passed on to [plane3d_frame()] (labels, colours).
#' @return The path of the GIF, invisibly.
#' @examples
#' \dontrun{
#' m <- lm(Volume ~ Girth + Height, data = trees)
#' rotate3d_gif(trees$Girth, trees$Height, trees$Volume, m, file = "trees.gif",
#'              xlab = "Girth", ylab = "Height", zlab = "Volume")
#' }
#' @export
rotate3d_gif <- function(x, y, z, model, file = "rotate3d.gif", dir = ".", width = 800, height = 650,
                         fps = 12, angles = seq(0, 355, by = 5), res = 120, ...) {
  make_gif(plane3d_frames(x, y, z, model, angles = angles, ...),
           file = file, dir = dir, width = width, height = height, fps = fps, res = res)
}
