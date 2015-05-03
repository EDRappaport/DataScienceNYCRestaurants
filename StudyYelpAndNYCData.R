# Process MergedYelpAndNYCData
installed.packages('ggplot2')
library(ggplot2)
library(lattice)

dataFile <- 'MergedYelpAndNYCData'

if (!file.exists(dataFile))
{
  stop('Must have MergedYelpAndNYCData file in current directory.
       Consider something like setwd(\'~/Documents/.../DataScience/FinalProject/\'')
  stopifnot(file.exists(dataFile))
}

data <- read.csv(dataFile, header = TRUE, sep = "|", quote = "")
data <- subset(data, !is.na(location.postal_code))
data <- subset(data, !is.na(PHONE))
data <- subset(data, !is.na(phone))

data$SCORE <- as.numeric(as.character(data$SCORE))
data$review_count <- as.numeric(as.character(data$review_count))
data$rating <- as.numeric(as.character(data$rating))
data$HasViolation <- ifelse(grepl('None', data$VIOLATION_CODE),0,1)

# Confirm data properties that we expect
if (any((data['PHONE'] == substr(data[,'phone'],2,11)) == FALSE))
{
  warning('There is at least 1 row where the phone number from NYC data is not the same as from the YELP data.  This breaks our assumption of the collected data.')
}
if (any((data['ZIPCODE'] == data['location.postal_code']) == FALSE))
{
  warning('There is at least 1 row where the zipcode from NYC data is not the same as from the YELP data.  This breaks our assumption of the collected data.')
}
data <- transform(data, VIOLATION_COUNT = ave(HasViolation, CAMIS, FUN = sum))


dataWithoutNoneScoresAndGrades <- subset(
  subset(data, !grepl('None', SCORE)), !grepl('None', GRADE))

aggregatedData <- transform(
  subset(dataWithoutNoneScoresAndGrades, !grepl('None', GRADE_DATE)),
  MeanScore = ave(SCORE, CAMIS, FUN = mean),
  MinScore = ave(SCORE, CAMIS, FUN = min),
  MaxScore = ave(SCORE, CAMIS, FUN = max),
  StdScore = ave(SCORE, CAMIS, FUN = sd))

groupedData <- aggregate(SCORE ~ CAMIS+DBA+BORO+rating+review_count+VIOLATION_COUNT+MeanScore+MaxScore+MinScore+StdScore,
                         aggregatedData, FUN=mean)

ggplot(data = dataWithoutNoneScoresAndGrades, aes(x=SCORE)) + geom_histogram()
ggplot(data = groupedData, aes(x=rating)) + geom_histogram()
ggplot(data = dataWithoutNoneScoresAndGrades, aes(x=review_count)) + geom_histogram()

ggplot(data=dataWithoutNoneScoresAndGrades,aes(x=as.factor(GRADE),y=SCORE)) +  geom_point()
ggplot(data=subset(dataWithoutNoneScoresAndGrades, grepl('BROOKLYN',BORO)),aes(x=rating,y=SCORE)) +  geom_point()
ggplot(data=subset(dataWithoutNoneScoresAndGrades, grepl('BROOKLYN',BORO)),aes(x=review_count,y=SCORE)) +  geom_point()

ggplot(data=groupedData,aes(x=rating,y=SCORE)) +  geom_point()

attach(groupedData)
xyplot(review_count~MeanScore, xlab="Mean Health Rating Score (lower is better)",
       ylab="Number of Reviews", main="Number of Review on Yelp vs. NYC Health Score")
xyplot(rating~MeanScore, xlab="Mean Health Rating Score (lower is better)",
       ylab="Average Yelp Rating", main="Average Yelp Review Rating vs. NYC Health Score")
xyplot(VIOLATION_COUNT~rating, xlab="Average Yelp Rating",
       ylab="Number of Violations Cited in NYC Health Data",
       main="Number of Violations vs. Yelp Rating")
cloud(MeanScore~rating*as.factor(BORO), main="Mean Health Rating Score vs. Yelp Rating By Boro")
dotplot(~MeanScore|as.factor(BORO))
dotplot(~rating|as.factor(BORO))
histogram(MeanScore, breaks = seq(-2.5,65,2.5),
          type="count", xlab="Mean Health Rating Score (lower is better)",
          main="Histogram of the MeanScore")
xyplot(subset(groupedData, review_count > 25)$review_count~MeanScore,
       xlab="Mean Health Rating Score (lower is better)",
       ylab="Number of Yelp Reviews > 25 reviews",
       main="For Businesses with more than 25 Reviews: Number of Reviews vs Health Score")
detach(groupedData)