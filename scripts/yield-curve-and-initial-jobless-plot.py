import requests
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.dates import MonthLocator, DateFormatter

# Download the first CSV file (Yield Curve Data)
url1 = 'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1320&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=T10Y2Y&scale=left&cosd=2000-01-01&coed=2024-11-27&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=3&ost=-99999&oet=99999&mma=0&fml=a&fq=Daily&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2024-11-29&revision_date=2024-11-29&nd=1976-06-01'
response1 = requests.get(url1)
with open('yield_curve.csv', 'wb') as file1:
    file1.write(response1.content)

# Load and preprocess the first dataset
df1 = pd.read_csv('yield_curve.csv')
df1['DATE'] = pd.to_datetime(df1['DATE'])
df1['T10Y2Y'] = pd.to_numeric(df1['T10Y2Y'], errors='coerce')
df1 = df1.dropna(subset=['T10Y2Y']).sort_values(by='DATE')

df1.set_index('DATE', inplace=True)
df1_resampled = df1.resample('3D').mean()
df1_resampled['T10Y2Y'] = df1_resampled['T10Y2Y'].interpolate(method='linear')
df1_resampled = df1_resampled.reset_index()

# Download the second CSV file (e.g., Jobless Claims Data)
url2 = 'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1320&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=ICSA&scale=left&cosd=2000-01-01&coed=2024-11-23&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=3&ost=-99999&oet=99999&mma=0&fml=a&fq=Weekly%2C%20Ending%20Saturday&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2024-11-29&revision_date=2024-11-29&nd=1967-01-07'
response2 = requests.get(url2)
with open('jobless_claims.csv', 'wb') as file2:
    file2.write(response2.content)

# Load and preprocess the second dataset
df2 = pd.read_csv('jobless_claims.csv')
df2['DATE'] = pd.to_datetime(df2['DATE'])
df2['ICSA'] = pd.to_numeric(df2['ICSA'], errors='coerce') / 1000
df2 = df2.dropna(subset=['ICSA']).sort_values(by='DATE')

df2.set_index('DATE', inplace=True)
df2_resampled = df2.resample('3D').mean()
df2_resampled['ICSA'] = df2_resampled['ICSA'].interpolate(method='linear')
df2_resampled = df2_resampled.reset_index()

# Plot both datasets
fig, ax1 = plt.subplots(figsize=(12, 6))

# First dataset (Yield Curve)
ax1.plot(df1_resampled['DATE'], df1_resampled['T10Y2Y'], label='10Y-2Y Spread', color='blue')
ax1.axhline(y=0.0, color='black', linewidth=1.5, linestyle='--', label='0.0 Reference')
ax1.set_xlabel('Date')
ax1.set_ylabel('Yield Curve Spread (%)', color='blue')
ax1.tick_params(axis='y', labelcolor='blue')
ax1.xaxis.set_major_locator(MonthLocator(bymonth=(1), interval=1))
# Use custom DateFormatter to show only the last two digits of the year
ax1.xaxis.set_major_formatter(DateFormatter("'%y"))  # '%y' formats the year as two digits
ax1.set_xlim(df1_resampled['DATE'].iloc[0], df1_resampled['DATE'].iloc[-1])
ax1.grid(True)

# Second dataset (Jobless Claims) on secondary Y-axis
ax2 = ax1.twinx()
ax2.plot(df2_resampled['DATE'], df2_resampled['ICSA'], label='Jobless Claims', color='red')
ax2.set_ylabel('Jobless Claims (in thousands)', color='red')
ax2.tick_params(axis='y', labelcolor='red')
ax2.set_ylim(0, 1200)

# Title and legend
fig.suptitle('US Yield Curve and Jobless Claims')
fig.tight_layout()
plt.show()

