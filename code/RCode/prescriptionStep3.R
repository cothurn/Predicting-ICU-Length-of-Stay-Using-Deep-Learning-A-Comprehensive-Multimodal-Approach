library('factoextra')

ordered = read.csv("../../data/Processed/prescription_secondStep.csv", stringsAsFactors = FALSE)
firstDay = ordered[ordered$firstDay==T,]
secondDay = ordered[ordered$secondDay==T,]
firstDay = subset(firstDay, select = -c(ICUID,firstDay,secondDay))
secondDay = subset(secondDay, select = -c(ICUID, firstDay, secondDay))

firstDayPCA = prcomp(~.,data = firstDay)
#summary(firstDayPCA)
secondDayPCA = prcomp(~.,data = secondDay)
#summary(secondDayPCA)

firstDayReduced = as.data.frame(get_pca_ind(firstDayPCA)[1])[,1:7]
secondDayReduced = as.data.frame(get_pca_ind(secondDayPCA)[1])[,1:7]
#firstDay = ordered[ordered$firstDay==T,]
#secondDay = ordered[ordered$secondDay==T,]

firstDay = ordered[ordered$firstDay==T,]
secondDay = ordered[ordered$secondDay==T,]
firstDayReduced$ICUID = firstDay$ICUID
secondDayReduced$ICUID = secondDay$ICUID


write.csv(firstDayReduced,file = "../../data/Processed/firstDayPrescriptionReduced.csv",row.names = F)
write.csv(secondDayReduced,file = "../../data/Processed/secondDayPrescriptionReduced.csv",row.names = F)