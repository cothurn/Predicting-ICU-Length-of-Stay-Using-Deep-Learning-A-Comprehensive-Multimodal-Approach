#setwd("Z:/Research/MIMIC/code/RCode")
library("chron")

prescription = read.csv(file = "../../data/Raw/PRESCRIPTIONS.csv", stringsAsFactors = FALSE)
icuData = read.csv(file= "../../data/Raw/ICUSTAYS.csv",stringsAsFactors = FALSE)

ICUPrescription = prescription[!is.na(prescription$icustay_id),]
remove(prescription)
noZeroICUPrescription = ICUPrescription[ICUPrescription$ndc!=0,]
noZeroICUPrescription = noZeroICUPrescription[!is.na(noZeroICUPrescription$row_id),]
zeroICUPrescription = ICUPrescription[ICUPrescription$ndc==0,]
#uniqueZeroDrugName = unique(zeroICUPrescription$drug)

uniqueNDC = data.frame("NDC" = unique(ICUPrescription$ndc))
noZero = ICUPrescription[ICUPrescription$ndc!=0,]
uniqueNDC = data.frame("NDC" = unique(noZero$ndc))

uniqueNDC = data.frame("NDC" = uniqueNDC[!is.na(uniqueNDC$NDC),])
count = dim(uniqueNDC)[1]
for(i in 1:count)
{
  output = ""
  length = nchar(as.character(uniqueNDC$NDC[i]))
  if(length < 11) {
    for(j in length:10){
      output = paste(output,"0",sep = "")
    }
  }
  output = paste(output,uniqueNDC$NDC[i],sep = "")
  uniqueNDC$ElevenDigit[i] = output
}

write.csv(uniqueNDC,file = "../../data/Processed/prescription_11digitNDC.csv")


simplifiedNoZeroICUPrescription = subset(noZeroICUPrescription,select = -c(row_id,subject_id,hadm_id,drug_type,drug,drug_name_poe,
                                                                           drug_name_generic,formulary_drug_cd,gsn,prod_strength,
                                                                           form_val_disp,form_unit_disp,route))
simplifiedNoZeroICUPrescription = simplifiedNoZeroICUPrescription[!is.na(simplifiedNoZeroICUPrescription$icustay_id),]
simplifiedNoZeroICUPrescription$dose_val_rx=gsub(",", "", simplifiedNoZeroICUPrescription$dose_val_rx,fixed = T)

options(warn=1)
tempVector = simplifiedNoZeroICUPrescription$dose_val_rx
vecLength = length(tempVector)
tempOutput = c(rep(0,vecLength))
for (i in 1:vecLength){
  tempVal = strsplit(tempVector[i],"-")[[1]]
  if(length(tempVal)==1)
    tempOutput[i] = as.numeric(tempVal[1])
  else if(length(tempVal)==2)
    tempOutput[i] = (as.double(tempVal[1]) + as.numeric(tempVal[2]))/2
  else{
    tempOutput[i] = NA
  }
  if(i %% 100000 == 0)
    print(i)
}
simplifiedNoZeroICUPrescription$dose_val_rx = tempOutput
simplifiedNoZeroICUPrescription = simplifiedNoZeroICUPrescription[!is.na(simplifiedNoZeroICUPrescription$dose_val_rx),]
simplifiedNoZeroICUPrescription = simplifiedNoZeroICUPrescription[simplifiedNoZeroICUPrescription$dose_val_rx!=0,]

