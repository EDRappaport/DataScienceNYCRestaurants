# Process MergedYelpAndNYCData

if (!file.exists('MergedYelpAndNYCData'))
{
  print('Must have MergedYelpAndNYCData file in current directory.')
  print('Consider something like setwd(\'~/Documents/.../DataScience/FinalProject/\')')
  stopifnot(file.exists('MergedYelpAndNYCData'))
}