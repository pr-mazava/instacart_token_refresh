/*
================================================================================
MAZAVA CONSULTING - POWER BI CONNECTOR FOR INSTACART ADS API
================================================================================

This Power Query M script enables direct integration between Instacart Ads API 
and Power BI using refresh tokens generated by the instacart_refresh_token.py utility.

Author: Paul Rakotoarisoa <paul@mazavaltd.com>
Company: Mazava Consulting
Version: 1.0.0

Usage:
1. Open Power BI Desktop
2. Get Data > Blank Query
3. Advanced Editor > Paste this script
4. Update the parameters section with your credentials
5. Apply & Close

Data Sources Created:
- InstacartCampaigns: Campaign performance data
- InstacartProducts: Product performance data
- InstacartKeywords: Keyword performance data

#AnalyzeResponsibly
================================================================================
*/

let
    //========================================================================
    // CONFIGURATION PARAMETERS
    //========================================================================
    
    // Update these parameters with your Instacart API credentials
    RefreshToken = "YOUR_REFRESH_TOKEN_HERE",           // From instacart_refresh_token.py
    ClientId = "YOUR_CLIENT_ID_HERE",                   // Your Instacart API Client ID
    ClientSecret = "YOUR_CLIENT_SECRET_HERE",           // Your Instacart API Client Secret
    
    // API Configuration
    InstacartAuthUrl = "https://api.ads.instacart.com/oauth/token",
    InstacartApiBase = "https://api.ads.instacart.com/api/v2",
    
    // Date Range Configuration (last 30 days)
    EndDate = Date.AddDays(DateTime.Date(DateTime.LocalNow()), -1),
    StartDate = Date.AddDays(EndDate, -30),
    StartDateText = Date.ToText(StartDate, "yyyy-MM-dd"),
    EndDateText = Date.ToText(EndDate, "yyyy-MM-dd"),
    
    //========================================================================
    // AUTHENTICATION FUNCTION
    //========================================================================
    
    GetAccessToken = () =>
        let
            AuthBody = Json.FromValue([
                client_id = ClientId,
                client_secret = ClientSecret,
                refresh_token = RefreshToken,
                grant_type = "refresh_token"
            ]),
            
            AuthResponse = try Web.Contents(
                InstacartAuthUrl,
                [
                    Headers = [#"Content-Type" = "application/json"],
                    Content = AuthBody,
                    Timeout = #duration(0, 0, 1, 0)
                ]
            ) otherwise error "Authentication request failed",
            
            AuthJson = try Json.Document(AuthResponse) otherwise error "Invalid authentication response",
            AccessToken = try AuthJson[access_token] otherwise error "No access token in response"
        in
            AccessToken,
    
    //========================================================================
    // API REQUEST FUNCTION WITH RETRY LOGIC
    //========================================================================
    
    MakeInstacartRequest = (endpoint as text, requestBody as record) =>
        let
            AccessToken = GetAccessToken(),
            RequestUrl = InstacartApiBase & endpoint,
            RequestContent = Json.FromValue(requestBody),
            
            ApiResponse = try Web.Contents(
                RequestUrl,
                [
                    Headers = [
                        #"Authorization" = "Bearer " & AccessToken,
                        #"Content-Type" = "application/json",
                        #"Accept" = "application/json"
                    ],
                    Content = RequestContent,
                    Timeout = #duration(0, 0, 2, 0)
                ]
            ) otherwise error "API request failed for endpoint: " & endpoint,
            
            ResponseJson = try Json.Document(ApiResponse) otherwise error "Invalid JSON response from: " & endpoint,
            ResponseData = try ResponseJson[data] otherwise error "No data field in response from: " & endpoint
        in
            ResponseData,
    
    //========================================================================
    // DATE RANGE HELPER
    //========================================================================
    
    CreateDateRange = () => [
        start_date = StartDateText,
        end_date = EndDateText
    ],
    
    //========================================================================
    // CAMPAIGN PERFORMANCE DATA
    //========================================================================
    
    GetCampaignData = () =>
        let
            RequestBody = [
                date_range = CreateDateRange(),
                segment = "day",
                sort_by = "date_asc",
                exclude_fields = {},
                filters = [spend = true]
            ],
            
            RawData = MakeInstacartRequest("/reports/campaigns", RequestBody),
            
            // Convert to table if data exists
            DataTable = if List.IsEmpty(RawData) then 
                #table(
                    {"Date", "CampaignId", "CampaignName", "Status", "Budget", "Spend", "Impressions", "Clicks", "CTR", "CPC", "Conversions", "Sales", "ROAS"},
                    {}
                )
            else
                Table.FromRows(
                    RawData,
                    {"Date", "CampaignId", "CampaignName", "Status", "Budget", "Spend", "Impressions", "Clicks", "CTR", "CPC", "Conversions", "Sales", "ROAS"}
                ),
            
            // Data type transformations
            TypedTable = Table.TransformColumnTypes(
                DataTable,
                {
                    {"Date", type date},
                    {"CampaignId", type text},
                    {"CampaignName", type text},
                    {"Status", type text},
                    {"Budget", Currency.Type},
                    {"Spend", Currency.Type},
                    {"Impressions", Int64.Type},
                    {"Clicks", Int64.Type},
                    {"CTR", Percentage.Type},
                    {"CPC", Currency.Type},
                    {"Conversions", Int64.Type},
                    {"Sales", Currency.Type},
                    {"ROAS", type number}
                }
            ),
            
            // Add calculated columns
            EnhancedTable = Table.AddColumn(
                Table.AddColumn(
                    Table.AddColumn(
                        TypedTable,
                        "ConversionRate",
                        each if [Clicks] > 0 then [Conversions] / [Clicks] else 0,
                        Percentage.Type
                    ),
                    "CostPerConversion",
                    each if [Conversions] > 0 then [Spend] / [Conversions] else null,
                    Currency.Type
                ),
                "DatePeriod",
                each Date.ToText([Date], "yyyy-MM"),
                type text
            )
        in
            EnhancedTable,
    
    //========================================================================
    // PRODUCT PERFORMANCE DATA
    //========================================================================
    
    GetProductData = () =>
        let
            RequestBody = [
                date_range = CreateDateRange(),
                segment = "day",
                sort_by = "date_asc",
                exclude_fields = {},
                filters = [spend = true]
            ],
            
            RawData = MakeInstacartRequest("/reports/products", RequestBody),
            
            // Convert to table if data exists
            DataTable = if List.IsEmpty(RawData) then 
                #table(
                    {"Date", "ProductId", "ProductName", "CampaignId", "CampaignName", "Spend", "Impressions", "Clicks", "Conversions", "Sales", "UnitsSold"},
                    {}
                )
            else
                Table.FromRows(
                    RawData,
                    {"Date", "ProductId", "ProductName", "CampaignId", "CampaignName", "Spend", "Impressions", "Clicks", "Conversions", "Sales", "UnitsSold"}
                ),
            
            // Data type transformations
            TypedTable = Table.TransformColumnTypes(
                DataTable,
                {
                    {"Date", type date},
                    {"ProductId", type text},
                    {"ProductName", type text},
                    {"CampaignId", type text},
                    {"CampaignName", type text},
                    {"Spend", Currency.Type},
                    {"Impressions", Int64.Type},
                    {"Clicks", Int64.Type},
                    {"Conversions", Int64.Type},
                    {"Sales", Currency.Type},
                    {"UnitsSold", Int64.Type}
                }
            ),
            
            // Add calculated columns
            EnhancedTable = Table.AddColumn(
                Table.AddColumn(
                    Table.AddColumn(
                        Table.AddColumn(
                            TypedTable,
                            "CTR",
                            each if [Impressions] > 0 then [Clicks] / [Impressions] else 0,
                            Percentage.Type
                        ),
                        "ConversionRate", 
                        each if [Clicks] > 0 then [Conversions] / [Clicks] else 0,
                        Percentage.Type
                    ),
                    "ROAS",
                    each if [Spend] > 0 then [Sales] / [Spend] else 0,
                    type number
                ),
                "AvgOrderValue",
                each if [Conversions] > 0 then [Sales] / [Conversions] else 0,
                Currency.Type
            )
        in
            EnhancedTable,
    
    //========================================================================
    // KEYWORD PERFORMANCE DATA
    //========================================================================
    
    GetKeywordData = () =>
        let
            RequestBody = [
                date_range = CreateDateRange(),
                segment = "day", 
                sort_by = "date_asc",
                exclude_fields = {},
                filters = [spend = true]
            ],
            
            RawData = try MakeInstacartRequest("/reports/keywords", RequestBody) otherwise {},
            
            // Convert to table if data exists
            DataTable = if List.IsEmpty(RawData) then 
                #table(
                    {"Date", "Keyword", "MatchType", "CampaignId", "CampaignName", "Spend", "Impressions", "Clicks", "Conversions", "Sales"},
                    {}
                )
            else
                Table.FromRows(
                    RawData,
                    {"Date", "Keyword", "MatchType", "CampaignId", "CampaignName", "Spend", "Impressions", "Clicks", "Conversions", "Sales"}
                ),
            
            // Data type transformations
            TypedTable = Table.TransformColumnTypes(
                DataTable,
                {
                    {"Date", type date},
                    {"Keyword", type text},
                    {"MatchType", type text},
                    {"CampaignId", type text},
                    {"CampaignName", type text},
                    {"Spend", Currency.Type},
                    {"Impressions", Int64.Type},
                    {"Clicks", Int64.Type},
                    {"Conversions", Int64.Type},
                    {"Sales", Currency.Type}
                }
            ),
            
            // Add calculated columns
            EnhancedTable = Table.AddColumn(
                Table.AddColumn(
                    Table.AddColumn(
                        Table.AddColumn(
                            TypedTable,
                            "CTR",
                            each if [Impressions] > 0 then [Clicks] / [Impressions] else 0,
                            Percentage.Type
                        ),
                        "CPC",
                        each if [Clicks] > 0 then [Spend] / [Clicks] else 0,
                        Currency.Type
                    ),
                    "ConversionRate",
                    each if [Clicks] > 0 then [Conversions] / [Clicks] else 0,
                    Percentage.Type
                ),
                "ROAS",
                each if [Spend] > 0 then [Sales] / [Spend] else 0,
                type number
            )
        in
            EnhancedTable,
    
    //========================================================================
    // SUMMARY METRICS
    //========================================================================
    
    GetSummaryMetrics = () =>
        let
            // Get campaign data for summary
            CampaignData = GetCampaignData(),
            
            // Calculate summary metrics
            TotalSpend = List.Sum(CampaignData[Spend]),
            TotalSales = List.Sum(CampaignData[Sales]),
            TotalImpressions = List.Sum(CampaignData[Impressions]),
            TotalClicks = List.Sum(CampaignData[Clicks]),
            TotalConversions = List.Sum(CampaignData[Conversions]),
            
            OverallCTR = if TotalImpressions > 0 then TotalClicks / TotalImpressions else 0,
            OverallConversionRate = if TotalClicks > 0 then TotalConversions / TotalClicks else 0,
            OverallROAS = if TotalSpend > 0 then TotalSales / TotalSpend else 0,
            OverallCPC = if TotalClicks > 0 then TotalSpend / TotalClicks else 0,
            
            // Create summary table
            SummaryTable = #table(
                {"Metric", "Value", "Period"},
                {
                    {"Total Spend", TotalSpend, StartDateText & " to " & EndDateText},
                    {"Total Sales", TotalSales, StartDateText & " to " & EndDateText},
                    {"Total Impressions", TotalImpressions, StartDateText & " to " & EndDateText},
                    {"Total Clicks", TotalClicks, StartDateText & " to " & EndDateText},
                    {"Total Conversions", TotalConversions, StartDateText & " to " & EndDateText},
                    {"Overall CTR", OverallCTR, StartDateText & " to " & EndDateText},
                    {"Overall Conversion Rate", OverallConversionRate, StartDateText & " to " & EndDateText},
                    {"Overall ROAS", OverallROAS, StartDateText & " to " & EndDateText},
                    {"Overall CPC", OverallCPC, StartDateText & " to " & EndDateText}
                }
            )
        in
            SummaryTable,
    
    //========================================================================
    // MAIN DATA SELECTION
    //========================================================================
    
    // Choose which dataset to return
    // Change this value to switch between data sources:
    // "campaigns" | "products" | "keywords" | "summary"
    
    DataSource = "campaigns",
    
    FinalData = if DataSource = "campaigns" then GetCampaignData()
        else if DataSource = "products" then GetProductData() 
        else if DataSource = "keywords" then GetKeywordData()
        else if DataSource = "summary" then GetSummaryMetrics()
        else error "Invalid DataSource. Use: campaigns, products, keywords, or summary"

