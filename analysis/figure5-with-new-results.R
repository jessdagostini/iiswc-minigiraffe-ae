options(crayon.enabled = FALSE)
suppressMessages(library(tidyverse))
suppressMessages(library(stringr))

read_traces <- function(file) {
    read_csv(file,
             skip = 1,
             progress=FALSE,
             col_names=FALSE,
             col_types=cols()) %>%
        rename(Query = X1, Runtime = X2, Thread = X3)
}

lscpu_output <- system("lscpu", intern = TRUE)                                                                                                                                                                                             
# Get the CPU model name                                                                                                                                                                                                                
model_name_line <- grep("Model name:", lscpu_output, value = TRUE)                                                                                                                                                                         
processor_model <- gsub("Model name:\\s*", "", model_name_line)                                                                                                                                                                            
cleaned_model_name <- gsub("\\.", "", gsub(" ", "", gsub("\\(r\\)", "", tolower(processor_model))))

home_directory <- path.expand("~")

FOLDER <- paste(home_directory, "iiswc-minigiraffe-ae/results", cleaned_model_name, "scalability", sep = "/")
df <- tibble(SOURCE = list.files(FOLDER,
                                 pattern="miniGiraffe",
                                 recursive=TRUE,
                                 full.names=TRUE)
             )
df

df %>%
    mutate(DATA = map(SOURCE, read_traces)) %>%
    separate(SOURCE, c("XX1", "XX2", "XX3", "XX4", "XX5", "XX6", "XX7", "EXP"), sep="/") %>%
    separate(EXP, c("Batches", "Threads", "Scheduler", "Repetition", "InputSet"), sep="_") %>%
    select(-contains("XX")) %>%
    unnest(DATA) %>%
    mutate(Batches = as.integer(Batches),
           Threads = as.integer(Threads),
           Repetition = as.integer(Repetition)) -> df.5.1

df.5.1 %>%
  filter(Query == "seeds-loop") %>%
  group_by(Threads, Scheduler, Repetition, InputSet) %>%
  summarize(Makespan = max(Runtime)) %>%
  ungroup() %>%
  group_by(Threads, Scheduler, InputSet) %>%
  summarize(AvgMakespan = mean(Makespan),
            MedianMakespan = median(Makespan)) -> df.5.1.makespan

df.5.1.makespan %>%
  ungroup() %>%
  arrange(Threads) %>%
  group_by(Scheduler, InputSet) %>%
  mutate(Baseline = first(AvgMakespan),
         Speedup = Baseline/AvgMakespan) %>%
  select(-MedianMakespan) %>%
  #write_csv("iiswc25/scalability_local-intel.csv") %>%
  print() -> df.5.1.speedup

colors_list <- c(
  "#f1a346",  # Light Amber
  "#7a4f91",  # Lavender Purple
  "#3c6e91",  # Steel Blue
  "#e67e22"  # Vivid Orange
)

p <- df.5.1.speedup %>%
  filter(Scheduler == "omp") %>%
  ggplot(aes(x=Threads, y=Speedup, color=InputSet)) +
  geom_line() +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  scale_color_manual(values=colors_list) + 
  scale_x_continuous("Threads", breaks=df.5.1.speedup$Threads) +
  #facet_wrap(~Machine, scales="free_x") + # comment out this line if you run in multiple machines
  ylim(0, 100) +
  theme_bw() +
  theme(legend.position = "top",
        text = element_text(size = 20),
        axis.text.y = element_text(angle = 45, hjust = 1, size=15),
        axis.text.x = element_text(angle = 45, hjust = 1, size=15))
ggsave("scalability-diff-machines.png", plot = p)
