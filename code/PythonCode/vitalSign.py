import gzip
import csv
import pandas as pd
import regex as re
import datetime
from progressbar import ProgressBar
import numpy as np

vitals = pd.read_table("../../data/Processed/vitalSign.csv",delimiter=",")
eligibleICUs = pd.read_table("../../data/Processed/FirstFirstVFinal.csv",delimiter=",")

IDVitals = vitals.dropna(subset = ['icustay_id'])
ICUList = eligibleICUs['icustay_id'].to_list()
eligibleICUs.set_index('icustay_id',inplace=True)
intimeDict = eligibleICUs['intime'].to_dict()

startID = 0
startDateTime = 0
timeList = []
skip = False
pbar = ProgressBar()
for i in pbar(range(0,IDVitals.shape[0])):
  currentID = IDVitals['icustay_id'][i]
  currentDateTime = datetime.datetime.strptime((IDVitals['charttime'][i]), "%Y-%m-%d %H:%M:%S")
  if currentID == startID:
    if skip:
      timeList.append(-1)
      continue
    timeList.append((currentDateTime - startDateTime).total_seconds())
  else:
    startID = currentID
    if startID not in ICUList:
      skip = True
      timeList.append(-1)
      continue
    startDateTime = currentDateTime
    ICUStartTime = datetime.datetime.strptime(intimeDict[startID], "%Y-%m-%d %H:%M:%S")
    diff = ICUStartTime - startDateTime
    if diff.total_seconds() < 0:
      timeList.append(0)
    else:
      timeList.append(diff.total_seconds())
    skip = False

IDVitals['TimeSinceFirstRecord'] = timeList
del IDVitals['charttime']
GlucoseOutlier = IDVitals[IDVitals['glucose'].gt(10000)].index
IDVitals.drop(axis = 0, index = GlucoseOutlier, inplace = True)
entriesToDelete = IDVitals['TimeSinceFirstRecord'] != -1
eligibleVitals = IDVitals.loc[entriesToDelete,:]
afterDataCollectionPeriod = eligibleVitals['TimeSinceFirstRecord'] < 172800
eligibleVitalsV2 = eligibleVitals.loc[afterDataCollectionPeriod,:]
eligibleVitalsV2.reset_index(inplace=True)
del eligibleVitalsV2['index']

lastEntryPos = eligibleVitalsV2.shape[0]

pbar = ProgressBar()
uniquePatientCount = len(eligibleVitalsV2['icustay_id'].unique())
matrixSize = uniquePatientCount
seriesList = []
entryCountList = []

startPointer = 0
endPointer = 0
for i in pbar(range(0,uniquePatientCount)):
  currentID = eligibleVitalsV2['icustay_id'][startPointer]

  for j in range(1,24):
    foundLastEntry = False
    while not foundLastEntry:
      if endPointer == lastEntryPos:
        break
      if eligibleVitalsV2['TimeSinceFirstRecord'][endPointer] > 7200 * j or eligibleVitalsV2['icustay_id'][endPointer] != currentID:
        foundLastEntry = True
      else:
        endPointer = endPointer + 1
    #print("For ID %6d, %d th 2 hour block starts at %d, end at %d" %(currentID,j,startPointer,endPointer))
    meanVal = eligibleVitalsV2[startPointer:endPointer].mean()
    if endPointer - startPointer == 0:
      meanVal['icustay_id'] = currentID
    seriesList.append(meanVal)
    entryCountList.append(endPointer-startPointer)
    startPointer = endPointer
    endPointer = endPointer
  foundLastEntryForCurrentID =False

  while not foundLastEntryForCurrentID:
    if endPointer == lastEntryPos:
      break
    if eligibleVitalsV2['icustay_id'][endPointer] == currentID:
      endPointer = endPointer + 1
    else:
      foundLastEntryForCurrentID = True

  meanVal = eligibleVitalsV2[startPointer:endPointer].mean()
  if endPointer - startPointer == 0:
    meanVal['icustay_id'] = currentID
  seriesList.append(meanVal)
  entryCountList.append(endPointer-startPointer)
  #print("For ID %6d, 24 th 2 hour block starts at %d, end at %d" %(currentID,startPointer,endPointer))
  startPointer = endPointer
  endPointer = endPointer

temp = pd.DataFrame(seriesList)
del temp['TimeSinceFirstRecord']
temp['bihourlyEntryCount'] = entryCountList

tempNegativeOne = temp.fillna(value = -1)
tempNegativeOne.to_csv(r'../../data/Processed/bihourlyNegativeOne.csv',index=False,header=True)