#####Midwestern Agriculture Synthesis#####
#####Citations & Introduction Statements######

library("readxl")
library("dplyr")
library("stringr")
library("stringi")
library("tidyverse")
library("forcats")

setwd("C:/Users/LWA/Desktop/github/midwesternag_synthesis/")


#import data
fullfile <- read_excel("PestMgmt Review/PestMgmt_Review_completefile.xlsx")
  ref <- read.csv("PestMgmt Review/PestMgmt_Review_Reference.csv")
    cashcrop <- read.csv("PestMgmt Review/PestMgmt_Review_CashCrop.csv")
      trtmt <- read.csv("PestMgmt Review/PestMgmt_Review_Treatment.csv")
        results <- read.csv("PestMgmt Review/PestMgmt_Review_Results.csv")
          expd <- read.csv("PestMgmt Review/PestMgmt_Review_ExpD_Location.csv")
          
          ref_expd <- left_join(ref, expd)
      
        ###NOTE: Use Paper_id list to filter papers for synthesis writing
        
        #monocultures <- read.csv("C:/Users/LWA/github/midwesternag_synthesis/monocultures_data.csv", header=TRUE, row.names = "X")
        #mixtures <- read.csv("C:/Users/LWA/github/midwesternag_synthesis/mixtures_data.csv", header=TRUE, row.names = "X")
        
        #df <-
          #filter(fullfile,!(Trt_id1 > 0)) #set dataframe to work with - only using comparisons to control (0)
        df_results <- results %>%
                filter(Trt_id1 < 1, Stat_type == "mean") #set dataframe to work with - only using comparisons to control (0)
       
        
        #df <- filter(monocultures, !(Trt_id1>0)) #set dataframe to work with - only using comparisions to control (0)
        #df <- filter(mixtures, !(Trt_id1>0)) #set dataframe to work with - only using comparisions to control (0)
        #df <- arrange(df, Paper_id)
        df_results <- arrange(df_results, Paper_id)
        df_refexp <- ref_expd
        df_trtmt <- trtmt
        
        ###Synthesis Output################################################################################################################
        #Run this code for each metric grouping (from query script)
        
        #####Citations####################################
        
        df_refexp$citation <- df_refexp %>%
          str_glue_data(
            "{Paper_id} {Authors} ({PubYear}). {Title}. {Journal}, {Volume_issue}: {Pages}. DOI: {DOI}"
          )
        
        df_refexp$citation_short <- df_refexp %>%
            str_glue_data("{Authors_abbrev} ({PubYear})")
        
        #print list of citations
        noquote(unique(df_refexp$citation))
        
        df_citation <- df_refexp %>%
          group_by(Paper_id) %>%
          distinct(citation)
        
        df_citation_short <- df_refexp %>%
          group_by(Paper_id) %>%
          distinct(citation_short)
        
      CC_citation_summary <- left_join(df_citation, df_citation_short)
        
        
        #need to italize Journal name <- preferably italize entire column
        
        
        
        ###Paper-level synthesis##################################################################################################
        
        #Prepare df####
        
        ###Create conditional statement for experimental design and experimental arrangement####
        
        #Experiment_row <- df %>%
         # select(Exp_design, Exp_arrangement, Res_key, Paper_id) %>%
        #  mutate(Exp_list_row = case_when(
         #   !is.na(Exp_arrangement)  ~ paste(Exp_arrangement, Exp_design),!is.na(Exp_design)  ~ paste(Exp_design)
        #  ))
        #unique(Experiment_row$Exp_list_row)
        
        
        Experiment_row <- df_refexp %>%
          select(Exp_design, Exp_arrangement, Paper_id) %>%
          mutate(Exp_list_row = case_when(
            !is.na(Exp_arrangement)  ~ paste(Exp_arrangement, Exp_design),!is.na(Exp_design)  ~ paste(Exp_design)
          ))
        unique(Experiment_row$Exp_list_row)
        
        #Generate list of treatments included in each experiment.
        Exp_list <- Experiment_row %>%
          group_by(Paper_id) %>%
          summarise (Exp_list = paste(unique(Exp_list_row), collapse =
              ", "))
        
        #Inspect Treatment list
        View(Exp_list)
        
        #Attach column with list of treatments to dataframe
        df_refexp <-
          left_join(df_refexp, Exp_list)
        
        
        ###Create City, State lists#####
        
        #Make column that combines city, state for each row
        df_refexp$city_state <-
          if_else(
            !is.na(df_refexp$City),
            paste(df_refexp$City, df_refexp$State, sep = ", "),
            paste(df_refexp$State)
          )
        
        #Then create lists and rename column
        countSpaces <- function(s) { sapply(gregexpr(" ", s), function(p) { sum(p>=0) } ) } #used to determine preceeding proposition
        
        city_statelist <- df_refexp %>%
          group_by(Paper_id) %>%
          summarise (city_state_list = paste(unique(city_state), collapse =
              ", "))
        
       #conditional statement for "in" (city, state) or "at" (research center)
      city_statelist$city_state_list2 <- if_else(grepl("University" , city_statelist$city_state_list), paste("at", city_statelist$city_state_list, sep = " "),
                                      if_else(grepl("Station", city_statelist$city_state_list), paste("at", city_statelist$city_state_list, sep = " "),
                                          if_else(grepl("Research", city_statelist$city_state_list), paste("at", city_statelist$city_state_list, sep = " "), 
                                            paste("in", city_statelist$city_state_list, sep = " "))))
                                              
        
        
        #ATtach list of city, states to dataset
        df_refexp <-
          left_join(df_refexp, city_statelist, by = "Paper_id")
        
        
        ###Create Experimental Treatment lists####
        
        #Make column that combines all treatments for each study
        Trtmt_list_row <- df_refexp %>%
          select(Trtmt_main:Trtmt_splitC, Paper_id) %>%
          mutate(Trtmt_list_row = case_when(
            !is.na(Trtmt_splitC)  ~ paste(
              Trtmt_main,
              ", ",
              Trtmt_splitA,
              ", ",
              Trtmt_splitB,
              ", and " ,
              Trtmt_splitC,
              sep = ""
            ),!is.na(Trtmt_splitB)  ~ paste(Trtmt_main, ", ", Trtmt_splitA, ", and ", Trtmt_splitB, sep = ""),!is.na(Trtmt_splitA)  ~ paste(Trtmt_main, " and ", Trtmt_splitA, sep = ""),!is.na(Trtmt_main)  ~ paste(Trtmt_main)
          ))
        
        
        
        #Generate list of treatments included in each experiment.
        Trtmt_list <- Trtmt_list_row %>%
          group_by(Paper_id) %>%
          summarise (Trtmt_list = paste(unique(Trtmt_list_row), collapse =
              ", "))
        
        #Inspect Treatment list
        View(Trtmt_list)
        
        #Attach column with list of treatments to dataframe
        df_refexp <-
          left_join(df_refexp, Trtmt_list)
        
        
        ###Consolidate Start & End Years across site locations####
        
        #Set dates for end of experiment
        df_refexp$Year_end <-
          df_refexp$Year_start + df_refexp$Years_num
        
        #Concatenate year start and year end
        df_refexp$Years_exp <-
          paste(df_refexp$Year_start, df_refexp$Year_end, sep = "-")
        
        years_list <- df_refexp %>%
          group_by(Paper_id) %>%
          summarise (years_list = paste(unique(Years_exp), collapse =
              " and "))
        unique(years_list)
        
        #Attach list of years study is conducted to dataset
        df_refexp <-
          left_join(df_refexp, years_list, by = "Paper_id")
        
        
        
        #Count number of sites for each experiment####
        
        df_refexp <- df_refexp %>%
          group_by(Paper_id) %>%
          mutate(unique_locations = n_distinct(Loc_multi))
        
        
        
        Unique_locations_text <- df_refexp %>%
          select(unique_locations, Paper_id) %>%
          mutate(Unique_locs_text_row = case_when(
            unique_locations == 1  ~ paste(unique_locations, "site"),
            unique_locations != 1  ~ paste(unique_locations, "sites")
          ))
        
        
        
        #Generate list of treatments included in each experiment.
        Unique_locs_text <-
          Unique_locations_text %>%
          group_by(Paper_id) %>%
          summarise (locs_text = paste(unique(Unique_locs_text_row), collapse =
              ", "))
        
        #Inspect Treatment list
        View(Unique_locs_text)
        
        #Attach column with list of treatments to dataframe
        df_refexp <-
          left_join(df_refexp, Unique_locs_text)
        colnames(df)
        
        
        #Count number of replications for each experiment####
        reps_list <- df_refexp %>%
          group_by(Paper_id) %>%
          summarise (reps_list = paste(unique(Reps), collapse =
              " or "))
        
        unique(reps_list)
        
        #Attach list of years study is conducted to dataset
        df_refexp <-
          left_join(df_refexp, reps_list, by = "Paper_id")
        
        #need to remove NAs (possibly with if else statement + is.na)
        #need to add *and* before last treatment
        
        ######Dealing with NAs for Exp_arrangement & Exp_design
        Trtmt_list_row <- df_refexp %>%
          select(Trtmt_main:Trtmt_splitC, Paper_id) %>%
          mutate(Trtmt_list_row = case_when(
            !is.na(Trtmt_splitC)  ~ paste(
              Trtmt_main,
              ", ",
              Trtmt_splitA,
              ", ",
              Trtmt_splitB,
              ", and " ,
              Trtmt_splitC,
              sep = ""
            ),!is.na(Trtmt_splitB)  ~ paste(Trtmt_main, ", ", Trtmt_splitA, ", and ", Trtmt_splitB, sep = ""),!is.na(Trtmt_splitA)  ~ paste(Trtmt_main, " and ", Trtmt_splitA, sep = ""),!is.na(Trtmt_main)  ~ paste(Trtmt_main)
          ))
        
        #Generate list of treatments included in each experiment.
        Trtmt_list <- Trtmt_list_row %>%
          group_by(Paper_id) %>%
          summarise (Trtmt_list = paste(unique(Trtmt_list_row), collapse =
              ", "))
        
        #Inspect Treatment list
        View(Trtmt_list)
        
        #Attach column with list of treatments to dataframe
        df_refexp <-
          left_join(df_refexp, Trtmt_list)
        
        #Join RefExp with Cash crops
        df2 <-
          left_join(df_refexp, cashcrop)
        
        
        
        #######INTRODUCTION Statement #################
        df2$intro <- df2 %>%
          str_glue_data(
            "{Paper_id} A {Exp_list} study with {reps_list} replications was conducted at {locs_text} from {years_list} {city_state_list2} investigating the effects of {Trtmt_list} in a {Cash_species} system ({Authors_abbrev}, {PubYear})."
          )
        unique(df2$intro)
        
        df_intro <- df2 %>%
          select(Paper_id, intro) %>%
          group_by(Paper_id) %>%
          summarise(introduction = paste(unique(intro), collapse = " "))
        
        
        
        
        ######Results#####
        #Continue adding results (short & long) to dataframe.
        df_results2 <- df_results %>%
                      select(Paper_id:Loc_multi_results, Group_RV, group_metric, main_group, Group_finelevel, Response_var,Trt_id1, Trt1_interaction, Trt1_interaction2 , Trt_id1description ,Trt_id2, Trt2_interaction, Trt2_interaction2 , Trt_id2description , Reviewers_results_short, Reviewers_results_long) %>%
                      mutate(results_short = str_c("They found ", {df_results$Reviewers_results_short}, " "))
                      
        df_results_short <- df_results2 %>%
          select(Paper_id:Loc_multi_results, Group_RV, group_metric, main_group, Group_finelevel, Response_var,Trt_id1, Trt1_interaction, Trt1_interaction2 , Trt_id1description ,Trt_id2, Trt2_interaction, Trt2_interaction2 , Trt_id2description , Reviewers_results_short, Reviewers_results_long) %>%
          distinct(results_short)
        
        df_results_long <- df_results2 %>%
          select(Paper_id:Loc_multi_results, Group_RV, group_metric, main_group, Group_finelevel, Response_var,Trt_id1, Trt1_interaction, Trt1_interaction2 , Trt_id1description ,Trt_id2, Trt2_interaction, Trt2_interaction2 , Trt_id2description , Reviewers_results_short, Reviewers_results_long) %>%
          distinct(Reviewers_results_long)
        
        
        #need abridged dataframe for each unique paper to synthesize across
        
        results_summary <- left_join(df_results_short, df_results_long)
        
        
        
        #import methods and merge with intro and results
        methods_summary <- read.csv("methods_summary.csv", header=TRUE, row.names = "X")
        
        
        #Join and export full summary table for Review ###############
        intro_results_summary <- left_join(df_intro, results_summary)
        review_summary1 <- left_join(intro_results_summary, methods_summary)
        review_summary <- left_join(review_summary1, citation_summary)
        
        review_summary <- review_summary %>%
                              filter(Group_finelevel != "none")
        
        
        write.csv(review_summary, file = "report_summary.csv")
        
        
        ####Extra unused code####
        ##### Experiments with Cover crop mixtures####
        colnames(mix_soil_om)
        
        #create abridged table with pertinent information
        # Directionality of results (+/0/-)
        df.mix_soil_om_abridged <- select(
          mix_soil_om,
          c(
            Paper_id,
            Loc_multi.x,
            Plot_width,
            Plot_length,
            Cash_tillage:Cash_genetics,
            Trt_id:Loc_multi.y,
            Group_RV:Authors_comments
          )
        )
        
        
        
