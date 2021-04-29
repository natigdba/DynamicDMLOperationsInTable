# DynamicDMLOperationsInTable
Example and result for this procedure

--exec procedure but this generate script and print endly script
EXEC	 [dbo].[sp_process]
		@table_name = N'table_name',
		@operation = N'UPDATE',
		@column_names_for_value = N'column_name1,column_name2',
		@newvalues = N'200,300',
		@column_names_for_condition = N'column_name3,column_name4',
		@operators_for_condition = N'=,>',
		@values_for_condition = N'200,400',
		@type = N'P'
    
    Result as 
update table_name set column_name1 = 200, column_name2 = 300 where column_name3=200 and column_name4>400
