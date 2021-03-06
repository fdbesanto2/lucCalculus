#################################################################
##                                                             ##
##   (c) Adeline Marinho <adelsud6@gmail.com>                  ##
##                                                             ##
##       Image Processing Division                             ##
##       National Institute for Space Research (INPE), Brazil  ##
##                                                             ##
##                                                             ##
##  R script to compute Frequqncy, Area, CumSum,               ##
##  Freqquency relative and Frequency Relative CumSum          ##
##  and prepare input data                                     ##
##                                             2018-08-28      ##
##                                                             ##
##                                                             ##
#################################################################


#' @title Data.frame with statistical measures
#' @name lucC_result_measures
#' @aliases lucC_result_measures
#' @author Adeline M. Maciel
#' @docType data
#'
#' @description Provide a data.frame with main statistical measures to resultd from LUC Calculus application such as: Area (km2),
#' Cumulative Sum, Relative Frequency and Cumulative Relative Frequency
#'
#' @usage lucC_result_measures (data_mtx = NULL, data_frequency = NULL, pixel_resolution = 250)
#'
#' @param data_mtx         Matrix. A matrix with values obtained from predicates RECUR, EVOLVE, CONVERT or HOLDS
#' @param data_frequency   Dataframe. A frequency table of a categorical variable from a data set
#' @param pixel_resolution Numeric. Is a spatial resolution of the pixel. Default is 250 meters considering MODIS 250 m. See more at \url{https://modis.gsfc.nasa.gov/about/specifications.php}.
#'
#' @keywords datasets
#' @return Data frame with statistical measures
#' @import ggplot2
#' @importFrom ensurer ensure_that
#' @importFrom tidyr gather
#' @importFrom dplyr mutate bind_cols group_by
#' @export
#'
#' @examples \dontrun{
#' library(lucCalculus)
#'
#' file <- c(system.file("extdata/raster/rasterSample.tif", package = "lucCalculus"))
#' rb_class <- raster::brick(file)
#' my_label <- c("Degradation", "Fallow_Cotton", "Forest", "Pasture", "Soy_Corn", "Soy_Cotton",
#'               "Soy_Fallow", "Soy_Millet", "Soy_Sunflower", "Sugarcane", "Urban_Area", "Water")
#' my_timeline <- c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01",
#'                  "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01",
#'                  "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01",
#'                  "2016-09-01")
#'
#' b <- lucC_pred_recur(raster_obj = rb_class, raster_class = "Forest",
#'                      time_interval1 = c("2001-09-01","2001-09-01"),
#'                      time_interval2 = c("2002-09-01","2016-09-01"),
#'                      label = my_label, timeline = my_timeline)
#'
#' lucC_result_measures(data_mtx = b, pixel_resolution = 232)
#'
#'}
#'

lucC_result_measures <- function(data_mtx = NULL, data_frequency = NULL, pixel_resolution = 250){

  # Ensure if parameters exists
  #ensurer::ensure_that(data_mtx, !is.null(data_mtx),
  #                     err_desc = "data_mtx matrix, file must be defined!\nThis data can be obtained using predicates RECUR, HOLDS, EVOLVE and CONVERT.")
  ensurer::ensure_that(pixel_resolution, !is.null(pixel_resolution),
                       err_desc = "pixel_resolution must be defined! Default is 250 meters on basis of MODIS image")

  # input data matrix or a frequency table
  if (!is.null(data_mtx)){
    # to data frame
    #input_data <- reshape2::melt(as.data.frame(data_mtx), id = c("x","y"))
    input_data <- as.data.frame(data_mtx) %>%
      tidyr::gather(variable, value, -x, -y)

    input_data <- input_data[!duplicated(input_data), ]
    # count number of values
    dataMeasures.df <- data.frame(table(lubridate::year(input_data$variable), input_data$value)) %>%
      dplyr::mutate(Area_km2 = (.$Freq*(pixel_resolution*pixel_resolution))/(1000*1000)) # Area

  } else if (!is.null(data_frequency)){
    # already
    input_data <- data_frequency
    colnames(input_data) <- c("Var1", "Var2", "Freq")
    # count number of values
    dataMeasures.df <- input_data %>%
      dplyr::mutate(Area_km2 = (.$Freq*(pixel_resolution*pixel_resolution))/(1000*1000)) # Area
  } else {
    stop("\nProvide at least a 'data_mtx' or a 'data_frequency' to plot graphics!\n")
  }

  colnames(dataMeasures.df)[c(1:3)] <- c("Years", "Classes", "Pixel_number")

 # compute absolute frequency
  dataMeasures.df <- dataMeasures.df %>%
    dplyr::group_by(Classes) %>%
    dplyr::mutate(Cumulative_Sum = cumsum(Area_km2)) %>% # rev_area
    as.data.frame() %>%
    dplyr::bind_cols()

  # compute relative frquency for each label
  dataMeasures.df <- dataMeasures.df %>%
    dplyr::group_by(Classes) %>%
    dplyr::mutate(Relative_Frequency = (Area_km2/max(Cumulative_Sum))*100) %>%
    as.data.frame() %>%
    dplyr::bind_cols()

  # compute relative frequency cumsum for each label
  dataMeasures.df <- dataMeasures.df %>%
    dplyr::group_by(Classes) %>%
    dplyr::mutate(Cumulative_Relative_Frequency = cumsum(Relative_Frequency)) %>%
    as.data.frame() %>%
    dplyr::bind_cols()

  dataMeasures.df

  return(as.data.frame(dataMeasures.df))

}


