import requests
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.dates import MonthLocator, DateFormatter
from io import BytesIO

def download_csv_data(url: str) -> pd.DataFrame:
    """Download CSV data from a given URL and return as a DataFrame."""
    response = requests.get(url)
    response.raise_for_status()  # Raises HTTPError if the request failed
    # Read directly from memory, avoiding the creation of a file
    df = pd.read_csv(BytesIO(response.content))
    return df

def standardise_date_column(df: pd.DataFrame) -> pd.DataFrame:
    """Ensure the DataFrame has a standardised date column named 'standard_date'."""
    # Normalise column names
    df.columns = df.columns.str.strip().str.lower()
    
    # Handle multiple possible date column names
    if 'date' in df.columns:
        df.rename(columns={'date': 'standard_date'}, inplace=True)
    elif 'observation_date' in df.columns:
        df.rename(columns={'observation_date': 'standard_date'}, inplace=True)
    else:
        raise KeyError("Neither 'date' nor 'observation_date' column found in the dataset.")
    
    df['standard_date'] = pd.to_datetime(df['standard_date'])
    return df

def preprocess_yield_curve_data(df: pd.DataFrame) -> pd.DataFrame:
    """Preprocess yield curve data and resample."""
    df['t10y2y'] = pd.to_numeric(df['t10y2y'], errors='coerce')
    df = df.dropna(subset=['t10y2y']).sort_values(by='standard_date')
    df.set_index('standard_date', inplace=True)
    df_resampled = df.resample('3D').mean()
    df_resampled['t10y2y'] = df_resampled['t10y2y'].interpolate(method='linear')
    df_resampled = df_resampled.reset_index()
    return df_resampled

def preprocess_jobless_claims_data(df: pd.DataFrame) -> pd.DataFrame:
    """Preprocess jobless claims data and resample."""
    df['icsa'] = pd.to_numeric(df['icsa'], errors='coerce') / 1000
    df = df.dropna(subset=['icsa']).sort_values(by='standard_date')
    df.set_index('standard_date', inplace=True)
    df_resampled = df.resample('3D').mean()
    df_resampled['icsa'] = df_resampled['icsa'].interpolate(method='linear')
    df_resampled = df_resampled.reset_index()
    return df_resampled

def plot_data(df_yield: pd.DataFrame, df_claims: pd.DataFrame) -> None:
    """Plot the yield curve and jobless claims data on a dual-axis chart."""
    fig, ax1 = plt.subplots(figsize=(12, 6))

    # Plot Yield Curve
    ax1.plot(df_yield['standard_date'], df_yield['t10y2y'], label='10Y-2Y Spread', color='blue')
    ax1.axhline(y=0.0, color='black', linewidth=1.5, linestyle='--', label='0.0 Reference')
    ax1.set_xlabel('Date')
    ax1.set_ylabel('Yield Curve Spread (%)', color='blue')
    ax1.tick_params(axis='y', labelcolor='blue')
    ax1.xaxis.set_major_locator(MonthLocator(bymonth=(1), interval=1))
    ax1.xaxis.set_major_formatter(DateFormatter("'%y"))
    ax1.set_xlim(df_yield['standard_date'].iloc[0], df_yield['standard_date'].iloc[-1])
    ax1.grid(True)

    # Plot Jobless Claims on secondary axis
    ax2 = ax1.twinx()
    ax2.plot(df_claims['standard_date'], df_claims['icsa'], label='Jobless Claims', color='red')
    ax2.set_ylabel('Jobless Claims (in thousands)', color='red')
    ax2.tick_params(axis='y', labelcolor='red')
    ax2.set_ylim(0, 1200)

    fig.suptitle('US Yield Curve and Jobless Claims')
    fig.tight_layout()
    plt.show()

def main():
    # URLs
    yield_curve_url = (
        'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1320&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=T10Y2Y&scale=left&cosd=2000-01-01&coed=2024-11-27&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=3&ost=-99999&oet=99999&mma=0&fml=a&fq=Daily&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2024-11-29&revision_date=2024-11-29&nd=1976-06-01'
    )
    jobless_claims_url = (
        'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1320&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=ICSA&scale=left&cosd=2000-01-01&coed=2024-11-23&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=3&ost=-99999&oet=99999&mma=0&fml=a&fq=Weekly%2C%20Ending%20Saturday&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2024-11-29&revision_date=2024-11-29&nd=1967-01-07'
    )
    
    try:
        # Download and preprocess yield curve data
        df_yield = download_csv_data(yield_curve_url)
        df_yield = standardise_date_column(df_yield)
        df_yield_resampled = preprocess_yield_curve_data(df_yield)

        # Download and preprocess jobless claims data
        df_claims = download_csv_data(jobless_claims_url)
        df_claims = standardise_date_column(df_claims)
        df_claims_resampled = preprocess_jobless_claims_data(df_claims)
        
        # Plot the data
        plot_data(df_yield_resampled, df_claims_resampled)

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
