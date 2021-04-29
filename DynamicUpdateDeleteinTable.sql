USE [SK2DB_test]
GO

/****** Object:  StoredProcedure [dbo].[sp_process]    Script Date: 4/28/2021 5:52:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[sp_process] @table_name nvarchar(50),@operation nvarchar(50),@column_names_for_value nvarchar(100)
,@newvalues nvarchar(100),@column_names_for_condition nvarchar(100)=NULL,@operators_for_condition nvarchar(100)=NULL,@values_for_condition nvarchar(100)=NULL,@type varchar(1)='P'

as

begin 


---------multiply columns condition

BEGIN TRY
declare @condition nvarchar(1000)
DECLARE @Pos     BIGINT,
        @OldPos  BIGINT,
        @Pos1    BIGINT=1,
        @OldPos1 BIGINT=1,
		@Pos2   BIGINT=1,
        @OldPos2 BIGINT=1,
		@str nvarchar(1000) =''

    SELECT  @Pos    = 1,
            @OldPos = 1

    WHILE   @Pos < LEN(@column_names_for_condition) and @pos<>0
        BEGIN

            SELECT  @Pos = CHARINDEX(',', @column_names_for_condition, @OldPos)
			SELECT  @Pos1 = CHARINDEX(',', @operators_for_condition, @OldPos1)
			SELECT  @Pos2 = CHARINDEX(',', @values_for_condition, @OldPos2)
            --INSERT INTO @Table


			select @condition= a+b+case when f.datatype='nvarchar' then 'N'''+f.c+'''' 
			when  f.datatype in (
'date',
'datetime',
'datetime2',
'varchar' ) then ''''+f.c+'''' else c end

			
			from (

			select * ,(select  DATA_TYPE from INFORMATION_SCHEMA.columns where COLUMN_NAME=t.a and TABLE_NAME=@table_name)  as datatype
			
			
			 from (
            SELECT  SUBSTRING(@column_names_for_condition, @OldPos,iif(@pos=0,len(@column_names_for_condition), @Pos - @OldPos)) as a
			,  SUBSTRING(@operators_for_condition, @OldPos1,iif(@pos1=0,len(@operators_for_condition), @Pos1 - @OldPos1)) as b
			,  SUBSTRING(@values_for_condition, @OldPos2,iif(@pos2=0,len(@values_for_condition), @Pos2 - @OldPos2)) as c) as t ) as f

            SELECT  @OldPos = @Pos + 1
			SELECT  @OldPos1 = @Pos1 + 1
			SELECT  @OldPos2 = @Pos2 + 1

			set @str=@str+@condition+' and '


        END


		set @condition = substring(@str,1,len(@str)-4)

		

END TRY 

BEGIN CATCH

print 'must be add condition'

END CATCH

declare @string nvarchar(max)




if @operation='update'
begin
BEGIN TRY
declare @conditionnew nvarchar(1000)
set  @str=''
set  @Pos     =1
set  @OldPos  =1
set  @Pos1    =1
set  @OldPos1 =1


  WHILE   @Pos < LEN(@column_names_for_value) and @pos<>0
        BEGIN

            SELECT  @Pos = CHARINDEX(',', @column_names_for_value, @OldPos)
			SELECT  @Pos1 = CHARINDEX(',', @newvalues, @OldPos1)
			select @conditionnew=  a+' = '+case when f.datatype='nvarchar' and not f.b like '%[-,+,/,*,),(]%' then 'N'''+f.b+'''' 
			when  f.datatype in (
'date',
'datetime',
'datetime2',
'varchar' ) and not f.b like '%[-,+,/,*,),(]%' then ''''+f.b+'''' else b end

			
			from (

			select * ,(select  DATA_TYPE from INFORMATION_SCHEMA.columns where COLUMN_NAME=t.a and TABLE_NAME=@table_name)  as datatype
			
			
			 from (
  SELECT  SUBSTRING(@column_names_for_value, @OldPos,iif(@pos=0,len(@column_names_for_value), @Pos - @OldPos)) as a
			
			,  SUBSTRING(@newvalues, @OldPos1,iif(@pos1=0,len(@newvalues), @Pos1 - @OldPos1)) as b)  as t ) as f

            SELECT  @OldPos = @Pos + 1
			SELECT  @OldPos1 = @Pos1 + 1

			
set @str=@str+@conditionnew+', '

        END

		set @conditionnew = substring(@str,1,len(@str)-1)



set @string='update '+@table_name +' set '+ @conditionnew+' where ' +@condition
if @string is null 
begin
print 'update doesn''t work' 
end
IF @type='p'
begin
print @string
end
IF @type='e'
begin
execute sp_executesql @statement = @string
end
END TRY 

BEGIN CATCH 
print 'update doesn''t work'
END CATCH
end

if @operation='delete'
begin
BEGIN TRY

set @string='delete ' +@table_name +' where '+@condition
if @string is null 
begin
print 'delete doesn''t work' 
end

IF @type='p'
begin
print @string
end
IF @type='e'
begin
execute sp_executesql @statement = @string
end
END TRY 

BEGIN CATCH
print 'delete doesn''t work'
END CATCH

END


END
GO