#' @title Categorical frequency from a list of data.frames
#' @name lucC_extract_frequency
#' @aliases lucC_extract_frequency
#' @author Adeline M. Maciel
#' @docType data
#'
#' @description Provide a data.frame with count of categorical variables from a list of data.frame derived of processing with many blocks of RasterBricks
#'
#' @usage lucC_extract_frequency (data_mtx.list = NULL, cores_in_parallel = 1)
#'
#' @param data_mtx.list       Matrix. A list of matrix with values obtained from predicates RECUR, EVOLVE, CONVERT or HOLDS for each block of RasterBrick
#' @param cores_in_parallel   Integer. Number of cores to use, in other words the amount of child processes will be run simultaneously. Default is 1 core, that means no one parallelization.
#'
#' @keywords datasets
#' @return Data frame with statistical measures
#' @import ggplot2
#' @importFrom ensurer ensure_that
#' @importFrom stats na.omit
#' @importFrom parallel mclapply
#' @importFrom tidyr gather
#' @importFrom dplyr group_by summarise
#' @export
#'
#' @examples \dontrun{
#' library(lucCalculus)
#'
#' file <- c(system.file("extdata/raster/rasterSample.tif", package = "lucCalculus"))
#' rb_class <- raster::brick(file)
#' my_label <- c("Degradation", "Fallow_Cotton", "Forest", "Pasture", "Soy_Corn", "Soy_Cotton",
#'               "Soy_Fallow", "Soy_Millet", "Soy_Sunflower", "Sugarcane", "Urban_Area", "Water")
#' my_timeline <- c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01",
#'                  "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01",
#'                  "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01",
#'                  "2016-09-01")
#'
#' # list empty to store the holds operations
#' data.list <- list(NULL)
#'
#' data.list[[1]] <- lucC_pred_holds(raster_obj = rb_class, raster_class = "Pasture",
#'                                   time_interval = c("2001-09-01","2016-09-01"),
#'                                   label = my_label, timeline = my_timeline)
#' data.list[[2]] <- lucC_pred_holds(raster_obj = rb_class, raster_class = "Degradation",
#'                                   time_interval = c("2001-09-01","2016-09-01"),
#'                                   label = my_label, timeline = my_timeline)
#' data.list
#'
#' # extract frequency from list data
#' d <- lucC_extract_frequency(data_mtx.list = data.list, cores_in_parallel = 2)
#'
#' # use the frequency extracted from list
#' lucC_result_measures(data_frequency = d, pixel_resolution = 232)
#'
#'
#'}
#'

lucC_extract_frequency <- function(data_mtx.list = NULL, cores_in_parallel = 1){

  # Ensure if parameters exists
  ensurer::ensure_that(data_mtx.list, !is.null(data_mtx.list),
                       err_desc = "data_mtx matrix, file must be defined!\nThis data can be obtained using predicates RECUR, HOLDS, EVOLVE and CONVERT.")

  # remove null elementos of the list
  data_mtx.list[sapply(data_mtx.list, is.null)] <- NULL

  # function to melt each data.frame of a list
  .meltFromList <- function(x){
    #raster_data <- reshape2::melt(as.data.frame(x), id.vars = c("x","y"), na.rm = TRUE)
    raster_data <- as.data.frame(x) %>%
      tidyr::gather(variable, value, -x, -y) %>%
      stats::na.omit()

    raster_data$x = as.numeric(as.character(raster_data$x))
    raster_data$variable = as.character(as.character(raster_data$variable))
    raster_data$y = as.numeric(as.character(raster_data$y))

    raster_data <- raster_data[!duplicated(raster_data), ]

    # count number of values
    result <- data.frame(table(lubridate::year(raster_data$variable), raster_data$value))

    return(result)
  }

  # result
  out <- parallel::mclapply(X = data_mtx.list, mc.cores = cores_in_parallel, FUN = .meltFromList)

  # aggregate all list reshaped in a output of data
  output <- do.call(rbind, out)
  #result <- stats::aggregate(output$Freq, by=list(output$Var1, output$Var2), FUN = sum) # conflict with raster::aggregate

  result <- output %>%
    dplyr::group_by(., Var1, Var2) %>%
    dplyr::summarise(., sum(Freq)) %>%
    as.data.frame()

  result$Var1 <- as.numeric(as.character(result$Var1)) # remove factor of first column
  result <- result[ order(result$Var2, result$Var1), ]
  rownames(result) <- NULL

  colnames(result) <- c("Years", "Classes", "Freq")

  return(result)

}