normalizedSimplifiedNoZeroICUPrescription = data.frame(simplifiedNoZeroICUPrescription)
normalizedSimplifiedNoZeroICUPrescription = normalizedSimplifiedNoZeroICUPrescription[order(normalizedSimplifiedNoZeroICUPrescription$ndc),]
uniqueNDCValues = unique(normalizedSimplifiedNoZeroICUPrescription$ndc)
varCheckVector = c(rep(0,dim(normalizedSimplifiedNoZeroICUPrescription)[1]))
count = 1
for(i in uniqueNDCValues){
  k = simplifiedNoZeroICUPrescription[simplifiedNoZeroICUPrescription$ndc==i,]
  varCheck = (k$dose_val_rx-mean(k$dose_val_rx))/sd(k$dose_val_rx)
  for(j in 1:length(varCheck))
  {
    varCheckVector[count] = varCheck[j]
    count = count + 1
  }
  print(count)
}
varCheckVector[is.nan(varCheckVector)] = 0
varCheckVector[is.na(varCheckVector)] = 0
noOutlierNormalizedSimplifiedNoZeroICUPrescription = normalizedSimplifiedNoZeroICUPrescription[abs(varCheckVector)<5,]
noOutlierNormalizedSimplifiedNoZeroICUPrescription = noOutlierNormalizedSimplifiedNoZeroICUPrescription[!is.na(noOutlierNormalizedSimplifiedNoZeroICUPrescription$dose_val_rx),]


ICUentryTime = data.frame("icustay_id" = icuData$icustay_id,"entryTime" = icuData$intime,stringsAsFactors = F)
dtparts = strsplit(ICUentryTime$entryTime," ")
tempList = vector(mode = 'list',length = length(dtparts))
for (j in 1:length(dtparts)){
  i = dtparts[[j]]
  tempList[[j]] = chron(dates = i[1],times = i[2],format=c('y-m-d','h:m:s'))
}

ICUentryTime$Chron=tempList


noOutlierNormalizedSimplifiedNoZeroICUPrescription$startSplit = strsplit(noOutlierNormalizedSimplifiedNoZeroICUPrescription$startdate," ")
noOutlierNormalizedSimplifiedNoZeroICUPrescription$endSplit = strsplit(noOutlierNormalizedSimplifiedNoZeroICUPrescription$enddate," ")
noOutlierNormalizedSimplifiedNoZeroICUPrescription$firstDay = F
noOutlierNormalizedSimplifiedNoZeroICUPrescription$secondDay = F
size = dim(noOutlierNormalizedSimplifiedNoZeroICUPrescription)[1]

for (i in 1:size) {
  entryTime = ICUentryTime$Chron[ICUentryTime$icustay_id==noOutlierNormalizedSimplifiedNoZeroICUPrescription$icustay_id[i]][[1]]
  startTime = chron(dates = noOutlierNormalizedSimplifiedNoZeroICUPrescription$startSplit[i][[1]][1],
                    times = noOutlierNormalizedSimplifiedNoZeroICUPrescription$startSplit[i][[1]][2],
                    format=c('y-m-d','h:m:s'))
  endTime = chron(dates = noOutlierNormalizedSimplifiedNoZeroICUPrescription$endSplit[i][[1]][1],
                  times = noOutlierNormalizedSimplifiedNoZeroICUPrescription$endSplit[i][[1]][2],
                  format=c('y-m-d','h:m:s'))
  #print(startTime)
  if(startTime-entryTime < 1){
    noOutlierNormalizedSimplifiedNoZeroICUPrescription$firstDay[i] = T
    if(endTime-entryTime > 1)
      noOutlierNormalizedSimplifiedNoZeroICUPrescription$secondDay[i] = T
    else
      noOutlierNormalizedSimplifiedNoZeroICUPrescription$secondDay[i] = F
  }else if(startTime-entryTime < 2){
    noOutlierNormalizedSimplifiedNoZeroICUPrescription$firstDay[i] = F
    noOutlierNormalizedSimplifiedNoZeroICUPrescription$secondDay[i] = T 
  }else{
    noOutlierNormalizedSimplifiedNoZeroICUPrescription$firstDay[i] = F
    noOutlierNormalizedSimplifiedNoZeroICUPrescription$secondDay[i] = F
  }
}

outputPresciptionValue = subset(noOutlierNormalizedSimplifiedNoZeroICUPrescription,select = -c(startSplit,endSplit,firstDay,secondDay))
outputICUTime = subset(ICUentryTime,select =-c(Chron))
outputICUTime = outputICUTime[order(outputICUTime$icustay_id),]

write.csv(outputPresciptionValue,file = "../../data/Processed/prescription_CleanedPresciption.csv")
write.csv(outputICUTime,file = "../../data/Processed/prescription_ICUTime.csv",row.names = F)