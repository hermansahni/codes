//==============================================================================
//	MEPS DATA EXTRACTION
//==============================================================================
//	Written	by Herman Sahni, Baldwin Wallace University
//	version: 06/26/2020
//==============================================================================

clear all 
capture log close 
set more off 


log using "C:\MEPS\download_data", replace  // CREATE LOG FILE

cd "C:\MEPS\DATA" // SET CURRENT DIRECTORY 



local filenm h24 h57 h66 h76 h88 h95 h103 h111 h119 h127 h136 h145 h153 h161 h169 h179 h191 h200 


foreach k of local filenm { 

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}STEP 1: COPY REMOTE ZIPPED DAT FILE AND MAKE LOCAL {p_end}"
	di "{p}------------------------------------------------------------------{p_end}"

		copy "https://meps.ahrq.gov/data_files/pufs/`k'dat.zip" `k'dat.zip , replace 

	di "{p}COPY FILE - DONE ...... {p_end}"

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}STEP 2: UNZIP LOCAL FILE{p_end}" 
	di "{p}------------------------------------------------------------------{p_end}"

		unzipfile `k'dat , replace // unzip dat files 

	di "{p}UNZIP DONE ...... {p_end}" 

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}STEP 3: RENAMING FILENAME INTO STANDARD FORMAT{p_end}" 
	di "{p}------------------------------------------------------------------{p_end}"

		local myfiles: dir "C:\MEPS\DATA" files "*.DAT"

		foreach f of local myfiles {
			local subfile = upper(substr("`f'", 1, ustrlen("`f'")-4)) + ".dat"
				!rename "`f'" "`subfile'"
		}

	di "{p}RENAMING DONE ...... {p_end}" 

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}STEP 4: COPY REMOTE STATA CODE {p_end}" 
	di "{p}------------------------------------------------------------------{p_end}"

		copy "https://meps.ahrq.gov/data_stats/download_data/pufs/`k'/`k'stu.txt" dofile`k'stu.txt 

	di "{p}COPY CODE - DONE ...... {p_end}" 

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}STEP 4: RUN STATA CODE {p_end}" 
	di "{p}------------------------------------------------------------------{p_end}"
	
		do "C:\MEPS\DATA\dofile`k'stu.txt" 

	di "{p}RUN DO FILE DONE ...... {p_end}" 

	di "{p}------------------------------------------------------------------{p_end}"
	di "{p}erase files{p_end}" 
	di "{p}------------------------------------------------------------------{p_end}"

	local list1 : dir . files "*.DAT" 
	local list2 : dir . files "*.zip" 
	local list3 : dir . files "*.txt" 
	forval i = 1/3 {
		foreach f of local list`i' {
			capture erase "`f'" 
		}  
	} 

	di "{p}erase DONE ...... {p_end}" 

} 

log close // CLOSE OUTPUT 
