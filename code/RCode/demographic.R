setwd("Z:/Research/MIMIC/code/RCode")
#install.packages("fastDummies")


admission = read.csv(file = "../../data/Raw/ADMISSIONS.csv", stringsAsFactors = FALSE)
ICUStay = read.csv(file= "../../data/Raw/ICUSTAYS.csv",stringsAsFactors = FALSE)
patient = read.csv(file="../../data/Raw/PATIENTS.csv", stringsAsFactors = FALSE)

ICUtoHADM = ICUStay[,c('ICUSTAY_ID',"HADM_ID")]
write.csv(ICUtoHADM, file = "../../data/Processed/ICUToHAMDDict.csv", row.names = F)

dataV1 = data.frame("ICU ID" = ICUStay$icustay_id)
dataV1$los = ICUStay$los
dataV1$patientID = ICUStay$subject_id
dataV1$admissionID = ICUStay$hadm_id
ICUStay = ICUStay[order(ICUStay$subject_id,ICUStay$intime),]
#gender



for(i in 1:99999)
{
  dataV1$gender[dataV1$patientID==i] = patient$gender[patient$subject_id==i]
}
#age

lengthOfLoop = dim(patient)[1]

for(i in 1:lengthOfLoop)
{
  dob = patient$dob[patient$subject_id==dataV1$patientID[i]]
  dobYear = as.integer(strsplit(dob,"-")[[1]][1])
  doa = admission$admittime[admission$hadm_id==dataV1$admissionID[i]]
  doaYear = as.integer(strsplit(doa,"-")[[1]][1])
  ageA = doaYear-dobYear
  dataV1$AgeAdm[i] = ageA
}
#insurance information
for(i in 1:lengthOfLoop)
{
  insurance = admission$insurance[admission$hadm_id==dataV1$admissionID[i]]
  dataV1$insurance[i] = insurance
  if(i%%1000 == 0)
    print(i)
}
#ethnicity
for(i in 1:lengthOfLoop)
{
  race = admission$ethnicity[admission$hadm_id==dataV1$admissionID[i]]
  dataV1$ethnicity[i] = race
  if(i%%1000 == 0)
    print(i)  
}
#marital status
for(i in 1:lengthOfLoop)
{
  marital = admission$marital_status[admission$hadm_id==dataV1$admissionID[i]]
  dataV1$maritalStatus[i] = marital
  if(i%%1000 == 0)
    print(i)  
}

for(i in 1:lengthOfLoop)
{
  ICUID = dataV1$ICU.ID[i]
  subjectID = ICUStay$subject_id[ICUStay$icustay_id==ICUID]
  DOD = patient$dod[patient$subject_id==subjectID]
  discharge = ICUStay$outtime[ICUStay$icustay_id==ICUID]
  if(!is.null(DOD))
  {
    if(DOD <= discharge){
      mort = TRUE
    }
    else
      mort = FALSE
  }else
    mort = FALSE
  
  dataV1$mortality[i] = mort
  if(i%%1000 == 0)
    print(i)  
}

dataV1$admissionType = ""

for(i in 1:dim(dataV1)[1])
{
  dataV1$admissionType[i] = admission$admission_type[admission$hadm_id==dataV1$admissionID[i]]
}


---------------------------------------------------------------------------------------------------------------------------------------------------
#ICU visit time within same hospitalization
dataV1$ICUSeqWithSameHopsitalAdmission = 0
seqCounter = NA
lastID = ""
ICUStay = ICUStay[order(ICUStay$hadm_id,ICUStay$intime),]
for(i in 1:dim(ICUStay)[1])
{
  currentAID = ICUStay$hadm_id[i]
  currentICUID = ICUStay$icustay_id[i]
  if(currentAID != lastID)
  {
    seqCounter = 0
    dataV1$ICUSeqWithSameHopsitalAdmission[dataV1$ICU.ID==currentICUID] = 1
    lastID = currentAID
  }
  else
  {
    seqCounter = seqCounter + 1
    dataV1$ICUSeqWithSameHopsitalAdmission[dataV1$ICU.ID==currentICUID] = 1 + seqCounter
  }
  if(i%%100 == 0)
    print(i)
}

#Hospital Admission count
dataV1$AdmissionSeq = 0
admission = admission[order(admission$subject_id,admission$admittime),]
lastPID = ""
seqCounter = 0
for(i in 1:dim(admission)[1]){
  currentPID = admission$subject_id[i]
  currentAID = admission$hadm_id[i]
  if(currentPID != lastPID){
    seqCounter = 0
    dataV1$AdmissionSeq[dataV1$admissionID==currentAID] = 1
    lastPID = currentPID
  }
  else{
    seqCounter = seqCounter + 1
    dataV1$AdmissionSeq[dataV1$admissionID==currentAID] = seqCounter + 1
    
  }
  if(i%%100 == 0)
    print(i)
}
dataV1$firstICU = ""
dataV1$lastICU = ""
for(i in 1:dim(dataV1)[1])
{
  dataV1$firstICU[i] = ICUStay$first_careunit[ICUStay$icustay_id==dataV1$ICU.ID[i]]
  dataV1$lastICU[i] = ICUStay$last_careunit[ICUStay$icustay_id==dataV1$ICU.ID[i]]
}

firstfirst = dataV1$ICUSeqWithSameHopsitalAdmission==1 & dataV1$AdmissionSeq==1
shortICUStay = ICUStay[,c('icustay_id','intime','los')]
firstfirst = dataV1$ICU.ID[firstfirst]
ShortICUStayV2 = shortICUStay[shortICUStay$icustay_id %in% firstfirst,]
ShortICUStayV3 = ShortICUStayV2[ShortICUStayV2$los >= 2,]
write.table(as.data.frame(ShortICUStayV3),file = "../../data/Processed/FirstFirstVFinal.csv",quote=F,sep = ",",row.names = F)


dataV1 = dataV1[dataV1$ICUSeqWithSameHopsitalAdmission==1,]
dataV1 = dataV1[dataV1$AdmissionSeq==1,]
dataV1_1 = fastDummies::dummy_cols(dataV1)
dataV1_2 = dataV1_1[dataV1_1$los>2,]

output1 = subset(dataV1_2, select = c(ICU.ID,los))
output2 = subset(dataV1_2, select = c(ICU.ID,mortality))

input = subset(dataV1_2,select = -c(ICUSeqWithSameHopsitalAdmission,AdmissionSeq,mortality,los,patientID,admissionID,gender,insurance,ethnicity,maritalStatus,firstICU,lastICU,admissionType))

write.csv(input,file = "../../data/Processed/demoInput.csv")
write.csv(output1,file = "../../data/Processed/los.csv")
write.csv(output2,file = "../../data/Processed/mortality.csv")