in
    FinalData

/*
================================================================================
USAGE INSTRUCTIONS
================================================================================

1. UPDATE PARAMETERS:
   - Replace RefreshToken with your token from instacart_refresh_token.py
   - Replace ClientId with your Instacart API Client ID  
   - Replace ClientSecret with your Instacart API Client Secret

2. SELECT DATA SOURCE:
   - Change the DataSource variable to choose what data to import:
     * "campaigns" - Campaign performance metrics
     * "products" - Product performance metrics  
     * "keywords" - Keyword performance metrics
     * "summary" - Overall summary metrics

3. CUSTOMIZE DATE RANGE:
   - Modify StartDate and EndDate variables as needed
   - Default is last 30 days

4. CREATE MULTIPLE QUERIES:
   - Duplicate this query for each data source
   - Name them: InstacartCampaigns, InstacartProducts, etc.
   - Set different DataSource values for each

5. SCHEDULE REFRESH:
   - Configure automatic refresh in Power BI Service
   - Recommended: Daily refresh at 6 AM

================================================================================
TROUBLESHOOTING
================================================================================

Common Issues:
- "Authentication request failed" = Check refresh token validity
- "API request failed" = Verify Client ID/Secret 
- "No data field in response" = Check date range and filters
- "Invalid JSON response" = Check API endpoint availability

For support: paul@mazavaltd.com | #AnalyzeResponsibly
================================================================================
*/