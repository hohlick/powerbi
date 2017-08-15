(ListsOfDates as list, optional CalType as nullable number, optional Culture as nullable text) as list=>
/*
ListsOfDates:	single list/column, or list of lists/columns.
			Any dates column or list of dates can be supplied: 
			Table[ColumnName] or {Table[ColumnName1] [, Table[ColumnName2], ...]}
			All non-date (according to current or suppplied Culture) values will be removed.
				
CalType:	optional number. 
			From date to date: If 0, omitted or any other number then calendar will be build from earliest date to last date only.
			From month to month: If 1 then calendar will be sart from first day in the month of the earliest date and end  at the last day in the month of the last date
			From year to year: If 2 then calendar will start from 01 Jan of the same year as earliest date in list, and end at 31 Dec of the year of last date. 
				
Culture: 	optional text. Locale name ("en-US", "en-GB","ru-RU" etc.)
*/

let
	// Clear all non-date values from list:
	Src = List.Union(List.Transform(ListsOfDates,each if Type.Is(Value.Type(_),List.Type) then _ else {_})),
	Source = List.Buffer(List.RemoveNulls(List.Transform(Src, each try Date.From(_, Culture) otherwise null))),
	FD = List.Min(Source), // first date
	LD = List.Max(Source), // last date
	
	// Select start and end dates of calendar:
	StartDate = if CalType = 1 then Date.StartOfMonth(FD) else if CalType = 2 then Date.StartOfYear(FD) else FD,
	EndDate = if CalType = 1 then Date.EndOfMonth(LD) else if CalType = 2 then Date.EndOfYear(LD) else LD,
    //Build calendar:
    DatesList = List.Dates(StartDate,Duration.Days(EndDate-StartDate)+1,#duration(1,0,0,0))
in 
    DatesList
