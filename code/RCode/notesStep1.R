setwd("Z:/Research/MIMIC/code/RCode")
library('chron')

notes = read.csv(file = "../../data/Raw/NOTEEVENTS.csv", stringsAsFactors = FALSE)
ICUData = read.csv(file = "../../data/Raw/ICUSTAYS.csv", stringsAsFactors = FALSE)

newICUData = ICUData[with(ICUData,order(subject_id,outtime)),]
newICUData$Count = 0
for (i in 2:length(ICUData$row_id)){
  if (newICUData$subject_id[i] == newICUData$subject_id[i-1]){
    
    newICUData$Count[i] = 1
  }
}
newICUData = newICUData[newICUData$Count==0,]
tempData = data.frame("SubjectID" = newICUData$subject_id,"inTime" = newICUData$intime,stringsAsFactors = FALSE)
inTimeSplit = strsplit(tempData$inTime," ")

for (i in (1:length(tempData$inTime))){
  tempData$ChronCutoff[i] = chron(inTimeSplit[i][[1]][1],inTimeSplit[i][[1]][2], format=c('y-m-d','h:m:s')) + 2
}

tempDataV2 = data.frame("SubjectID" = tempData$SubjectID,"cutOff" = tempData$ChronCutoff ,stringsAsFactors = FALSE)
remove(tempData)
NotesWithTime = notes[notes$charttime!="",]
NotesWOTime = notes[notes$charttime=="",]

dfForLoop = subset(NotesWithTime, select = c(subject_id,charttime))
dfForLoop$INC = FALSE
notesTimeSplit = strsplit(paste(dfForLoop$charttime, "00", sep = ":")," ")

for (i in 1:length(dfForLoop$subject_id)){
  timeToConsider = chron(notesTimeSplit[i][[1]][1],notesTimeSplit[i][[1]][2], format=c('m/d/y','h:m:s'))
  subjectID = dfForLoop$subject_id[i]
  correspondingCutoff = tempDataV2$cutOff[tempDataV2$SubjectID==subjectID]
  diff = correspondingCutoff-timeToConsider
  if(length(diff) > 0){
    if (diff <= 2 & diff >= 0)
      dfForLoop$INC[i] = TRUE
  }
  if(i %% 100000 == 0)
    cat("..",i)
}


applicableEntryV1 = subset(dfForLoop[dfForLoop$INC,], select = c(subject_id,charttime))
applicableEntryV1$MoreThan48 = F
for (i in 1:length(applicableEntryV1$subject_id)){
  id = applicableEntryV1$subject_id[i]
  los = newICUData$los[newICUData$subject_id==id]
  if(!is.na(los) &los >= 2){
    applicableEntryV1$MoreThan48[i] = T
  }
  if(i %% 100000 == 0)
    cat("..",i)
}

applicableEntryV2 = applicableEntryV1[applicableEntryV1$MoreThan48==TRUE,]
subjectEntryCount = table(applicableEntryV2$subject_id)
remove(applicableEntryV1)
applicableRowNames = rownames((applicableEntryV2))

tempData = notes[applicableRowNames,]
notesV2 = subset(tempData, select = c(subject_id,charttime,category,description,text))

notesV2$ICUID = 0
for (i in 1:length(notesV2$subject_id)){
  subjectID = notesV2$subject_id[i]
  icuID = newICUData$subject_id[newICUData$subject_id==subjectID]
  if(length(icuID==1))
    notesV2$ICUID[i] = icuID
  if(i %% 20000 == 0)
    cat("..",i)
}

notesV3 = notesV2[c(6,1,2,3,4,5)]
notesV3 = subset(notesV3, select = c(1,3,4,5,6))

orderedNotes = notesV3[with(notesV3,order(ICUID,charttime)),]
tempVal = fastDummies::dummy_cols(notesV3$category)
tempVal = subset(tempVal,select = -c(.data))

previousID = 0
seqCount = 0
timeCount = 0


notesTimeSplit = strsplit(paste(orderedNotes$charttime, "00", sep = ":")," ")
seqAndTime = data.frame("SeqNum" = rep(0, length(orderedNotes$ICUID)), "TimeSinceLastNote" = rep(0, length(orderedNotes$ICUID)))

for (i in 1:length(orderedNotes$ICUID)){
  id = orderedNotes$ICUID[i]
  timeChron = chron(notesTimeSplit[i][[1]][1],notesTimeSplit[i][[1]][2], format=c('m/d/y','h:m:s'))
  newID = (id != previousID)
  if(newID)
  {
    seqCount = 1
    timeCount = timeChron
    previousID = id
  }else
  {
    seqCount = seqCount + 1
  }
  seqAndTime$SeqNum[i] = seqCount
  seqAndTime$TimeSinceLastNote[i] = timeChron-timeCount
  timeCount = timeChron
  if(i %% 10000 ==0)
    cat("..",i)
}

finalOutput = cbind(orderedNotes$ICUID,seqAndTime,tempVal,orderedNotes$text)
colnames(finalOutput) = c("ICUID","SeqNum","TimeSinceLastNote","Case Management ","Consult","General","Nursing","Nursing/other","Nutrition","Pharmacy","Physician ","Radiology","Rehab Services","Respiratory ","Social Work","TEXT")

write.csv(finalOutput,file = "../../data/Processed/notes_finalNotesForProcess.csv",row.names = F)