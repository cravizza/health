"""
Create cleaned datasets of health claims
"""
from __future__ import division # to use division (instead of integer division) in python 2
import os
import pandas as pd 
import matplotlib.pyplot as plt
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_seasonality.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/seasonality.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    start0 = time.time()
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1
    del df2
    del df3
    print('\n-- Time elapsed load and concat: ' + str(int(time.time() - start0)) + ' sec.\n')

    # Drop to use in Stata
    dfp.drop(columns=['proid'], inplace=True) 
    
    # Plot
    dfp_plot = dfp.loc[dfp['gender']!= 'unborn',['month','isapre']].groupby(['month'], as_index=False)['isapre'].count()
    dfp_plot.sort_values(by=['month'],inplace=True)
    dfp_plot['month'] = dfp_plot['month'].astype('category')
    dfp_plot.set_index('month',drop=True,inplace=True)
    dfp_plot.plot(legend=False)
    plt.savefig('../output/pb_month.pdf')

    # Aggregate data and subsamples agg_demo_groups() hiv_sample()
    dfp_month = dfp.groupby(['month','gender','code2'], as_index=False)['isapre'].count()
    dfp_month.isapre.fillna(0,inplace=True)
    dfp_month.to_stata('../output/pb_groupby_month.dta')
    
    dfp_date = dfp.groupby(['date','gender'], as_index=False)['isapre'].count()
    dfp_date.isapre.fillna(0,inplace=True)
    dfp_date.to_stata('../output/pb_groupby_date.dta')
    
    # END
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout
    
    dfp.info()

if __name__ == '__main__':
    main()
