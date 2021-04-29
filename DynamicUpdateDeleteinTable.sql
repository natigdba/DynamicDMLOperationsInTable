USE [SK2DB_test];
GO

/****** Object:  StoredProcedure [dbo].[sp_process]    Script Date: 4/28/2021 5:52:26 PM ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROC [dbo].[sp_process] @table_name                 NVARCHAR(50),     -- which table we need for operation
                               @operation                  NVARCHAR(50),     -- which type of operation (example : delete, update)
                               @column_names_for_value     NVARCHAR(100),    -- column names for update process
                               @newvalues                  NVARCHAR(100),    -- new values for update process
                               @column_names_for_condition NVARCHAR(100) = NULL,  
                               @operators_for_condition    NVARCHAR(100) = NULL,  
                               @values_for_condition       NVARCHAR(100) = NULL, 
                               @type                       VARCHAR(1)    = 'P' --P is print and E is execute
AS
    BEGIN

        ---------multiply columns condition

        BEGIN TRY
            DECLARE @condition NVARCHAR(1000);
            DECLARE @Pos BIGINT, @OldPos BIGINT, @Pos1 BIGINT= 1, @OldPos1 BIGINT= 1, @Pos2 BIGINT= 1, @OldPos2 BIGINT= 1, @str NVARCHAR(1000)= '';
            SELECT @Pos = 1, 
                   @OldPos = 1;
            WHILE @Pos < LEN(@column_names_for_condition)
                  AND @pos <> 0
                BEGIN
                    SELECT @Pos = CHARINDEX(',', @column_names_for_condition, @OldPos);
                    SELECT @Pos1 = CHARINDEX(',', @operators_for_condition, @OldPos1);
                    SELECT @Pos2 = CHARINDEX(',', @values_for_condition, @OldPos2);
                    SELECT @condition = a + b + CASE
                                                    WHEN f.datatype = 'nvarchar'
                                                    THEN 'N''' + f.c + ''''
                                                    WHEN f.datatype IN('date', 'datetime', 'datetime2', 'varchar')
                                                    THEN '''' + f.c + ''''
                                                    ELSE c
                                                END
                    FROM
                    (
                        SELECT *, 
                        (
                            SELECT DATA_TYPE
                            FROM INFORMATION_SCHEMA.columns
                            WHERE COLUMN_NAME = t.a
                                  AND TABLE_NAME = @table_name
                        ) AS datatype
                        FROM
                        (
                            SELECT SUBSTRING(@column_names_for_condition, @OldPos, IIF(@pos = 0, LEN(@column_names_for_condition), @Pos - @OldPos)) AS a, 
                                   SUBSTRING(@operators_for_condition, @OldPos1, IIF(@pos1 = 0, LEN(@operators_for_condition), @Pos1 - @OldPos1)) AS b, 
                                   SUBSTRING(@values_for_condition, @OldPos2, IIF(@pos2 = 0, LEN(@values_for_condition), @Pos2 - @OldPos2)) AS c
                        ) AS t
                    ) AS f;
                    SELECT @OldPos = @Pos + 1;
                    SELECT @OldPos1 = @Pos1 + 1;
                    SELECT @OldPos2 = @Pos2 + 1;
                    SET @str = @str + @condition + ' and ';
                END;
            SET @condition = SUBSTRING(@str, 1, LEN(@str) - 4);
        END TRY
        BEGIN CATCH
            PRINT 'must be add condition';
        END CATCH;

		-------for update 
        DECLARE @string NVARCHAR(MAX);
        IF @operation = 'update'
            BEGIN
                BEGIN TRY
                    DECLARE @conditionnew NVARCHAR(1000);
                    SET @str = '';
                    SET @Pos = 1;
                    SET @OldPos = 1;
                    SET @Pos1 = 1;
                    SET @OldPos1 = 1;
                    WHILE @Pos < LEN(@column_names_for_value)
                          AND @pos <> 0
                        BEGIN
                            SELECT @Pos = CHARINDEX(',', @column_names_for_value, @OldPos);
                            SELECT @Pos1 = CHARINDEX(',', @newvalues, @OldPos1);
                            SELECT @conditionnew = a + ' = ' + CASE
                                                                   WHEN f.datatype = 'nvarchar'
                                                                        AND NOT f.b LIKE '%[-,+,/,*,),(]%'
                                                                   THEN 'N''' + f.b + ''''
                                                                   WHEN f.datatype IN('date', 'datetime', 'datetime2', 'varchar')
                                                                        AND NOT f.b LIKE '%[-,+,/,*,),(]%'
                                                                   THEN '''' + f.b + ''''
                                                                   ELSE b
                                                               END
                            FROM
                            (
                                SELECT *, 
                                (
                                    SELECT DATA_TYPE
                                    FROM INFORMATION_SCHEMA.columns
                                    WHERE COLUMN_NAME = t.a
                                          AND TABLE_NAME = @table_name
                                ) AS datatype
                                FROM
                                (
                                    SELECT SUBSTRING(@column_names_for_value, @OldPos, IIF(@pos = 0, LEN(@column_names_for_value), @Pos - @OldPos)) AS a, 
                                           SUBSTRING(@newvalues, @OldPos1, IIF(@pos1 = 0, LEN(@newvalues), @Pos1 - @OldPos1)) AS b
                                ) AS t
                            ) AS f;
                            SELECT @OldPos = @Pos + 1;
                            SELECT @OldPos1 = @Pos1 + 1;
                            SET @str = @str + @conditionnew + ', ';
                        END;
                    SET @conditionnew = SUBSTRING(@str, 1, LEN(@str) - 1);
                    SET @string = 'update ' + @table_name + ' set ' + @conditionnew + ' where ' + @condition;
                    IF @string IS NULL
                        BEGIN
                            PRINT 'update doesn''t work';
                        END;
                    IF @type = 'p'
                        BEGIN
                            PRINT @string;
                        END;
                    IF @type = 'e'
                        BEGIN
                            EXECUTE sp_executesql 
                                    @statement = @string;
                        END;
                END TRY
                BEGIN CATCH
                    PRINT 'update doesn''t work';
                END CATCH;
            END;


	    -----For delete 
        IF @operation = 'delete'
            BEGIN
                BEGIN TRY
                    SET @string = 'delete ' + @table_name + ' where ' + @condition;
                    IF @string IS NULL
                        BEGIN
                            PRINT 'delete doesn''t work';
                        END;
                    IF @type = 'p'
                        BEGIN
                            PRINT @string;
                        END;
                    IF @type = 'e'
                        BEGIN
                            EXECUTE sp_executesql 
                                    @statement = @string;
                        END;
                END TRY
                BEGIN CATCH
                    PRINT 'delete doesn''t work';
                END CATCH;
            END;
    END;
GO