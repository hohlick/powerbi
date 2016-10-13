(SourceColumn as list, optional ByYear as logical, optional Culture as nullable text) as table =>
/*
SourceColumn:	list. Any dates column or list of dates can be supplied
ByYear:		 	logical. If true, calendar will start from 1st day of the same year as earliest date in list,
				and ends 31 Dec of the same year as last date in list. 
				If false, the start of the first month and the end of the last month will be used.
				false by def
Culture: 		optional text. Locale name ("en-US", "en-GB","ru-RU" etc.)
*/
let
    Source = List.Buffer(SourceColumn),
    DSOY = Date.StartOfYear(List.Min(Source)),
    DEOY = Date.EndOfYear(List.Max(Source)),
    DSOM = Date.StartOfMonth(List.Min(Source)),
    DEOM = Date.EndOfMonth(List.Max(Source)),
    ByYear = 
	    if Type.Is(Value.Type(ByYear), type logical) // = null 
	    then ByYear
	    else false,
    DatesList = 
	    if ByYear 
	    then 
	    List.Dates(DSOY,Number.From(DEOY-DSOY)+1,#duration(1,0,0,0)) 
	    else 
            List.Dates(DSOM,Number.From(DEOM-DSOM)+1,#duration(1,0,0,0)),
    DatesTable = Table.FromList(DatesList, Splitter.SplitByNothing(), {"Date"}),
    #"Changed Type with Locale" = Table.TransformColumnTypes(DatesTable, {{"Date", type date}}, Culture),
    #"Inserted Year" = Table.AddColumn(#"Changed Type with Locale", "Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Quarter" = Table.AddColumn(#"Inserted Year", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    #"Inserted Start of Quarter" = Table.AddColumn(#"Inserted Quarter", "StartOfQuarter", each Date.StartOfQuarter([Date]), type date),
    #"Inserted Month" = Table.AddColumn(#"Inserted Start of Quarter", "Month", each Date.Month([Date]), Int64.Type),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Date.MonthName([Date], Culture), type text),
    #"Inserted Short Month Name" = Table.AddColumn(#"Inserted Month Name", "Short Month", each Date.ToText([Date],"MMM", Culture), type text),
    #"Inserted Start of Month" = Table.AddColumn(#"Inserted Short Month Name", "StartOfMonth", each Date.StartOfMonth([Date]), type date),
    #"Inserted Week of Year" = Table.AddColumn(#"Inserted Start of Month", "WeekOfYear", each Date.WeekOfYear([Date]), Int64.Type),
    #"Inserted Day" = Table.AddColumn(#"Inserted Week of Year", "Day", each Date.Day([Date]), Int64.Type),
    // Week starts from Monday, Monday = 1
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted Day", "DayOfWeek", each Date.DayOfWeek([Date])+1, Int64.Type),
    #"Inserted Day of Year" = Table.AddColumn(#"Inserted Day of Week", "DayOfYear", each Date.DayOfYear([Date]), Int64.Type),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Year", "Day Name", each Date.DayOfWeekName([Date], Culture), type text),
    #"Inserted Short Day Name" = Table.AddColumn(#"Inserted Day Name", "Short Day Name", each Date.ToText([Date],"ddd", Culture), type text),
    #"Insert DateKeyLong" = Table.AddColumn(#"Inserted Short Day Name", "DateKeyLong", each [Year]*10000+[Month]*100+[Day], Int64.Type),
    #"Insterted DateKeyShort" = Table.AddColumn(#"Insert DateKeyLong", "DateKeyShort", each [Year]*1000+[DayOfYear], Int64.Type),
    InsertedIsWeekDay = Table.AddColumn(#"Insterted DateKeyShort", "IsWeekDay", each if [DayOfWeek]<6 then true else false, type logical)
in
    InsertedIsWeekDay