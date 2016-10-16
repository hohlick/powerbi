(SourceColumn as list, optional CalType as nullable number, optional Culture as nullable text) as table =>
/*
v1.01 15 Oct 2016

SourceColumn:	list. Any dates column or list of dates can be supplied.
				All non-date (according to current or suppplied Culture) values will be removed from list.
				
CalType:		optional number. 
			From month to month: If 1 then calendar will be sart from first day in the month of the earliest date 
			and end  at the last day in the month of the last date
			
			From year to year: If 2 then calendar will start from 01 Jan of the same year as earliest date in list, 
			and end at 31 Dec of the year of last date. 
			
			From date to date: If 0, omitted or any other number then calendar will be build from earliest date 
			to last date only.
				
Culture: 		optional text. Locale name ("en-US", "en-GB","ru-RU" etc.)
*/
let
	// Clear all non-date values from list:
	Source = List.Buffer(List.RemoveNulls(List.Transform(SourceColumn, each try Date.From(_, Culture) otherwise null))),
	FD = List.Min(Source), // first date
	LD = List.Max(Source), // last date
	
	// Select start and end dates of calendar:
	StartDate = if CalType = 1 then Date.StartOfMonth(FD) else if CalType = 2 then Date.StartOfYear(FD) else FD,
	EndDate = if CalType = 1 then Date.EndOfMonth(LD) else if CalType = 2 then Date.EndOfYear(LD) else LD,
    //Build calendar 
	DatesList = List.Dates(StartDate,Duration.Days(EndDate-StartDate)+1,#duration(1,0,0,0)),
	DatesTable = Table.FromList(DatesList, Splitter.SplitByNothing(), {"Date"}),
    #"Changed Type with Locale" = Table.TransformColumnTypes(DatesTable, {{"Date", type date}}, Culture),
	// then insert additional columns
    #"Inserted Year" = Table.AddColumn(#"Changed Type with Locale", "Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Quarter" = Table.AddColumn(#"Inserted Year", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    #"Inserted Start of Quarter" = Table.AddColumn(#"Inserted Quarter", "StartOfQuarter", each Date.StartOfQuarter([Date]), type date),
    #"Inserted Month" = Table.AddColumn(#"Inserted Start of Quarter", "Month", each Date.Month([Date]), Int64.Type),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Date.MonthName([Date], Culture), type text),
    #"Inserted Short Month Name" = Table.AddColumn(#"Inserted Month Name", "Short Month", each Date.ToText([Date],"MMM", Culture), type text),
    #"Inserted Start of Month" = Table.AddColumn(#"Inserted Short Month Name", "StartOfMonth", each Date.StartOfMonth([Date]), type date),
    // Week of year: standard PQ, non-ISO week
	#"Inserted Week of Year" = Table.AddColumn(#"Inserted Start of Month", "WeekOfYear", each Date.WeekOfYear([Date]), Int64.Type),
    #"Inserted Day" = Table.AddColumn(#"Inserted Week of Year", "Day", each Date.Day([Date]), Int64.Type),
    // Week starts from Monday, Monday = 1
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted Day", "DayOfWeek", each Date.DayOfWeek([Date])+1, Int64.Type),
    #"Inserted Day of Year" = Table.AddColumn(#"Inserted Day of Week", "DayOfYear", each Date.DayOfYear([Date]), Int64.Type),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Year", "Day Name", each Date.DayOfWeekName([Date], Culture), type text),
    #"Inserted Short Day Name" = Table.AddColumn(#"Inserted Day Name", "Short Day Name", each Date.ToText([Date],"ddd", Culture), type text),
    // LONG Integer Date key: YYYYMMDD and YYYYDDD
	#"Insert DateKeyLong" = Table.AddColumn(#"Inserted Short Day Name", "DateKeyLong", each [Year]*10000+[Month]*100+[Day], Int64.Type),
	// SHORT Integer Date key: YYYYDDD
    #"Insterted DateKeyShort" = Table.AddColumn(#"Insert DateKeyLong", "DateKeyShort", each [Year]*1000+[DayOfYear], Int64.Type),
	// Saturdays and Sundays:
    InsertedIsWeekDay = Table.AddColumn(#"Insterted DateKeyShort", "IsWeekDay", each if [DayOfWeek]<6 then true else false, type logical)
in
    InsertedIsWeekDay
