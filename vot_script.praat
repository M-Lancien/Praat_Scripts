#################################
#
# Extract informations on VOT based a on tier in a textgrid
#
# Author : Melanie Lancien 09/2022
#
################################"

form Extract_acoustic_parameters
	#comment Folder with textgrids (all textgrids must have the same structure)
	text textgrids_folder C:\Users\33665\Dropbox\isolated_words\corrected VOT of JV data\adele_british_pulse_textgrids
	#comment Regular expression for filtering textgrids in folder (* = any string)
	text regexp *.TextGrid
	#comment Folder with sounds (leave empty if same as textgrids folder or to extract only duration and context)
	text wavefiles_folder C:\Users\33665\Dropbox\isolated_words\wav\adel_british
	#comment Output file
	text results_file C:\Users\33665\Dropbox\isolated_words\resultats.txt
	comment Index of the tier with labels to be processed
	positive reference_tier 1
	comment Index of the other interval tier from which labels should be extracted (0 = none, -1 = all interval tiers)
	integer secondary_tier 0
	boolean Extract_F0 1
	boolean Extract_HNR 1
	boolean Extract_intensity 1
	boolean Extract_formants 1
	boolean Extract_left_and_right_context 0
	boolean Extract_min_max_and_standard_deviation 1
	comment Speakers gender (used to parameterize formants extraction)
	optionmenu speakers_gender: 1
	option F
	option M
	positive offset_for_acoustic_parameters_extraction_milliseconds 30
endform

# Clear info window
clearinfo

# Check parameters values
if wavefiles_folder$ = ""
	wavefiles_folder$ = textgrids_folder$
endif


# Get the list of textgrids in the specified folder that match the regular expression
flist = Create Strings as file list: "filelist", "'textgrids_folder$'/'regexp$'"
ntextgrids = Get number of strings

# Write the results file header
#fileappend 'results_file$' 'textgrid_file'tab$'label'tab$'previousLabel'tab$'followingLabel'tab$'start'tab$'end'tab$'duration(s)'tab$'mean_f0(Hz)'tab$'f0_point1(Hz)'tab$'f0_point2(Hz)'tab$'f0_point3(Hz)'newline$'
writeFile: results_file$, "nom_textgrid_file", tab$, "label", tab$, "start_time", tab$,"end_time", tab$, "duration(s)"
if extract_left_and_right_context
	appendFile: results_file$, tab$, "previousLabel", tab$, "followingLabel"
endif
if extract_F0
	appendFile: results_file$, tab$, "mean_F0(Hz)" 
	if extract_min_max_and_standard_deviation
		appendFile: results_file$, tab$, "min_F0(Hz)", tab$, "max_F0(Hz)", tab$, "std_dev_F0(Hz)"
	endif
endif
if extract_HNR
	appendFile: results_file$, tab$, "mean_HNR(dB)"
	if extract_min_max_and_standard_deviation
		appendFile: results_file$, tab$, "min_HNR(dB)", tab$, "max_HNR(dB)", tab$, "std_dev_HNR(dB)"
	endif
endif
if extract_intensity
	appendFile: results_file$, tab$, "mean_intensity(dB)"
	if extract_min_max_and_standard_deviation
		appendFile: results_file$, tab$, "min_intensity()", tab$, "max_intensity()", tab$, "std_dev_intensity()"
	endif
endif
if extract_formants
		appendFile: results_file$, tab$, "mean_F1(Hz)"
		appendFile: results_file$, tab$, "mean_F2(Hz)" 
		appendFile: results_file$, tab$, "mean_F3(Hz)" 
		appendFile: results_file$, tab$, "mean_F4(Hz)" 
if extract_min_max_and_standard_deviation
		appendFile: results_file$, tab$, "min_F1(Hz)", tab$, "max_F1(Hz)", tab$, "std_dev_F1(Hz)"
		appendFile: results_file$, tab$, "min_F2(Hz)", tab$, "max_F2(Hz)", tab$, "std_dev_F2(Hz)"
		appendFile: results_file$, tab$, "min_F3(Hz)", tab$, "max_F3(Hz)", tab$, "std_dev_F3(Hz)"
		appendFile: results_file$, tab$, "min_F4(Hz)", tab$, "max_F4(Hz)", tab$, "std_dev_F4(Hz)"
	endif
