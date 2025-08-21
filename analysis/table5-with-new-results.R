options(crayon.enabled = FALSE)
suppressMessages(library(tidyverse))
suppressMessages(library(stringr))

read_traces <- function(file) {
    read_csv(file,
             skip = 6,
             progress=FALSE,
             col_names=FALSE,
             col_types=cols()) %>%
        rename(Counter = X1, Total = X2, Thread = X3)
}

lscpu_output <- system("lscpu", intern = TRUE)                                                                                                                                                                                             
# Get the CPU model name                                                                                                                                                                                                                
model_name_line <- grep("Model name:", lscpu_output, value = TRUE)                                                                                                                                                                         
processor_model <- gsub("Model name:\\s*", "", model_name_line)                                                                                                                                                                            
cleaned_model_name <- gsub("\\.", "", gsub(" ", "", gsub("\\(r\\)", "", tolower(processor_model))))

home_directory <- path.expand("~")

FOLDER <- paste(home_directory, "miniGiraffe/iiswc25", cleaned_model_name, "hw", sep = "/")
df <- tibble(SOURCE = list.files(FOLDER,
                                 pattern="miniGiraffe",
                                 recursive=FALSE,
                                 full.names=TRUE)
             )

df %>%
    mutate(DATA = map(SOURCE, read_traces)) %>%
    separate(SOURCE, c("XX1", "XX2", "XX3", "XX4", "XX5", "XX6", "XX7", "EXP"), sep="/") %>%
    separate(EXP, c("Threads", "Repetition", "XX7", "Source"), sep="_") %>%
    mutate(Source = str_replace_all(Source, "(.csv)", "")) %>%
    select(-contains("XX")) %>%
    unnest(DATA) %>%
    print() -> df.hw.mini

df.hw.mini %>%
  group_by(Counter) %>%
  summarize(Result = mean(Total)) %>%
  pivot_wider(names_from = Counter, values_from = Result) %>%
  mutate(IPC = instructions/cycles)