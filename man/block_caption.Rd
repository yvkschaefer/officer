% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ooxml_block_objects.R
\name{block_caption}
\alias{block_caption}
\title{caption block}
\usage{
block_caption(label, style, id = NULL, autonum = NULL)
}
\arguments{
\item{label}{a scalar character representing label to display}

\item{style}{paragraph style name}

\item{id}{cross reference identifier}

\item{autonum}{an object generated with function \link{run_autonum}}
}
\description{
Create a representation of a
caption that can be used for cross reference. The caption
can also be an auto numbered paragraph.
}
\examples{

library(magrittr)
library(officer)

run_num <- run_autonum(seq_id = "tab", pre_label = "tab. ")
caption <- block_caption("iris table",
                         style = "Normal", id = "iris_table",
                         autonum = run_num )

doc <- read_docx() \%>\%
  body_add("A title", style = "heading 1") \%>\%
  body_add("Hello world!", style = "Normal") \%>\%
  body_add(caption) \%>\%
  body_add(iris, style = "table_template")

print(doc, target = tempfile(fileext = ".docx") )
}
\seealso{
Other block functions for reporting: 
\code{\link{block_list}()},
\code{\link{block_section}()},
\code{\link{block_table}()},
\code{\link{block_toc}()},
\code{\link{fpar}()},
\code{\link{plot_instr}()},
\code{\link{unordered_list}()}
}
\concept{block functions for reporting}