endif

# The rest of the results file header will be written only when processing the first textgrid
header_written = 0
# Init ntiers to 0 before actual number of tiers is known
ntiers = 0

# fileappend "'results_file$'" 'newline$'

# Loop every selected textgrid
for itextgrid to ntextgrids
	# Get its name, display it in 'info' windows and read it
	selectObject: flist
	tg$ = Get string: itextgrid
	appendInfoLine: "Processing file ", tg$, "..."
	current_tg = Read from file: "'textgrids_folder$'/'tg$'"
	
	if header_written = 0
		# Finish writing results file header on the first loop increment
		selectObject: current_tg
		ntiers = Get number of tiers
		if secondary_tier>0
			# Get the name of the selected secondary tier
			selectObject: current_tg
			tiername$ = Get tier name: secondary_tier
			appendFile: results_file$, tab$, tiername$
			if extract_left_and_right_context
				appendFile: results_file$, tab$, "previous_'tiername$'", tab$, "next_'tiername$'"
			endif
		elsif secondary_tier = -1
			# Get the names of all interval tiers
			for itier from 1 to ntiers
				# Ignore it if it's the reference tier (already processed) or a point tier (no labels to extract)
				selectObject: current_tg
				interv_tier = Is interval tier: itier
				if itier<>reference_tier and interv_tier=1
					# Get tier name and write it to results file
					selectObject: current_tg
					tiername$ = Get tier name: itier
					appendFile: results_file$, tab$, tiername$
					if extract_left_and_right_context
						appendFile: results_file$, tab$, "previous_'tiername$'", tab$, "next_'tiername$'"
					endif
				endif
			endfor
		endif
		# Append a linebreak to results file to finish writing the header
		appendFile: results_file$, newline$
		header_written = 1
	endif

	# Read corresponding sound if acoustic parameters extraction is selected
	if extract_F0+extract_HNR+extract_intensity+extract_formants>0
		snd$ = tg$ - ".TextGrid" + ".wav"
		current_snd = Open long sound file: "'wavefiles_folder$'/'snd$'"
		current_snd_total_duration = Get total duration
	endif

	# Extract info from every non-empty interval
	selectObject: current_tg
	ninterv = Get number of intervals: reference_tier
	# Loop every interval on reference tier
	for iinterv from 1 to ninterv
		selectObject: current_tg
		label$ = Get label of interval: reference_tier, iinterv
		# Do something only if the interval label is not empty and matches the set of symbols to be processed (if defined)
		if length(label$)>0
			
				selectObject: current_tg
				#  Extract phonemic context
				if extract_left_and_right_context
					if iinterv>1
						previousLabel$ = Get label of interval: reference_tier, iinterv-1
					else
						previousLabel$ = "--undefined--"
					endif
					if iinterv<ninterv
						followingLabel$ = Get label of interval: reference_tier, iinterv+1
					else
						followingLabel$ = "--undefined--"
					endif
				endif
				# Extract start and end times, and calculate segment duration
				start_time = Get start point: reference_tier, iinterv
				end_time = Get end point: reference_tier, iinterv
				duration = end_time-start_time
				
				# Get the time of the 3 points for acoustic measurements extraction, the signal extract as a Sound object, and compute acoustic parameters
				if extract_F0+extract_HNR+extract_intensity+extract_formants>0

					
					# Get the start and end time of the signal extract (Sound object including offset before and after the target interval)
					extract_start_time = start_time - offset_for_acoustic_parameters_extraction_milliseconds/1000
					extract_end_time = end_time + offset_for_acoustic_parameters_extraction_milliseconds/1000
					# Check that the extract start and end times are not off limits
					if extract_start_time < 0
						extract_start_time = 0
					endif
					if extract_end_time > current_snd_total_duration
						extract_end_time = current_snd_total_duration
					endif
					selectObject: current_snd
					current_snd_extract = Extract part: extract_start_time, extract_end_time, "yes"
					
					# Get F0, intensity and formants values of the extract if needed
					if extract_F0
						selectObject: current_snd_extract
						current_pitch = To Pitch: 0.001, 50, 300
 
						mean_f0 = Get mean: start_time, end_time, "Hertz"
						if extract_min_max_and_standard_deviation
							min_f0 = Get minimum: start_time, end_time, "Hertz", "Parabolic"
							max_f0 = Get maximum: start_time, end_time, "Hertz", "Parabolic"
							std_f0 = Get standard deviation: start_time, end_time, "Hertz"
						endif
						removeObject: current_pitch
					endif

					if extract_HNR
						selectObject: current_snd_extract
						current_HNR = To Harmonicity (cc)... 0.01 75 0.1 1
 

						mean_HNR = Get mean: start_time, end_time
						if extract_min_max_and_standard_deviation
							min_HNR = Get minimum: start_time, end_time,  "Parabolic"
							max_HNR = Get maximum: start_time, end_time,  "Parabolic"
							std_HNR = Get standard deviation: start_time, end_time 
						endif
						removeObject: current_HNR
					endif

					if extract_intensity
						selectObject: current_snd_extract
						current_intensity = To Intensity: 100, 0.001, "yes"
                      
						mean_intensity = Get mean: start_time, end_time, "dB"
						if extract_min_max_and_standard_deviation
							min_intensity = Get minimum: start_time, end_time, "Parabolic"
							max_intensity = Get maximum: start_time, end_time, "Parabolic"
							std_intensity = Get standard deviation: start_time, end_time
						endif
						removeObject: current_intensity
					endif
					if extract_formants
					selectObject: current_snd_extract
					if (speakers_gender$ = "M")
					current_formant = To Formant (burg): 0, 5, 5000, 0.025, 50
					else
					current_formant = To Formant (burg): 0, 5, 5500, 0.025, 50
					endif
					mean_f1 =  Get value at time... 1 end_time Hertz Linear
					appendFile: results_file$, tab$, mean_f1
						if extract_min_max_and_standard_deviation
							min_f1 = Get minimum: 1, start_time, end_time, "Hertz", "Parabolic"
							max_f1 = Get maximum: 1, start_time, end_time, "Hertz", "Parabolic"
							std_f1 = Get standard deviation: 1, start_time, end_time, "Hertz"
						endif

					mean_f2 = Get value at time... 2 end_time Hertz Linear
					appendFile: results_file$, tab$, mean_f2
			
						if extract_min_max_and_standard_deviation
							min_f2 = Get minimum: 2, start_time, end_time, "Hertz", "Parabolic"
							max_f2 = Get maximum: 2, start_time, end_time, "Hertz", "Parabolic"
							std_f2 = Get standard deviation: 2, start_time, end_time, "Hertz"
						endif								
					mean_f3 = Get value at time... 3 end_time Hertz Linear
					appendFile: results_file$, tab$, mean_f3
						if extract_min_max_and_standard_deviation
							min_f3 = Get minimum: 3, start_time, end_time, "Hertz", "Parabolic"
							max_f3 = Get maximum: 3, start_time, end_time, "Hertz", "Parabolic"
							std_f3 = Get standard deviation: 3, start_time, end_time, "Hertz"
						endif
						
					mean_f4 = Get value at time... 4 end_time Hertz Linear
					appendFile: results_file$, tab$, mean_f4

 
						if extract_min_max_and_standard_deviation
							min_f4 = Get minimum: 4, start_time, end_time, "Hertz", "Parabolic"
							max_f4 = Get maximum: 4, start_time, end_time, "Hertz", "Parabolic"
							std_f4 = Get standard deviation: 4, start_time, end_time, "Hertz"
						endif
					endif
			
	
					removeObject: current_formant
					removeObject: current_snd_extract
				endif
				
				# Write information to results file
				appendFile: results_file$, tg$, tab$, label$, tab$, start_time, tab$, end_time, tab$, duration
				if extract_left_and_right_context
					appendFile: results_file$, tab$, previousLabel$, tab$, followingLabel$
				endif
				if extract_F0
					appendFile: results_file$, tab$, mean_f0
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_f0, tab$, max_f0, tab$, std_f0
					endif
				endif

				if extract_HNR
					appendFile: results_file$, tab$, mean_HNR
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_HNR, tab$, max_HNR, tab$, std_HNR
					endif
				endif

				if extract_intensity
					appendFile: results_file$, tab$, mean_intensity
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_intensity, tab$, max_intensity, tab$, std_intensity
					endif
				endif

				if extract_formants
					appendFile: results_file$, tab$, mean_f1 
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_f1, tab$, max_f1, tab$, std_f1
					endif
					appendFile: results_file$, tab$, mean_f2 
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_f2, tab$, max_f2, tab$, std_f2
					endif
					appendFile: results_file$, tab$, mean_f3 
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_f3, tab$, max_f3, tab$, std_f3
					endif
					appendFile: results_file$, tab$, mean_f4 
					if extract_min_max_and_standard_deviation
						appendFile: results_file$, tab$, min_f4, tab$, max_f4, tab$, std_f4
					endif
				endif				


				
				# Extract labels from other tiers and append information to the results file
				# Get interval midpoint (used as reference to extract information from other tiers)
				mid_point = start_time + duration/2
				if secondary_tier>0
					# Get the corresponding label on the selected secondary tier
					selectObject: current_tg
					intervtmp = Get interval at time: itier, mid_point
					secondaryTierlabel$ = Get label of interval: itier, intervtmp
					appendFile: results_file$, tab$, secondaryTierlabel$
					if extract_left_and_right_context
						if intervtmp-1 > 0
							previousLabelSecondaryTier$ = Get label of interval: itier, intervtmp-1
						else
							previousLabelSecondaryTier$ = "--undefined--"
						endif
						nIntervalsSecondaryTier = Get number of intervals: itier
						if intervtmp+1 <= nIntervalsSecondaryTier
							followingLabelSecondaryTier$ = Get label of interval: itier, intervtmp+1
						else
							followingLabelSecondaryTier$ = "--undefined--"
						endif
						appendFile: results_file$, tab$, previousLabelSecondaryTier$, tab$, followingLabelSecondaryTier$
					endif
				elsif secondary_tier = -1
					# Get the corresponding labels on all interval tiers
					# Loop every tier
					for itier from 1 to ntiers
						# Ignore it if it's the reference tier (already processed) or a point tier (no labels to extract)
						selectObject: current_tg
						interv_tier = Is interval tier: itier
						if itier<>reference_tier and interv_tier=1
							selectObject: current_tg
							# Get label at reference tier's current interval midpoint and append it to results file
							intervtmp = Get interval at time: itier, mid_point
							secondaryTierlabel$ = Get label of interval: itier, intervtmp
							appendFile: results_file$, tab$, secondaryTierlabel$
							if extract_left_and_right_context
								if intervtmp-1 > 0
									previousLabelSecondaryTier$ = Get label of interval: itier, intervtmp-1
								else
									previousLabelSecondaryTier$ = "--undefined--"
								endif
								nIntervalsSecondaryTier = Get number of intervals: itier
								if intervtmp+1 <= nIntervalsSecondaryTier
									followingLabelSecondaryTier$ = Get label of interval: itier, intervtmp+1
								else
									followingLabelSecondaryTier$ = "--undefined--"
								endif
								appendFile: results_file$, tab$, previousLabelSecondaryTier$, tab$, followingLabelSecondaryTier$
							endif
						endif
					endfor
				endif
				
				# Append a line break to the results file before proceeding to the next interval
				appendFile: results_file$, newline$
			endif
		endif
	endfor
	# Clean-up: remove current textgrid, pitch, intensity, formant and sound objects
	removeObject: current_tg
	if extract_F0+extract_HNR+extract_intensity+extract_formants>0
		removeObject: current_snd
	endif
endfor

appendInfoLine: newline$, "Processed ", ntextgrids, " files."

# Clean-up: remove lists of textgrids and vowels
removeObject: flist
 


