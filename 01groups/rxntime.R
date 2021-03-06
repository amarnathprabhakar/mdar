# This is a comment.
# R will ignore anything after the # sign.

# Load the mosaic library
library(mosaic)

# Now we read in the data (in tab-delimited .txt format)
# Use RStudio's "Import Dataset" command or use read.table() 
# rxntime = read.table("rxntime.txt", header=TRUE, sep="\t")


###################################
# Simple group-wise models
# Residuals and fitted values
###################################

summary(rxntime)

# The $ sign is the variable-access operator
# Access variables using dataset$variable.
hist(rxntime$PictureTarget.RT)

# Some plots to show between-group and within-group variation
boxplot(PictureTarget.RT ~ FarAway, data=rxntime)
boxplot(PictureTarget.RT ~ Littered, data=rxntime)

# Fit a model using lm
# First by whether the scene was littered
lm1 = lm(PictureTarget.RT ~ Littered, data=rxntime)
coef(lm1)

# The model partitions variation into predictable and unpredictable pieces
resid(lm1)
fitted1 = cbind(rxntime$PictureTarget.RT, fitted(lm1), resid(lm1))
head(fitted1)
head(fitted1, 15)

###################################
# Dummy variables
###################################

# Compare the model coefficients with the group means
coef(lm1)

# Compute the group-wise means and standard deviations.
# If you haven't loaded the mosaic library,
# this will generate an error.
mean(PictureTarget.RT ~ Littered, data=rxntime)
506.71042 + 87.46354

# Can also compute other summary statistics
# stratified by group
sd(PictureTarget.RT ~ FarAway, data=rxntime)
median(PictureTarget.RT ~ FarAway, data=rxntime)
count( (PictureTarget.RT > 700) ~ FarAway, data=rxntime)


###################################
# Decomposition of variance
###################################

# The decomposition of variance
# Define a function to calculate the sum of squared deviations from the mean
sumsq = function(x) {
  return( sum((x - mean(x))^2) )
}
sumsq(rxntime$PictureTarget.RT)
sumsq(fitted(lm1))
sumsq(resid(lm1))
sumsq(fitted(lm1)) + sumsq(resid(lm1))

# Analysis of variance
anova(lm1)

# Calculate R^2 by hand
sumsq(fitted(lm1)) / sumsq(rxntime$PictureTarget.RT) 

# Can pick off R^2 directly from the summary command
summary(lm1)


###################################
# More than two levels of a factor
###################################

# Stratify by subject
# Notice the factor command
# This tells R that Subject is a label,
# not a number with a meaningful magnitude.
boxplot(PictureTarget.RT ~ factor(Subject), data=rxntime)

# Fit a model that accounts for subject-level variation
lm2 = lm(PictureTarget.RT ~ factor(Subject), data=rxntime)

# Results are expressed in "baseline/offset" form
coef(lm2)

# R^2
summary(lm2)


###################################
# More than one grouping factor
###################################

# Stratify means and sd by two categories
# Notice that the design is balanced: 480 in each group
mean(PictureTarget.RT ~ Littered + FarAway, data=rxntime)
sd(PictureTarget.RT ~ Littered+FarAway, data=rxntime)
tally( ~ Littered + FarAway, data=rxntime) # defined in mosaic


# Fit a model with main effects only, where
# the Littered and FarAway effects are separable.
lm3 = lm(PictureTarget.RT ~ Littered + FarAway, data=rxntime)
coef(lm3)



###################################
# Interaction terms
###################################

# An interaction would allow that the joint effect
# to be different than the sum of the parts
lm3int = lm(PictureTarget.RT ~ Littered + FarAway + Littered:FarAway, data=rxntime)
coef(lm3int)

# This is shorthand for the same model statement.
lm3int = lm(PictureTarget.RT ~ Littered*FarAway, data=rxntime)
coef(lm3int)

# The variance decomposition.
anova(lm3)
anova(lm3int)

# What if we flipped the order?
lm3b = lm(PictureTarget.RT ~ FarAway + Littered, data=rxntime)

# The coefficients are the same (always true).
# The variance decomposition is also the same.
# This will not always be true.
# Here it is a consequence of balanced design -- no collinearity.
coef(lm3); coef(lm3b)
anova(lm3); anova(lm3b)


###################################
# Model diagnostics
# Examine the residuals!
###################################

# Is the subject-specific effect left in the residuals from model 3?
lm3 = lm(PictureTarget.RT ~ Littered + FarAway, data=rxntime)
boxplot(resid(lm3) ~ factor(Subject), data=rxntime)

# Looks like we have not adequately accounted for subject-specific differences
# Fit a model with the interaction term and subject-specific dummy variables
lm4 = lm(PictureTarget.RT ~ Littered + FarAway + Littered:FarAway + factor(Subject), data=rxntime)
summary(lm4)


###################################
# Quantifying parameter uncertainty
###################################

# Estimate sampling distributions via bootstrapping

# Try this a few different times
# Different coefficients each time
# Creation myth: different (x,y) pairs come to us randomly from a population
lm(PictureTarget.RT ~ Littered, data=resample(rxntime))

# Now collect 1000 bootstrapped samples
# do(1000) is just a simple "for loop" with a return value
# R's basic for loops don't have return values
myboot = do(1000)*{
  lm(PictureTarget.RT ~ Littered, data=resample(rxntime))
}
head(myboot)

# Summarize the sampling distributions
hist(myboot$Littered)
boot_stderr = apply(myboot, 2, sd)[1:2]

# Compare with the normal-theory standard errors
# Pretty close!
lm1 = lm(PictureTarget.RT ~ Littered, data=rxntime)
summary(lm1)
boot_stderr


# A t-statistic is just a signal-to-noise ratio
tstat1 = coef(lm1)/boot_stderr
tstat1

# Notice that a two-sample t test
# is identical to summary()
# and close to the bootstrapped t stats
t.test(PictureTarget.RT ~ Littered, data=rxntime)

# Can also extract a confidence interval
confint(lm1, level=0.95)
confint(myboot, level=0.95)
cbind(coef(lm1) - 2*boot_stderr, coef(lm1) + 2*boot_stderr)


# Extract SE's and confidence intervals for the larger model
lm4 = lm(PictureTarget.RT ~ Littered + FarAway + Littered:FarAway + factor(Subject), data=rxntime)
summary(lm4)
confint(lm4, level=0.95)

# Now, by bootstrapping
myboot = do(1000)*{
  lm(PictureTarget.RT ~ Littered + FarAway + Littered:FarAway + factor(Subject), data=resample(rxntime))
}
confint(myboot, level=0.95)


