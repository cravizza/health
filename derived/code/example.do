set more off
preliminaries

sysuse auto, clear
di "Hello!"

summarize price, detail
ttest mpg, by(foreign)
