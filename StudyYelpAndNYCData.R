# Process MergedYelpAndNYCData

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

# Confirm data properties that we expect
if (any((data['PHONE'] == substr(data[,'phone'],2,11)) == FALSE))
{
  warning('There is at least 1 row where the phone number from NYC data is not the same as from the YELP data.  This breaks our assumption of the collected data.')
}
if (any((data['ZIPCODE'] == data['location.postal_code']) == FALSE))
{
  warning('There is at least 1 row where the zipcode from NYC data is not the same as from the YELP data.  This breaks our assumption of the collected data.')
}

dataWithoutNoneScoresAndGrades <- subset(subset(data, !grepl('None', SCORE)), !grepl('None', GRADE))
ggplot(data = dataWithoutNoneScoresAndGrades, aes(x=SCORE)) + geom_histogram()
ggplot(data = dataWithoutNoneScoresAndGrades, aes(x=rating)) + geom_histogram()
ggplot(data = dataWithoutNoneScoresAndGrades, aes(x=review_count)) + geom_histogram()

ggplot(data=dataWithoutNoneScoresAndGrades,aes(x=as.factor(GRADE),y=SCORE)) +  geom_point()
ggplot(data=subset(dataWithoutNoneScoresAndGrades, grepl('11229',ZIPCODE)),aes(x=rating,y=SCORE)) +  geom_point()

library(lattice)
attach(dataWithoutNoneScoresAndGrades)
xyplot(review_count~SCORE)
xyplot(SCORE~rating)
cloud(SCORE~rating*as.factor(ZIPCODE))
dotplot(~SCORE|as.factor(ZIPCODE))
dotplot(~rating|as.factor(ZIPCODE))
cloud(SCORE~rating*as.factor(BORO))
dotplot(~SCORE|as.factor(BORO))
dotplot(~rating|as.factor(BORO))
detach(dataWithoutNoneScoresAndGrades)